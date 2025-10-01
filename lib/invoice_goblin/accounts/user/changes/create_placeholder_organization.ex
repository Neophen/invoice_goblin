defmodule InvoiceGoblin.Accounts.User.Changes.CreatePlaceholderOrganization do
  @moduledoc """
  After creating a new user, automatically creates a placeholder organization
  and assigns the user as owner.
  """
  use Ash.Resource.Change

  alias InvoiceGoblin.Accounts.Onboarding

  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, user ->
      case Onboarding.create_placeholder_organization_for_user(user.id) do
        {:ok, _org} ->
          Logger.info("Created placeholder organization for user #{user.id}")
          {:ok, user}

        {:error, error} ->
          Logger.error(
            "Failed to create placeholder organization for user #{user.id}: #{inspect(error)}"
          )

          # Don't fail user creation, just log the error
          # The user can still use the system and create an org later
          {:ok, user}
      end
    end)
  end
end
