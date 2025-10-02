defmodule InvoiceGoblin.Finance do
  use Ash.Domain, otp_app: :invoice_goblin, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource InvoiceGoblin.Finance.CounterParty
    resource InvoiceGoblin.Finance.Invoice
    resource InvoiceGoblin.Finance.InvoiceLineItem
    resource InvoiceGoblin.Finance.Statement
    resource InvoiceGoblin.Finance.Transaction
    resource InvoiceGoblin.Finance.BankAccount
  end

  @doc """
  Ingests a list of parsed bank statement entries into transactions.

  This is used by the Oban worker but can also be called directly for testing.
  """
  def ingest_entries(entries, opts \\ []) when is_list(entries) do
    results = %{inserted: 0, skipped: 0, errors: 0}

    final_results =
      Enum.reduce(entries, results, fn entry, acc ->
        case ingest_single_entry(entry, opts) do
          {:ok, :created} ->
            %{acc | inserted: acc.inserted + 1}

          {:ok, :skipped} ->
            %{acc | skipped: acc.skipped + 1}

          {:error, _reason} ->
            %{acc | errors: acc.errors + 1}
        end
      end)

    {:ok, final_results}
  end

  defp ingest_single_entry(entry, opts) do
    tenant = Keyword.get(opts, :tenant)

    # Convert the parsed entry to the format expected by the Transaction resource
    transaction_attrs = %{
      booking_date: entry.booking_date,
      direction: entry.direction,
      amount: entry.amount,
      bank_mark: entry.bank_mark,
      doc_number: entry.doc_number,
      code: entry.code,
      counterparty_name: entry.counterparty_name,
      counterparty_reg_code: entry.counterparty_reg_code,
      payment_purpose: entry.payment_purpose,
      counterparty_iban: entry.counterparty_iban,
      payment_code: entry.payment_code,
      source_row_hash: entry.source_row_hash
    }

    case Ash.create(InvoiceGoblin.Finance.Transaction, transaction_attrs,
           action: :ingest,
           tenant: tenant
         ) do
      {:ok, _transaction} ->
        {:ok, :created}

      {:error, %Ash.Error.Invalid{errors: errors}} ->
        # Check if it's a uniqueness violation (duplicate)
        if has_uniqueness_error?(errors) do
          {:ok, :skipped}
        else
          {:error, {:validation_failed, errors}}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp has_uniqueness_error?(errors) when is_list(errors) do
    Enum.any?(errors, fn error ->
      case error do
        # Check for constraint violations related to source_row_hash
        %Ash.Error.Changes.InvalidAttribute{field: :source_row_hash} ->
          true

        %{message: message} when is_binary(message) ->
          String.contains?(message, "source_row_hash")

        # For nested errors
        %{errors: nested_errors} when is_list(nested_errors) ->
          has_uniqueness_error?(nested_errors)

        _ ->
          false
      end
    end)
  end
end
