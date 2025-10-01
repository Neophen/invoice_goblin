defmodule InvoiceGoblin.Ledger.Transfer do
  use Ash.Resource,
    domain: Elixir.InvoiceGoblin.Ledger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Transfer]

  transfer do
    account_resource InvoiceGoblin.Ledger.Account
    balance_resource InvoiceGoblin.Ledger.Balance
  end

  postgres do
    table "ledger_transfers"
    repo InvoiceGoblin.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  actions do
    defaults [:read]

    create :transfer do
      accept [:amount, :timestamp, :from_account_id, :to_account_id]
    end
  end

  attributes do
    attribute :id, AshDoubleEntry.ULID do
      primary_key? true
      allow_nil? false
      default &AshDoubleEntry.ULID.generate/0
    end

    attribute :amount, :money do
      allow_nil? false
    end

    attribute :organisation_id, :uuid do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :from_account, InvoiceGoblin.Ledger.Account do
      attribute_writable? true
    end

    belongs_to :to_account, InvoiceGoblin.Ledger.Account do
      attribute_writable? true
    end

    has_many :balances, InvoiceGoblin.Ledger.Balance
  end
end
