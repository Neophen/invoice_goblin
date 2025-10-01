defmodule InvoiceGoblin.Finance.StatementTest do
  use InvoiceGoblin.DataCase, async: true

  alias InvoiceGoblin.Finance.{Statement, Transaction}
  alias InvoiceGoblin.Accounts.Organisation
  require Ash.Query
  import Ash.Expr

  setup do
    # Create test organisation
    {:ok, org} = Ash.create(Organisation, %{name: "Test Org"}, action: :create)

    %{organisation: org, tenant: org.id}
  end

  describe "create statement" do
    test "creates a valid statement", %{tenant: tenant} do
      attrs = %{
        file_url: "https://example.com/statement.xml",
        file_name: "statement.xml",
        file_size: 12345,
        account_iban: "LT697300010178072190",
        statement_date: ~D[2025-08-31],
        statement_period_start: ~D[2025-08-01],
        statement_period_end: ~D[2025-08-31],
        title: "Statement Aug 2025"
      }

      assert {:ok, statement} = Ash.create(Statement, attrs, action: :create, tenant: tenant)
      assert statement.file_name == "statement.xml"
      assert statement.account_iban == "LT697300010178072190"
      assert statement.statement_date == ~D[2025-08-31]
    end

    test "requires file_url", %{tenant: tenant} do
      attrs = %{
        file_name: "statement.xml",
        file_size: 12345
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Statement, attrs, action: :create, tenant: tenant)
    end

    test "generates title if not provided", %{tenant: tenant} do
      attrs = %{
        file_url: "https://example.com/statement.xml",
        file_name: "statement.xml",
        file_size: 12345,
        account_iban: "LT697300010178072190",
        statement_date: ~D[2025-08-31],
        statement_period_start: ~D[2025-08-01],
        statement_period_end: ~D[2025-08-31]
      }

      assert {:ok, statement} = Ash.create(Statement, attrs, action: :create, tenant: tenant)
      # Title should be auto-generated
      assert statement.title
      assert statement.title =~ "LT69"
    end
  end

  describe "generate_title/1" do
    test "generates title with IBAN and date" do
      attrs = %{
        account_iban: "LT697300010178072190",
        statement_date: ~D[2025-08-31]
      }

      title = Statement.generate_title(attrs)
      assert title == "Bank Statement - LT697300010178072190 - 2025-08-31"
    end

    test "generates title with IBAN and period" do
      attrs = %{
        account_iban: "LT697300010178072190",
        statement_period_start: ~D[2025-08-01],
        statement_period_end: ~D[2025-08-31]
      }

      title = Statement.generate_title(attrs)
      assert title == "Bank Statement - LT697300010178072190 - 2025-08-01 to 2025-08-31"
    end

    test "generates title with just file name" do
      attrs = %{
        file_name: "statement.xml"
      }

      title = Statement.generate_title(attrs)
      assert title =~ "Bank Statement - statement.xml"
    end

    test "handles missing all fields" do
      attrs = %{}

      title = Statement.generate_title(attrs)
      assert title =~ "Bank Statement -"
    end
  end

  describe "download_url/1" do
    test "returns presigned URL for statement", %{tenant: tenant} do
      attrs = %{
        file_url: "https://example.com/statement.xml",
        file_name: "statement.xml",
        file_size: 12345,
        title: "Test Statement"
      }

      {:ok, statement} = Ash.create(Statement, attrs, action: :create, tenant: tenant)
      url = Statement.download_url(statement)
      # Should return a presigned URL with query parameters
      assert String.starts_with?(url, "https://example.com/statement.xml?")
      assert String.contains?(url, "X-Amz-Algorithm")
    end
  end

  describe "relationships" do
    test "loads transactions relationship", %{tenant: tenant} do
      # Create statement
      {:ok, statement} =
        Ash.create(
          Statement,
          %{
            file_url: "https://example.com/statement.xml",
            file_name: "statement.xml",
            file_size: 12345,
            title: "Test Statement"
          },
          action: :create,
          tenant: tenant
        )

      # Create transactions for this statement
      {:ok, _tx1} =
        Ash.create(
          Transaction,
          %{
            statement_id: statement.id,
            booking_date: ~D[2025-08-01],
            direction: :income,
            amount: Money.new(:EUR, "100.00"),
            source_row_hash: "stmt_tx1_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      {:ok, _tx2} =
        Ash.create(
          Transaction,
          %{
            statement_id: statement.id,
            booking_date: ~D[2025-08-02],
            direction: :expense,
            amount: Money.new(:EUR, "50.00"),
            source_row_hash: "stmt_tx2_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      # Load statement with transactions
      {:ok, loaded_statement} =
        Statement
        |> Ash.Query.filter(expr(id == ^statement.id))
        |> Ash.Query.load(:transactions)
        |> Ash.read_one(tenant: tenant)

      assert length(loaded_statement.transactions) == 2
    end
  end

  describe "tenant isolation" do
    test "statements are isolated by tenant", %{organisation: org1, tenant: tenant1} do
      # Create second organisation
      {:ok, org2} = Ash.create(Organisation, %{name: "Test Org 2"}, action: :create)
      tenant2 = org2.id

      # Create statement in first tenant
      {:ok, stmt1} =
        Ash.create(
          Statement,
          %{
            file_url: "https://example.com/statement1.xml",
            file_name: "statement1.xml",
            file_size: 12345,
            title: "Statement 1"
          },
          action: :create,
          tenant: tenant1
        )

      # Create statement in second tenant
      {:ok, stmt2} =
        Ash.create(
          Statement,
          %{
            file_url: "https://example.com/statement2.xml",
            file_name: "statement2.xml",
            file_size: 67890,
            title: "Statement 2"
          },
          action: :create,
          tenant: tenant2
        )

      # Query tenant1 should only see stmt1
      {:ok, tenant1_stmts} = Ash.read(Statement, tenant: tenant1)
      assert length(tenant1_stmts) == 1
      assert Enum.find(tenant1_stmts, &(&1.id == stmt1.id))
      refute Enum.find(tenant1_stmts, &(&1.id == stmt2.id))

      # Query tenant2 should only see stmt2
      {:ok, tenant2_stmts} = Ash.read(Statement, tenant: tenant2)
      assert length(tenant2_stmts) == 1
      assert Enum.find(tenant2_stmts, &(&1.id == stmt2.id))
      refute Enum.find(tenant2_stmts, &(&1.id == stmt1.id))
    end
  end
end
