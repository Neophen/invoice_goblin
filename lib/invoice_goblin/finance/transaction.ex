defmodule InvoiceGoblin.Finance.Transaction do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer

  import Ash.Expr

  postgres do
    table "transactions"
    repo InvoiceGoblin.Repo

    identity_wheres_to_sql by_source_row: "source_row_hash IS NOT NULL"
  end

  actions do
    defaults [:read, :destroy]

    create :ingest do
      accept [
        :booking_date,
        :direction,
        :amount,
        :bank_mark,
        :doc_number,
        :code,
        :counterparty_name,
        :counterparty_reg_code,
        :payment_purpose,
        :counterparty_iban,
        :payment_code,
        :source_row_hash,
        :statement_id
      ]
    end

    update :link_invoice do
      accept [:invoice_id]
    end

    update :unlink_invoice do
      require_atomic? false

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:invoice_id, nil)
      end
    end

    read :today do
      filter expr(booking_date == ^Date.utc_today())
    end

    read :last_week do
      filter expr(booking_date >= ^Date.add(Date.utc_today(), -7))
    end

    read :last_month do
      filter expr(booking_date >= ^Date.add(Date.utc_today(), -30))
    end

    read :by_date_range do
      argument :start_date, :date, allow_nil?: false
      argument :end_date, :date, allow_nil?: false

      filter expr(booking_date >= ^arg(:start_date) and booking_date <= ^arg(:end_date))
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  attributes do
    uuid_primary_key :id

    attribute :booking_date, :date, allow_nil?: false

    attribute :direction, :atom,
      allow_nil?: false,
      constraints: [one_of: [:income, :expense]]

    # Money type from ash_money
    attribute :amount, AshMoney.Types.Money, allow_nil?: false

    # Raw fields visible on the bank PDF (keep minimal but traceable)

    attribute :bank_mark, :string

    attribute :doc_number, :string

    attribute :code, :string

    attribute :counterparty_name, :string
    attribute :counterparty_reg_code, :string

    attribute :payment_purpose, :string

    attribute :counterparty_iban, :string

    attribute :payment_code, :string

    attribute :source_row_hash, :string

    attribute :invoice_id, :uuid, public?: true

    attribute :organisation_id, :uuid do
      allow_nil? false
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :statement, InvoiceGoblin.Finance.Statement
    belongs_to :counter_party, InvoiceGoblin.Finance.CounterParty
    belongs_to :invoice, InvoiceGoblin.Finance.Invoice
  end

  calculations do
    calculate :amount_formatted, :string do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          sign = if record.direction == :income, do: "+", else: "-"
          "#{sign}#{record.amount}"
        end)
      end
    end

    calculate :has_invoice, :boolean do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          not is_nil(record.invoice_id)
        end)
      end
    end
  end

  identities do
    # Optional soft dedupe guard if you compute source_row_hash on ingest
    identity :by_source_row, [:source_row_hash], where: expr(not is_nil(source_row_hash))
  end
end
