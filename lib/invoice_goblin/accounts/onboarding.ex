defmodule InvoiceGoblin.Accounts.Onboarding do
  @moduledoc """
  Handles user onboarding flow including placeholder organization creation
  and replacement with real organization data from bank statements.
  """

  alias InvoiceGoblin.Accounts.{Organisation, OrganisationMembership, User}
  alias InvoiceGoblin.Finance.Camt

  @doc """
  Creates a placeholder organization and assigns it to a user.
  This is called automatically when a user signs up.

  Returns {:ok, organisation} or {:error, reason}
  """
  def create_placeholder_organization_for_user(user_id) when is_binary(user_id) do
    case Ash.create(Organisation, %{}, action: :create_placeholder, authorize?: false) do
      {:ok, org} ->
        case create_membership(user_id, org.id, :owner) do
          {:ok, _membership} -> {:ok, org}
          error -> error
        end

      error ->
        error
    end
  end

  @doc """
  Extracts organization information from a bank statement XML content.

  Returns a map with organization details:
  - name: extracted from statement metadata
  - account_iban: the IBAN from the statement
  """
  def extract_organization_from_statement(xml_content) do
    format = Camt.detect(xml_content)

    case format do
      :unknown ->
        {:error, :unsupported_format}

      _ ->
        metadata = Camt.parse_statement_metadata(xml_content, format)

        org_data = %{
          name: build_organization_name(metadata),
          account_iban: metadata[:account_iban]
        }

        {:ok, org_data}
    end
  end

  @doc """
  Replaces a user's placeholder organization with a new real organization
  and transfers all relevant data.

  This performs the following:
  1. Creates new organization with provided data
  2. Creates owner membership for user in new org
  3. Transfers statement and transactions to new org
  4. Deletes placeholder organization and its membership
  5. Returns the new organization
  """
  def replace_placeholder_organization(user_id, placeholder_org_id, org_data, statement_id) do
    # Verify the organization is actually a placeholder
    case Ash.get(Organisation, placeholder_org_id) do
      {:ok, org} ->
        if org.is_placeholder do
          do_replace_organization(user_id, placeholder_org_id, org_data, statement_id)
        else
          {:error, :not_a_placeholder}
        end

      error ->
        error
    end
  end

  defp do_replace_organization(user_id, placeholder_org_id, org_data, statement_id) do
    # Create new organization
    case Ash.create(Organisation, Map.put(org_data, :is_placeholder, false), authorize?: false) do
      {:ok, new_org} ->
        # Create owner membership for user
        case create_membership(user_id, new_org.id, :owner) do
          {:ok, _membership} ->
            # Transfer statement to new organization
            transfer_statement_result = transfer_statement_to_org(statement_id, new_org.id)

            # Delete placeholder organization (will cascade delete membership)
            Ash.destroy(placeholder_org_id, resource: Organisation, authorize?: false)

            case transfer_statement_result do
              :ok -> {:ok, new_org}
              error -> error
            end

          error ->
            # Cleanup new org if membership creation failed
            Ash.destroy(new_org, authorize?: false)
            error
        end

      error ->
        error
    end
  end

  defp transfer_statement_to_org(statement_id, new_org_id) do
    # Update the statement's organization_id
    # Note: This requires loading with tenant context
    case Ash.get(InvoiceGoblin.Finance.Statement, statement_id, tenant: new_org_id) do
      {:ok, _statement} ->
        :ok

      {:error, _} ->
        # Statement may not exist yet, or may be in placeholder org
        # Try to update via raw SQL since we're changing tenant
        query = """
        UPDATE statements
        SET organisation_id = $1
        WHERE id = $2
        """

        case InvoiceGoblin.Repo.query(query, [new_org_id, statement_id]) do
          {:ok, _} ->
            # Also update transactions
            tx_query = """
            UPDATE transactions
            SET organisation_id = $1
            WHERE statement_id = $2
            """

            case InvoiceGoblin.Repo.query(tx_query, [new_org_id, statement_id]) do
              {:ok, _} -> :ok
              error -> error
            end

          error ->
            error
        end
    end
  end

  defp create_membership(user_id, org_id, role) do
    Ash.create(OrganisationMembership, %{
      user_id: user_id,
      organisation_id: org_id,
      role: role
    }, authorize?: false)
  end

  defp build_organization_name(%{account_iban: iban}) when not is_nil(iban) do
    # Extract country code and bank code from IBAN for a friendly name
    # IBAN format: CC2!n4!a...
    country = String.slice(iban, 0..1)
    "Organization - #{country} #{String.slice(iban, -4..-1)}"
  end

  defp build_organization_name(_metadata) do
    "Your Organization"
  end

  @doc """
  Gets the user's current organization.
  If user has multiple organizations, returns the first non-placeholder one,
  or the placeholder if that's all they have.
  """
  def get_user_organization(user_id) do
    case Ash.get(User, user_id, load: [:organisations]) do
      {:ok, user} ->
        organizations = user.organisations || []

        # Prefer non-placeholder organizations
        case Enum.find(organizations, &(not &1.is_placeholder)) do
          nil ->
            # Return placeholder if that's all we have
            case Enum.find(organizations, & &1.is_placeholder) do
              nil -> {:error, :no_organization}
              placeholder -> {:ok, placeholder}
            end

          org ->
            {:ok, org}
        end

      error ->
        error
    end
  end

  @doc """
  Checks if a user has only a placeholder organization.
  """
  def has_only_placeholder_organization?(user_id) do
    case Ash.get(User, user_id, load: [:organisations]) do
      {:ok, user} ->
        organizations = user.organisations || []

        case organizations do
          [] -> false
          orgs -> Enum.all?(orgs, & &1.is_placeholder)
        end

      _ ->
        false
    end
  end
end
