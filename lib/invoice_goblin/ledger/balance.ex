defmodule InvoiceGoblin.Ledger.Balance do
  use Ash.Resource,
    domain: Elixir.InvoiceGoblin.Ledger,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshDoubleEntry.Balance]

  balance do
    transfer_resource InvoiceGoblin.Ledger.Transfer
    account_resource InvoiceGoblin.Ledger.Account
  end

  postgres do
    table "ledger_balances"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read]

    create :upsert_balance do
      accept [:balance, :account_id, :transfer_id]
      upsert? true
      upsert_identity :unique_references
    end

    update :adjust_balance do
      argument :from_account_id, :uuid_v7, allow_nil?: false
      argument :to_account_id, :uuid_v7, allow_nil?: false
      argument :delta, :money, allow_nil?: false
      argument :transfer_id, AshDoubleEntry.ULID, allow_nil?: false

      change filter expr(
                      account_id in [^arg(:from_account_id), ^arg(:to_account_id)] and
                        transfer_id > ^arg(:transfer_id)
                    )

      change {AshDoubleEntry.Balance.Changes.AdjustBalance, can_add_money?: true}
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :balance, :money do
      constraints storage_type: :money_with_currency
    end

    attribute :organisation_id, :uuid do
      allow_nil? false
    end
  end

  relationships do
    belongs_to :transfer, InvoiceGoblin.Ledger.Transfer do
      attribute_type AshDoubleEntry.ULID
      allow_nil? false
      attribute_writable? true
    end

    belongs_to :account, InvoiceGoblin.Ledger.Account do
      allow_nil? false
      attribute_writable? true
    end
  end

  identities do
    identity :unique_references, [:account_id, :transfer_id]
  end
end
