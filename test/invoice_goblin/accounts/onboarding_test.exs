defmodule InvoiceGoblin.Accounts.OnboardingTest do
  use InvoiceGoblin.DataCase, async: true

  alias InvoiceGoblin.Accounts.{Onboarding, Organisation, User}

  describe "create_placeholder_organization_for_user/1" do
    test "creates a placeholder organization for a user" do
      user = create_user()

      assert {:ok, org} = Onboarding.create_placeholder_organization_for_user(user.id)
      assert org.name == "Temporary Organization"
      assert org.is_placeholder == true

      # Verify membership was created
      user = Ash.load!(user, [:organisations])
      assert length(user.organisations) == 1
      assert hd(user.organisations).id == org.id
    end

    test "returns error if user doesn't exist" do
      fake_user_id = Ash.UUID.generate()
      assert {:error, _} = Onboarding.create_placeholder_organization_for_user(fake_user_id)
    end
  end

  describe "extract_organization_from_statement/1" do
    test "extracts organization data from valid CAMT.053 XML" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.053.001.02">
        <BkToCstmrStmt>
          <Stmt>
            <Acct>
              <Id>
                <IBAN>LT123456789012345678</IBAN>
              </Id>
            </Acct>
            <CreDtTm>2025-09-13T10:00:00+03:00</CreDtTm>
          </Stmt>
        </BkToCstmrStmt>
      </Document>
      """

      assert {:ok, org_data} = Onboarding.extract_organization_from_statement(xml)
      assert org_data.account_iban == "LT123456789012345678"
      assert org_data.name =~ "Organization"
      assert org_data.name =~ "LT"
    end

    test "returns error for unsupported format" do
      xml = "<invalid>XML</invalid>"
      assert {:error, :unsupported_format} = Onboarding.extract_organization_from_statement(xml)
    end
  end

  describe "replace_placeholder_organization/4" do
    setup do
      user = create_user()
      {:ok, placeholder_org} = Onboarding.create_placeholder_organization_for_user(user.id)

      %{user: user, placeholder_org: placeholder_org}
    end

    test "replaces placeholder organization with real one", %{
      user: user,
      placeholder_org: placeholder_org
    } do
      org_data = %{
        name: "Test Company Ltd",
        account_iban: "LT123456789012345678"
      }

      # Create a test statement in placeholder org
      statement_id = create_test_statement(placeholder_org.id)

      assert {:ok, new_org} =
               Onboarding.replace_placeholder_organization(
                 user.id,
                 placeholder_org.id,
                 org_data,
                 statement_id
               )

      assert new_org.name == "Test Company Ltd"
      assert new_org.is_placeholder == false

      # Verify placeholder org is deleted
      assert {:error, _} = Ash.get(Organisation, placeholder_org.id)

      # Verify user has new org
      user = Ash.load!(user, [:organisations])
      assert length(user.organisations) == 1
      assert hd(user.organisations).id == new_org.id
    end

    test "returns error if trying to replace non-placeholder org", %{user: user} do
      # Create a non-placeholder org
      {:ok, real_org} =
        Ash.create(Organisation, %{name: "Real Org", is_placeholder: false}, authorize?: false)

      org_data = %{name: "Another Org"}
      statement_id = create_test_statement(real_org.id)

      assert {:error, :not_a_placeholder} =
               Onboarding.replace_placeholder_organization(
                 user.id,
                 real_org.id,
                 org_data,
                 statement_id
               )
    end
  end

  describe "get_user_organization/1" do
    test "returns user's non-placeholder organization if they have one" do
      user = create_user()
      {:ok, placeholder_org} = Onboarding.create_placeholder_organization_for_user(user.id)

      {:ok, real_org} = Ash.create(Organisation, %{name: "Real Org", is_placeholder: false}, authorize?: false)

      Ash.create(InvoiceGoblin.Accounts.OrganisationMembership, %{
        user_id: user.id,
        organisation_id: real_org.id,
        role: :owner
      }, authorize?: false)

      assert {:ok, org} = Onboarding.get_user_organization(user.id)
      assert org.id == real_org.id
    end

    test "returns placeholder organization if that's all user has" do
      user = create_user()
      {:ok, placeholder_org} = Onboarding.create_placeholder_organization_for_user(user.id)

      assert {:ok, org} = Onboarding.get_user_organization(user.id)
      assert org.id == placeholder_org.id
    end

    test "returns error if user has no organizations" do
      user = create_user()
      assert {:error, :no_organization} = Onboarding.get_user_organization(user.id)
    end
  end

  describe "has_only_placeholder_organization?/1" do
    test "returns true when user has only placeholder organization" do
      user = create_user()
      {:ok, _placeholder_org} = Onboarding.create_placeholder_organization_for_user(user.id)

      assert Onboarding.has_only_placeholder_organization?(user.id) == true
    end

    test "returns false when user has real organization" do
      user = create_user()
      {:ok, real_org} = Ash.create(Organisation, %{name: "Real Org", is_placeholder: false}, authorize?: false)

      Ash.create(InvoiceGoblin.Accounts.OrganisationMembership, %{
        user_id: user.id,
        organisation_id: real_org.id,
        role: :owner
      }, authorize?: false)

      assert Onboarding.has_only_placeholder_organization?(user.id) == false
    end

    test "returns false when user has no organizations" do
      user = create_user()
      assert Onboarding.has_only_placeholder_organization?(user.id) == false
    end
  end

  # Helper functions

  defp create_user do
    email = "test#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Ash.create(User, %{
        email: email,
        password: "test1234test",
        password_confirmation: "test1234test"
      },
      action: :register_with_password,
      authorize?: false
    )

    user
  end

  defp create_test_statement(org_id) do
    {:ok, statement} =
      Ash.create(
        InvoiceGoblin.Finance.Statement,
        %{
          file_url: "https://example.com/test.xml",
          file_name: "test.xml",
          file_size: 1024,
          title: "Test Statement"
        },
        tenant: org_id
      )

    statement.id
  end
end
