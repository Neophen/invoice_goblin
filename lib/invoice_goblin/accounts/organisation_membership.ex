defmodule InvoiceGoblin.Accounts.OrganisationMembership do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organisation_memberships"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:user_id, :organisation_id, :role]
    end

    update :update do
      accept [:role]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :role, :atom do
      constraints one_of: [:owner, :admin, :member]
      default :member
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :user, InvoiceGoblin.Accounts.User do
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :organisation, InvoiceGoblin.Accounts.Organisation do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_user_organisation, [:user_id, :organisation_id]
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end
end
