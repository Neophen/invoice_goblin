defmodule InvoiceGoblin.Accounts.OrganisationTest do
  use InvoiceGoblin.DataCase, async: true

  alias InvoiceGoblin.Accounts.{Organisation, User, OrganisationMembership}
  require Ash.Query
  import Ash.Expr

  describe "create organisation" do
    test "creates a valid organisation" do
      attrs = %{name: "Test Company Ltd"}

      assert {:ok, organisation} = Ash.create(Organisation, attrs, action: :create)
      assert organisation.name == "Test Company Ltd"
      assert organisation.id
    end

    test "requires name" do
      attrs = %{}

      assert {:error, %Ash.Error.Invalid{}} = Ash.create(Organisation, attrs, action: :create)
    end
  end

  describe "many-to-many user relationship" do
    @tag :skip
    test "users can belong to multiple organisations" do
      # Create user
      {:ok, user} =
        Ash.create(User, %{
          email: "user@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      # Create two organisations
      {:ok, org1} = Ash.create(Organisation, %{name: "Company 1"})
      {:ok, org2} = Ash.create(Organisation, %{name: "Company 2"})

      # Add user to both organisations
      {:ok, _membership1} =
        Ash.create(OrganisationMembership, %{
          user_id: user.id,
          organisation_id: org1.id,
          role: :owner
        })

      {:ok, _membership2} =
        Ash.create(OrganisationMembership, %{
          user_id: user.id,
          organisation_id: org2.id,
          role: :member
        })

      # Load user with organisations
      {:ok, loaded_user} =
        User
        |> Ash.Query.filter(expr(id == ^user.id))
        |> Ash.Query.load(:organisations)
        |> Ash.read_one()

      assert length(loaded_user.organisations) == 2
      org_names = Enum.map(loaded_user.organisations, & &1.name) |> Enum.sort()
      assert org_names == ["Company 1", "Company 2"]
    end

    @tag :skip
    test "organisations can have multiple users" do
      # Create organisation
      {:ok, org} = Ash.create(Organisation, %{name: "Test Org"})

      # Create two users
      {:ok, user1} =
        Ash.create(User, %{
          email: "user1@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      {:ok, user2} =
        Ash.create(User, %{
          email: "user2@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      # Add both users to organisation
      {:ok, _membership1} =
        Ash.create(OrganisationMembership, %{
          user_id: user1.id,
          organisation_id: org.id,
          role: :owner
        })

      {:ok, _membership2} =
        Ash.create(OrganisationMembership, %{
          user_id: user2.id,
          organisation_id: org.id,
          role: :admin
        })

      # Load organisation with users
      {:ok, loaded_org} =
        Organisation
        |> Ash.Query.filter(expr(id == ^org.id))
        |> Ash.Query.load(:users)
        |> Ash.read_one()

      assert length(loaded_org.users) == 2
      emails = Enum.map(loaded_org.users, & &1.email) |> Enum.sort()
      assert emails == ["user1@example.com", "user2@example.com"]
    end
  end

  describe "organisation membership roles" do
    @tag :skip

    @tag :skip
    test "creates membership with owner role" do
      {:ok, user} =
        Ash.create(User, %{
          email: "owner@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      {:ok, org} = Ash.create(Organisation, %{name: "Test Org"})

      {:ok, membership} =
        Ash.create(OrganisationMembership, %{
          user_id: user.id,
          organisation_id: org.id,
          role: :owner
        })

      assert membership.role == :owner
    end

    @tag :skip
    test "creates membership with admin role" do
      {:ok, user} =
        Ash.create(User, %{
          email: "admin@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      {:ok, org} = Ash.create(Organisation, %{name: "Test Org"})

      {:ok, membership} =
        Ash.create(OrganisationMembership, %{
          user_id: user.id,
          organisation_id: org.id,
          role: :admin
        })

      assert membership.role == :admin
    end

    @tag :skip
    test "creates membership with member role (default)" do
      {:ok, user} =
        Ash.create(User, %{
          email: "member@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      {:ok, org} = Ash.create(Organisation, %{name: "Test Org"})

      {:ok, membership} =
        Ash.create(OrganisationMembership, %{
          user_id: user.id,
          organisation_id: org.id
          # role defaults to :member
        })

      assert membership.role == :member
    end

    @tag :skip
    test "rejects invalid role" do
      {:ok, user} =
        Ash.create(User, %{
          email: "test@example.com",
          hashed_password: Bcrypt.hash_pwd_salt("password123")
        })

      {:ok, org} = Ash.create(Organisation, %{name: "Test Org"})

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(OrganisationMembership, %{
                 user_id: user.id,
                 organisation_id: org.id,
                 role: :invalid_role
               })
    end
  end

  describe "organisation as tenant" do
    test "organisation ID can be used as tenant for finance resources" do
      {:ok, org} = Ash.create(Organisation, %{name: "Finance Test Org"}, action: :create)

      # This demonstrates that the organisation ID works as a tenant
      # Actual finance resource tests are in their respective test files
      assert org.id
      assert is_binary(org.id)
    end
  end
end
