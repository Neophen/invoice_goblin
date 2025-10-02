defmodule InvoiceGoblin.Accounts.Waitlist do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "waitlist"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:email]
    end

    update :update do
      accept [:email]
      require_atomic? false
    end
  end

  validations do
    validate present(:email)

    validate match(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/),
      message: "must be a valid email address"
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_email, [:email]
  end
end
