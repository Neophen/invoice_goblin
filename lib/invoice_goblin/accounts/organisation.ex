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
      accept [:name]
    end

    update :update do
      accept [:name]
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

    attribute :company_code, :string do
      allow_nil? true
      public? true
    end

    attribute :vat_id, :string do
      allow_nil? true
      public? true
    end

    # --- Address Fields ---
    attribute :address_line_1, :string do
      allow_nil? true
      public? true
    end

    attribute :address_line_2, :string do
      allow_nil? true
      public? true
    end

    attribute :address_line_3, :string do
      allow_nil? true
      public? true
    end

    attribute :city, :string do
      allow_nil? true
      public? true
    end

    attribute :state_province, :string do
      # State, Province, Region, or County depending on country
      allow_nil? true
      public? true
    end

    attribute :postal_code, :string do
      # Zip/postcode/CEP etc.
      allow_nil? true
      public? true
    end

    attribute :country, :string do
      allow_nil? false
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

    # has_many :bank_accounts, InvoiceGoblin.Finance.BankAccount do
    #   destination_attribute :organisation_id
    # end

    has_many :memberships, InvoiceGoblin.Accounts.OrganisationMembership do
      destination_attribute :organisation_id
    end
  end
end
