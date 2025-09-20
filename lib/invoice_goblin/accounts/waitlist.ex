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
    defaults [:read]

    create :create do
      accept [:email]
    end
  end

  validations do
    validate fn changeset, _context ->
      email = Ash.Changeset.get_attribute(changeset, :email)

      if email && !match?(~r/^[^\s]+@[^\s]+\.[^\s]+$/, email) do
        [email: "must be a valid email address"]
      else
        []
      end
    end
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
