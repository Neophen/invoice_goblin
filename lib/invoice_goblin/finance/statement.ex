defmodule InvoiceGoblin.Finance.Statement do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "statements"
    repo InvoiceGoblin.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :title,
        :file_url,
        :file_name,
        :file_size,
        :statement_date,
        :account_iban,
        :statement_period_start,
        :statement_period_end,
        :processing_errors
      ]

      change fn changeset, _context ->
        if Ash.Changeset.get_attribute(changeset, :title) do
          changeset
        else
          attrs = changeset.attributes
          title = generate_title(attrs)
          Ash.Changeset.force_change_attribute(changeset, :title, title)
        end
      end
    end

    update :update do
      accept [
        :title,
        :file_url,
        :file_name,
        :file_size,
        :statement_date,
        :account_iban,
        :statement_period_start,
        :statement_period_end,
        :processing_errors
      ]
    end
  end

  validations do
    validate compare(:statement_period_start, less_than: :statement_period_end),
      where: present([:statement_period_start, :statement_period_end])

    validate string_length(:title, max: 255)

    validate match(:account_iban, ~r/^[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{7}([A-Z0-9]?){0,16}$/) do
      where present(:account_iban)
      message "must be a valid IBAN format"
    end
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? true
      public? true
      constraints max_length: 255
    end

    attribute :file_url, :string do
      allow_nil? false
      public? true
    end

    attribute :file_name, :string do
      public? true
    end

    attribute :file_size, :integer do
      public? true
      constraints min: 0
    end

    attribute :statement_date, :date do
      public? true
    end

    attribute :account_iban, :string do
      public? true
    end

    attribute :statement_period_start, :date do
      public? true
    end

    attribute :statement_period_end, :date do
      public? true
    end

    attribute :processing_errors, :string do
      public? true
    end

    attribute :organisation_id, :uuid do
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    has_many :transactions, InvoiceGoblin.Finance.Transaction do
      destination_attribute :statement_id
      public? true
    end
  end

  calculations do
    calculate :transactions_summary, :map do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          # This would be computed by joining with transactions table
          # For now, return a placeholder
          %{
            income_count: 0,
            expense_count: 0,
            total_income: Money.new(:eur, 0),
            total_expenses: Money.new(:eur, 0)
          }
        end)
      end
    end
  end

  def generate_title(params) do
    account_iban = Map.get(params, :account_iban)
    statement_period_start = Map.get(params, :statement_period_start)
    statement_period_end = Map.get(params, :statement_period_end)
    statement_date = Map.get(params, :statement_date)
    file_name = Map.get(params, :file_name)
    inserted_at = DateTime.utc_now()

    cond do
      account_iban && statement_period_start && statement_period_end ->
        "Bank Statement - #{account_iban} - #{statement_period_start} to #{statement_period_end}"

      account_iban && statement_date ->
        "Bank Statement - #{account_iban} - #{statement_date}"

      file_name ->
        date = DateTime.to_date(inserted_at)
        "Bank Statement - #{file_name} - #{date}"

      true ->
        date = DateTime.to_date(inserted_at)
        "Bank Statement - #{date}"
    end
  end

  def download_url(statement) do
    # slugify the title
    slug = String.downcase(statement.title) |> String.replace(" ", "")

    S3Uploader.presign_get_url(statement.file_url,
      as_attachment?: true,
      filename: "#{slug}.xml",
      content_type: "application/xml",
      expires_in: 300
    )
  end
end
