defmodule InvoiceGoblin.Finance.InvoiceLineItem do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "invoice_line_items"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:invoice_id, :description, :amount, :currency, :item_index]
    end

    update :update do
      accept [:description, :amount, :currency, :transaction_id]
    end

    update :assign_transaction do
      accept [:transaction_id]
      require_atomic? false

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(
          :transaction_id,
          Ash.Changeset.get_attribute(changeset, :transaction_id)
        )
      end
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  attributes do
    uuid_primary_key :id

    attribute :description, :string
    attribute :amount, :decimal
    attribute :currency, :string, default: "EUR"
    attribute :item_index, :integer

    attribute :organisation_id, :uuid do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :invoice, InvoiceGoblin.Finance.Invoice
    belongs_to :transaction, InvoiceGoblin.Finance.Transaction
  end
end
