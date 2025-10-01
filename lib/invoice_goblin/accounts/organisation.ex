defmodule InvoiceGoblin.Accounts.Organisation do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "organisations"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :is_placeholder]
    end

    create :create_placeholder do
      accept []

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.force_change_attribute(:name, "Temporary Organization")
        |> Ash.Changeset.force_change_attribute(:is_placeholder, true)
      end
    end

    update :update do
      accept [:name]
    end

    read :list_placeholders do
      filter expr(is_placeholder == true)
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :is_placeholder, :boolean do
      allow_nil? false
      default false
      public? true
    end

    timestamps()
  end

  relationships do
    many_to_many :users, InvoiceGoblin.Accounts.User do
      through InvoiceGoblin.Accounts.OrganisationMembership
      source_attribute_on_join_resource :organisation_id
      destination_attribute_on_join_resource :user_id
    end

    has_many :memberships, InvoiceGoblin.Accounts.OrganisationMembership do
      destination_attribute :organisation_id
    end
  end
end
