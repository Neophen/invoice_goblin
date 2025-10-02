defmodule InvoiceGoblin.Finance.BankAccount do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "bank_accounts"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read]
  end

  attributes do
    uuid_primary_key :uuidv7

    attribute :holder_name, :string do
      allow_nil? true
      public? true
    end

    attribute :bank_name, :string do
      allow_nil? true
      public? true
    end

    attribute :iban, :string do
      description "International Bank Account Number"
      allow_nil? true
      public? true
      constraints min_length: 5, max_length: 34
    end

    attribute :bic, :string do
      allow_nil? true
      public? true
      constraints max_length: 11
    end

    attribute :currency, :string do
      description "ISO-4217 like \"EUR\", \"USD\""
      allow_nil? true
      public? true
      constraints max_length: 3
    end

    attribute :type, :atom do
      description "Type of bank account, primary or secondary"
      constraints one_of: [:primary, :secondary]
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :organisation, InvoiceGoblin.Accounts.Organisation
  end
end
