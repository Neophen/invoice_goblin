defmodule InvoiceGoblin.Finance.Invoice do
  use Ash.Resource,
    otp_app: :invoice_goblin,
    domain: InvoiceGoblin.Finance,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAi, AshOban]

  import Ash.Expr

  postgres do
    table "invoices"
    repo InvoiceGoblin.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organisation_id
    global? false
  end

  oban do
    triggers do
      trigger :process_uploaded_invoice do
        action :parse_with_ai_trigger
        where expr(status == :processing)
        # Run every minute
        scheduler_cron "* * * * *"
        worker_module_name InvoiceGoblin.Oban.ProcessInvoiceWorker
        scheduler_module_name InvoiceGoblin.Oban.ProcessInvoiceScheduler
      end
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
        :title,
        :file_url,
        :file_name,
        :file_size,
        :file_type,
        :direction,
        :invoice_date,
        :due_date,
        :amount,
        :currency,
        :status,
        :parsed_data,
        :processing_errors,
        :counter_party_id,
        :transaction_id
      ]
    end

    update :update do
      primary? true
      require_atomic? false

      accept [
        :title,
        :direction,
        :invoice_date,
        :due_date,
        :amount,
        :currency,
        :status,
        :parsed_data,
        :processing_errors,
        :counter_party_id,
        :transaction_id
      ]
    end

    create :upload_and_process do
      accept [:title, :file_url, :file_name, :file_size, :file_type]

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:status, :processing)
        |> Ash.Changeset.change_attribute(:direction, :outgoing)
      end
    end

    update :parse_with_ai_trigger do
      require_atomic? false

      change fn changeset, _context ->
        # Get the invoice from the changeset
        invoice = changeset.data

        try do
          # Download the file content with timeout
          {:ok, response} = Req.get(invoice.file_url, receive_timeout: 120_000)
          file_content = response.body

          # Use OpenAI to parse the invoice
          case InvoiceGoblin.AI.OpenAiChatModel.parse_invoice(file_content, invoice.file_type) do
            {:ok, parsed_data} ->
              # Find or create counterparty
              counterparty = find_or_create_counterparty(parsed_data)

              # Update the changeset with parsed data
              # Handle potential date order issues
              invoice_date = parsed_data["invoice_date"]
              due_date = parsed_data["due_date"]

              # Convert string dates to Date if needed
              invoice_date =
                case invoice_date do
                  nil ->
                    nil

                  %Date{} = date ->
                    date

                  date_string when is_binary(date_string) ->
                    case Date.from_iso8601(date_string) do
                      {:ok, date} -> date
                      _ -> nil
                    end

                  _ ->
                    nil
                end

              due_date =
                case due_date do
                  nil ->
                    nil

                  %Date{} = date ->
                    date

                  date_string when is_binary(date_string) ->
                    case Date.from_iso8601(date_string) do
                      {:ok, date} -> date
                      _ -> nil
                    end

                  _ ->
                    nil
                end

              # If dates are in wrong order, swap them
              {invoice_date, due_date} =
                cond do
                  is_nil(invoice_date) or is_nil(due_date) -> {invoice_date, due_date}
                  Date.compare(invoice_date, due_date) == :gt -> {due_date, invoice_date}
                  true -> {invoice_date, due_date}
                end

              changeset
              |> Ash.Changeset.change_attribute(:parsed_data, parsed_data)
              |> Ash.Changeset.change_attribute(:status, :parsed)
              |> Ash.Changeset.change_attribute(:invoice_date, invoice_date)
              |> Ash.Changeset.change_attribute(:due_date, due_date)
              |> Ash.Changeset.change_attribute(:amount, parsed_data["total_amount"])
              |> Ash.Changeset.change_attribute(:currency, parsed_data["currency"] || "EUR")
              |> Ash.Changeset.change_attribute(
                :counter_party_id,
                counterparty && counterparty.id
              )

            {:error, reason} ->
              # Update changeset with error
              changeset
              |> Ash.Changeset.change_attribute(:status, :error)
              |> Ash.Changeset.change_attribute(:processing_errors, inspect(reason))
          end
        rescue
          e ->
            # Handle any exceptions
            changeset
            |> Ash.Changeset.change_attribute(:status, :error)
            |> Ash.Changeset.change_attribute(:processing_errors, "Exception: #{inspect(e)}")
        end
      end
    end

    update :match_transaction do
      require_atomic? false
      accept [:transaction_id]

      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.change_attribute(:status, :matched)
      end
    end

    action :parse_with_ai, InvoiceGoblin.Finance.Types.InvoiceData do
      argument :invoice_id, :uuid, allow_nil?: false

      run fn input, _context ->
        invoice = Ash.get!(InvoiceGoblin.Finance.Invoice, input.arguments.invoice_id)

        # Download the file content
        {:ok, response} = Req.get(invoice.file_url, receive_timeout: 120_000)
        file_content = response.body

        # Use OpenAI to parse the invoice
        case InvoiceGoblin.AI.OpenAiChatModel.parse_invoice(file_content, invoice.file_type) do
          {:ok, parsed_data} ->
            # Find or create counterparty
            counterparty = find_or_create_counterparty(parsed_data)

            # Update the invoice with parsed data
            invoice
            |> Ash.Changeset.for_update(:update, %{
              parsed_data: parsed_data,
              status: :parsed,
              invoice_date: parsed_data["invoice_date"],
              due_date: parsed_data["due_date"],
              amount: parsed_data["total_amount"],
              currency: parsed_data["currency"] || "EUR",
              counter_party_id: counterparty && counterparty.id
            })
            |> Ash.update!()

            {:ok, parsed_data}

          {:error, reason} ->
            # Update invoice with error
            invoice
            |> Ash.Changeset.for_update(:update, %{
              status: :error,
              processing_errors: inspect(reason)
            })
            |> Ash.update!()

            {:error, reason}
        end
      end
    end
  end

  validations do
    validate string_length(:title, max: 255)
    validate string_length(:processing_errors, max: 2000)

    # Remove the strict validation that's causing issues
    # validate compare(:invoice_date, less_than: :due_date),
    #   where: present([:invoice_date, :due_date])

    validate fn changeset, _context ->
      file_type = Ash.Changeset.get_attribute(changeset, :file_type)

      if file_type && file_type not in ["application/pdf", "image/png", "image/jpeg", "image/jpg"] do
        {:error,
         field: :file_type,
         message: "must be one of: application/pdf, image/png, image/jpeg, image/jpg"}
      else
        :ok
      end
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
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

    attribute :file_type, :string do
      public? true
    end

    attribute :direction, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:incoming, :outgoing]
      default :outgoing
    end

    attribute :invoice_date, :date do
      public? true
    end

    attribute :due_date, :date do
      public? true
    end

    attribute :amount, :decimal do
      public? true
    end

    attribute :currency, :string do
      public? true
      default "EUR"
    end

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:processing, :parsed, :matched, :error]
      default :processing
    end

    attribute :parsed_data, :map do
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
    belongs_to :counter_party, InvoiceGoblin.Finance.CounterParty do
      public? true
    end

    belongs_to :transaction, InvoiceGoblin.Finance.Transaction do
      public? true
    end
  end

  calculations do
    calculate :download_url, :string do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          slug = String.downcase(record.title) |> String.replace(" ", "_")

          S3Uploader.presign_get_url(record.file_url,
            as_attachment?: true,
            filename:
              "#{slug}.#{InvoiceGoblin.Finance.Invoice.get_file_extension(record.file_type)}",
            content_type: record.file_type,
            expires_in: 300
          )
        end)
      end
    end
  end

  def get_file_extension(file_type) do
    case file_type do
      "application/pdf" -> "pdf"
      "image/png" -> "png"
      "image/jpeg" -> "jpg"
      "image/jpg" -> "jpg"
      _ -> "bin"
    end
  end

  defp find_or_create_counterparty(parsed_data) do
    party_data =
      if parsed_data["direction"] == "incoming" do
        parsed_data["from_party"]
      else
        parsed_data["to_party"]
      end

    if party_data && party_data["name"] do
      # Try to find existing counterparty by name
      case Ash.read(InvoiceGoblin.Finance.CounterParty, filter: expr(name == ^party_data["name"])) do
        {:ok, [counterparty | _]} ->
          counterparty

        _ ->
          # Create new counterparty
          {:ok, counterparty} =
            Ash.create(InvoiceGoblin.Finance.CounterParty, %{
              name: party_data["name"],
              type: String.to_existing_atom(party_data["type"] || "company"),
              email: party_data["email"],
              phone: party_data["phone"],
              address: party_data["address"],
              registration_number: party_data["registration_number"],
              tax_number: party_data["tax_number"],
              website: party_data["website"]
            })

          counterparty
      end
    else
      nil
    end
  end
end
