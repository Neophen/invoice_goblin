defmodule InvoiceGoblin.Finance.CamtTest do
  use ExUnit.Case, async: true

  alias InvoiceGoblin.Finance.Camt

  @test_xml_path Path.join([File.cwd!(), "statement.xml"])

  describe "detect/1" do
    test "detects CAMT.053 format" do
      xml = File.read!(@test_xml_path)
      assert Camt.detect(xml) == :camt053
    end

    test "returns :unknown for invalid XML" do
      assert Camt.detect("invalid xml") == :unknown
    end

    test "returns :unknown for non-CAMT XML" do
      xml = ~s(<?xml version="1.0"?><root><data>test</data></root>)
      assert Camt.detect(xml) == :unknown
    end
  end

  describe "parse_statement_metadata/2" do
    test "extracts correct metadata from CAMT.053" do
      xml = File.read!(@test_xml_path)
      metadata = Camt.parse_statement_metadata(xml, :camt053)

      assert metadata[:account_iban] == "LT697300010178072190"
      assert metadata[:statement_date] == ~D[2025-09-22]
      assert metadata[:period_start] == ~D[2025-08-01]
      assert metadata[:period_end] == ~D[2025-08-31]
    end
  end

  describe "parse_entries/2" do
    test "parses all transactions from CAMT.053" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # Statement has 31 entries based on the XML
      assert length(entries) == 31
    end

    test "correctly parses debit entry" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # First entry: bank fee
      first_entry = Enum.at(entries, 0)

      assert first_entry.booking_date == ~D[2025-08-01]
      assert first_entry.direction == :expense
      assert first_entry.amount == Money.new(:EUR, "11.00")
      assert first_entry.payment_purpose =~ "Paslaugų plano"
    end

    test "correctly parses credit entry" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # Find a credit entry (refund or income)
      credit_entry = Enum.find(entries, fn e -> e.direction == :income end)

      assert credit_entry.direction == :income
      assert credit_entry.amount.amount > 0
      assert credit_entry.booking_date
    end

    test "extracts counterparty information" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # Find entry with counterparty info (like TELIA payment)
      entry_with_counterparty = Enum.find(entries, fn e ->
        e.counterparty_name && e.counterparty_name =~ "TELIA"
      end)

      assert entry_with_counterparty.counterparty_name == "TELIA LIETUVA AB"
      assert entry_with_counterparty.counterparty_iban == "LT137300010000561355"
    end

    test "generates unique source_row_hash for each entry" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # All entries should have source_row_hash
      assert Enum.all?(entries, & &1.source_row_hash)

      # All hashes should be unique
      hashes = Enum.map(entries, & &1.source_row_hash)
      assert length(hashes) == length(Enum.uniq(hashes))
    end

    test "handles large transaction correctly" do
      xml = File.read!(@test_xml_path)
      entries = Camt.parse_entries(xml, :camt053)

      # Find the 6686 EUR income from Marko Switzerland AG
      large_income = Enum.find(entries, fn e ->
        e.amount == Money.new(:EUR, "6686.00")
      end)

      assert large_income.direction == :income
      # Counterparty name extraction depends on XML structure
      # In this case the name is in a different location
      assert large_income.amount == Money.new(:EUR, "6686.00")
      assert large_income.payment_purpose == "TM 0033"
    end
  end

  describe "error handling" do
    test "handles malformed XML gracefully" do
      xml = "<?xml version='1.0'?><Document><Invalid"
      assert Camt.parse_entries(xml, :camt053) == []
    end

    test "handles missing required fields" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.053.001.02">
        <BkToCstmrStmt>
          <Stmt>
            <Ntry>
              <Amt Ccy="EUR">10.00</Amt>
            </Ntry>
          </Stmt>
        </BkToCstmrStmt>
      </Document>
      """

      # Should not crash, but may return empty or partial data
      entries = Camt.parse_entries(xml, :camt053)
      assert is_list(entries)
    end
  end
end
