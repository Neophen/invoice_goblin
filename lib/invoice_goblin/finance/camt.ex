defmodule InvoiceGoblin.Finance.Camt do
  @moduledoc """
  Parser for CAMT.053 (periodic) and CAMT.054 (intraday) bank statement XML files.

  This module provides functions to detect the CAMT format and parse entries into
  normalized maps that can be ingested into the Transaction resource.
  """

  require Logger
  import SweetXml

  # Private function to parse XML using SweetXML
  defp parse_xml(xml_content) do
    xml_content |> parse()
  end

  @doc """
  Detects the CAMT format from XML content.

  ## Examples

      iex> InvoiceGoblin.Finance.Camt.detect(xml_content)
      :camt053

      iex> InvoiceGoblin.Finance.Camt.detect(invalid_xml)
      :unknown
  """
  @spec detect(binary()) :: :camt053 | :camt054 | :unknown
  def detect(xml_content) when is_binary(xml_content) do
    try do
      cond do
        # CAMT.053 - Account Statement
        String.contains?(xml_content, "camt.053") -> :camt053
        String.contains?(xml_content, "urn:iso:std:iso:20022:tech:xsd:camt.053") -> :camt053
        # CAMT.054 - Debit Credit Notification
        String.contains?(xml_content, "camt.054") -> :camt054
        String.contains?(xml_content, "urn:iso:std:iso:20022:tech:xsd:camt.054") -> :camt054
        true -> :unknown
      end
    rescue
      _ -> :unknown
    end
  end

  @doc """
  Parses CAMT XML entries into normalized maps.

  ## Examples

      iex> InvoiceGoblin.Finance.Camt.parse_entries(xml_content, :camt053)
      [%{booking_date: ~D[2025-09-13], direction: :income, amount: %Money{}, ...}, ...]
  """
  @spec parse_entries(binary(), :camt053 | :camt054) :: [map()]
  def parse_entries(xml_content, format) when format in [:camt053, :camt054] do
    try do
      parsed = parse_xml(xml_content)
      extract_entries(parsed, format)
    rescue
      e ->
        Logger.error("Exception parsing CAMT XML: #{inspect(e)}")
        []
    catch
      :exit, reason ->
        Logger.error("XML parsing failed: #{inspect(reason)}")
        []
    end
  end

  @doc """
  Extracts statement-level metadata from CAMT XML.

  ## Examples

      iex> InvoiceGoblin.Finance.Camt.parse_statement_metadata(xml_content, :camt053)
      %{
        account_iban: "LT123456789012345678",
        account_currency: "EUR",
        statement_date: ~D[2025-09-13],
        period_start: ~D[2025-09-01],
        period_end: ~D[2025-09-13],
        account_owner: %{
          name: "MB THE MYKOLAS",
          address: "UKMERGĖS G. 300H-42, VILNIUS",
          country: "LT",
          company_code: "306310457"
        }
      }
  """
  @spec parse_statement_metadata(binary(), :camt053 | :camt054) :: map()
  def parse_statement_metadata(xml_content, format) when format in [:camt053, :camt054] do
    try do
      parsed = parse_xml(xml_content)
      extract_statement_metadata(parsed, format)
    rescue
      e ->
        Logger.error("Exception parsing CAMT statement metadata: #{inspect(e)}")
        %{}
    catch
      :exit, reason ->
        Logger.error("XML statement metadata parsing failed: #{inspect(reason)}")
        %{}
    end
  end

  # Private functions

  defp extract_entries(parsed_xml, format) do
    entries =
      case format do
        :camt053 -> find_camt053_entries(parsed_xml)
        :camt054 -> find_camt054_entries(parsed_xml)
      end

    entries
    |> Enum.map(&normalize_entry/1)
    |> Enum.filter(&(&1 != nil))
  end

  defp find_camt053_entries(parsed_xml) do
    # Navigate to entries in CAMT.053 structure using XPath
    # Document/BkToCstmrStmt/Stmt/Ntry
    parsed_xml
    |> xpath(~x"//Document/BkToCstmrStmt/Stmt/Ntry"l)
  end

  defp find_camt054_entries(parsed_xml) do
    # Navigate to entries in CAMT.054 structure using XPath
    # Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Ntry
    parsed_xml
    |> xpath(~x"//Document/BkToCstmrDbtCdtNtfctn/Ntfctn/Ntry"l)
  end

  defp normalize_entry(entry) do
    try do
      # Extract basic information
      booking_date = extract_booking_date(entry)
      direction = extract_direction(entry)
      amount = extract_amount(entry)

      # Skip entries without essential data
      if booking_date && direction && amount do
        %{
          booking_date: booking_date,
          direction: direction,
          amount: amount,
          bank_mark: extract_bank_mark(entry),
          doc_number: extract_doc_number(entry),
          code: extract_code(entry),
          counterparty_name: extract_counterparty_name(entry),
          counterparty_reg_code: extract_counterparty_reg_code(entry),
          payment_purpose: extract_payment_purpose(entry),
          counterparty_iban: extract_counterparty_iban(entry),
          payment_code: extract_payment_code(entry),
          source_row_hash: calculate_source_hash(entry)
        }
      else
        Logger.warning("Skipping entry with missing essential data: #{inspect(entry)}")
        nil
      end
    rescue
      e ->
        Logger.error("Failed to normalize entry: #{inspect(e)}, entry: #{inspect(entry)}")
        nil
    end
  end

  defp extract_booking_date(entry) do
    # BookgDt/Dt or ValDt/Dt
    date_str = entry |> xpath(~x"./BookgDt/Dt/text()"s) || entry |> xpath(~x"./ValDt/Dt/text()"s)

    if date_str && date_str != "" do
      case Date.from_iso8601(date_str) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  end

  defp extract_direction(entry) do
    # CdtDbtInd: CRDT = credit (income), DBIT = debit (expense)
    case entry |> xpath(~x"./CdtDbtInd/text()"s) do
      "CRDT" -> :income
      "DBIT" -> :expense
      _ -> nil
    end
  end

  defp extract_amount(entry) do
    # Amt with currency attribute
    currency = entry |> xpath(~x"./Amt/@Ccy"s) || "EUR"
    amount_str = entry |> xpath(~x"./Amt/text()"s)

    if amount_str && amount_str != "" do
      parse_money(amount_str, currency)
    else
      nil
    end
  end

  defp parse_money(amount_str, currency) do
    case Decimal.parse(amount_str) do
      {decimal_amount, _} ->
        Money.new(decimal_amount, currency)

      :error ->
        nil
    end
  rescue
    _ -> nil
  end

  defp extract_bank_mark(entry) do
    # AcctSvcrRef or similar reference fields
    entry |> xpath(~x"./AcctSvcrRef/text()"s) || entry |> xpath(~x"./Refs/AcctSvcrRef/text()"s)
  end

  defp extract_doc_number(entry) do
    # EndToEndId, InstrId, or TxId
    entry |> xpath(~x"./NtryDtls/TxDtls/Refs/EndToEndId/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/Refs/InstrId/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/Refs/TxId/text()"s)
  end

  defp extract_code(entry) do
    # Bank transaction code
    entry |> xpath(~x"./BkTxCd/Cd/text()"s) || entry |> xpath(~x"./BkTxCd/Prtry/Cd/text()"s)
  end

  defp extract_counterparty_name(entry) do
    # Creditor or Debtor name
    entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/Cdtr/Nm/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/Dbtr/Nm/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/UltmtCdtr/Nm/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/UltmtDbtr/Nm/text()"s)
  end

  defp extract_counterparty_reg_code(entry) do
    # Organization identification
    entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/Cdtr/Id/OrgId/Othr/Id/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/Dbtr/Id/OrgId/Othr/Id/text()"s)
  end

  defp extract_payment_purpose(entry) do
    # Remittance information
    entry |> xpath(~x"./NtryDtls/TxDtls/RmtInf/Ustrd/text()"s) ||
      entry |> xpath(~x"./AddtlNtryInf/text()"s)
  end

  defp extract_counterparty_iban(entry) do
    # Creditor or Debtor account IBAN
    entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/CdtrAcct/Id/IBAN/text()"s) ||
      entry |> xpath(~x"./NtryDtls/TxDtls/RltdPties/DbtrAcct/Id/IBAN/text()"s)
  end

  defp extract_payment_code(entry) do
    # Purpose code
    entry |> xpath(~x"./NtryDtls/TxDtls/Purp/Cd/text()"s)
  end

  defp calculate_source_hash(entry) do
    # Create a stable hash from key fields to prevent duplicates
    # Include more unique identifiers to reduce false positives
    hash_data =
      [
        entry |> xpath(~x"./BookgDt/Dt/text()"s),
        # Value date
        entry |> xpath(~x"./ValDt/Dt/text()"s),
        entry |> xpath(~x"./Amt/text()"s),
        entry |> xpath(~x"./CdtDbtInd/text()"s),
        # Entry reference
        entry |> xpath(~x"./NtryRef/text()"s),
        # Account servicer reference
        entry |> xpath(~x"./AcctSvcrRef/text()"s),
        entry |> xpath(~x"./NtryDtls/TxDtls/Refs/EndToEndId/text()"s),
        # Transaction ID
        entry |> xpath(~x"./NtryDtls/TxDtls/Refs/TxId/text()"s),
        # Instruction ID
        entry |> xpath(~x"./NtryDtls/TxDtls/Refs/InstrId/text()"s),
        extract_counterparty_name(entry),
        extract_counterparty_iban(entry),
        extract_payment_purpose(entry)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("|")

    :crypto.hash(:sha256, hash_data) |> Base.encode16(case: :lower)
  end

  # Statement metadata extraction functions

  defp extract_statement_metadata(parsed_xml, format) do
    case format do
      :camt053 -> extract_camt053_statement_metadata(parsed_xml)
      :camt054 -> extract_camt054_statement_metadata(parsed_xml)
    end
  end

  defp extract_camt053_statement_metadata(parsed_xml) do
    # Navigate to statement info in CAMT.053 structure
    # Document/BkToCstmrStmt/Stmt
    statement_node = parsed_xml |> xpath(~x"//Document/BkToCstmrStmt/Stmt")

    %{
      account_iban: extract_account_iban(statement_node),
      account_currency: extract_account_currency(statement_node),
      statement_date: extract_creation_date(statement_node),
      period_start: extract_period_start(statement_node),
      period_end: extract_period_end(statement_node),
      account_owner: extract_account_owner(statement_node)
    }
  end

  defp extract_camt054_statement_metadata(parsed_xml) do
    # Navigate to notification info in CAMT.054 structure
    # Document/BkToCstmrDbtCdtNtfctn/Ntfctn
    notification_node = parsed_xml |> xpath(~x"//Document/BkToCstmrDbtCdtNtfctn/Ntfctn")

    %{
      account_iban: extract_account_iban(notification_node),
      account_currency: extract_account_currency(notification_node),
      statement_date: extract_creation_date(notification_node),
      period_start: nil,
      period_end: nil,
      account_owner: extract_account_owner(notification_node)
    }
  end

  defp extract_account_iban(statement_node) do
    # Account/Id/IBAN or Acct/Id/IBAN
    statement_node
    |> xpath(~x"./Acct/Id/IBAN/text()"s)
    |> case do
      "" -> nil
      iban -> iban
    end
  end

  defp extract_account_currency(statement_node) do
    # Acct/Ccy
    currency = statement_node |> xpath(~x"./Acct/Ccy/text()"s)

    if currency && currency != "" do
      currency
    else
      nil
    end
  end

  defp extract_creation_date(statement_node) do
    # CreDtTm (creation date time)
    date_str = statement_node |> xpath(~x"./CreDtTm/text()"s)

    if date_str && date_str != "" do
      # CAMT dates can be ISO datetime, extract date part
      case extract_date_from_datetime(date_str) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  end

  defp extract_period_start(statement_node) do
    # FrToDt/FrDtTm or ElctrncSeqNb
    date_str = statement_node |> xpath(~x"./FrToDt/FrDtTm/text()"s)

    if date_str && date_str != "" do
      case extract_date_from_datetime(date_str) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  end

  defp extract_period_end(statement_node) do
    # FrToDt/ToDtTm
    date_str = statement_node |> xpath(~x"./FrToDt/ToDtTm/text()"s)

    if date_str && date_str != "" do
      case extract_date_from_datetime(date_str) do
        {:ok, date} -> date
        _ -> nil
      end
    end
  end

  defp extract_date_from_datetime(datetime_str) do
    # Handle both full ISO datetime and date-only formats
    cond do
      # Full ISO datetime: 2025-09-13T14:30:00+03:00
      String.contains?(datetime_str, "T") ->
        case DateTime.from_iso8601(datetime_str) do
          {:ok, datetime, _} -> {:ok, DateTime.to_date(datetime)}
          _ -> try_parse_date_portion(datetime_str)
        end

      # Just date: 2025-09-13
      true ->
        Date.from_iso8601(datetime_str)
    end
  end

  defp try_parse_date_portion(datetime_str) do
    # Extract date portion before T
    case String.split(datetime_str, "T") do
      [date_portion | _] -> Date.from_iso8601(date_portion)
      _ -> :error
    end
  end

  defp extract_account_owner(statement_node) do
    # Extract account owner information from Acct/Ownr
    # Path: Acct/Ownr/Nm, Acct/Ownr/PstlAdr/AdrLine, Acct/Ownr/PstlAdr/Ctry, Acct/Ownr/Id/OrgId/Othr/Id
    owner_name = statement_node |> xpath(~x"./Acct/Ownr/Nm/text()"s)

    # Address can be in AdrLine or split into multiple components
    address_line = statement_node |> xpath(~x"./Acct/Ownr/PstlAdr/AdrLine/text()"s)
    country = statement_node |> xpath(~x"./Acct/Ownr/PstlAdr/Ctry/text()"s)

    # Company code from organization ID
    company_code = statement_node |> xpath(~x"./Acct/Ownr/Id/OrgId/Othr/Id/text()"s)

    cond do
      owner_name && owner_name != "" ->
        %{
          name: owner_name,
          address: if(address_line && address_line != "", do: address_line, else: nil),
          country: if(country && country != "", do: country, else: nil),
          company_code: if(company_code && company_code != "", do: company_code, else: nil)
        }

      true ->
        nil
    end
  end
end
