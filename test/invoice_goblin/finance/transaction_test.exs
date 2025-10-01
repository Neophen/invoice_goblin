defmodule InvoiceGoblin.Finance.TransactionTest do
  use InvoiceGoblin.DataCase, async: true

  alias InvoiceGoblin.Finance.Transaction
  alias InvoiceGoblin.Accounts.{Organisation, User}
  require Ash.Query
  import Ash.Expr

  setup do
    # Create test organisation
    {:ok, org} = Ash.create(Organisation, %{name: "Test Org"}, action: :create)

    %{organisation: org, tenant: org.id}
  end

  describe "create transaction" do
    test "creates a valid transaction", %{tenant: tenant} do
      attrs = %{
        booking_date: ~D[2025-08-01],
        direction: :expense,
        amount: Money.new(:EUR, "11.00"),
        payment_purpose: "Test payment",
        source_row_hash: "test_hash_#{System.unique_integer()}"
      }

      assert {:ok, transaction} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
      assert transaction.booking_date == ~D[2025-08-01]
      assert transaction.direction == :expense
      assert transaction.amount == Money.new(:EUR, "11.00")
    end

    test "requires booking_date", %{tenant: tenant} do
      attrs = %{
        direction: :expense,
        amount: Money.new(:EUR, "10.00"),
        source_row_hash: "test_hash_#{System.unique_integer()}"
      }

      assert {:error, %Ash.Error.Invalid{}} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
    end

    test "requires direction", %{tenant: tenant} do
      attrs = %{
        booking_date: ~D[2025-08-01],
        amount: Money.new(:EUR, "10.00"),
        source_row_hash: "test_hash_#{System.unique_integer()}"
      }

      assert {:error, %Ash.Error.Invalid{}} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
    end

    test "requires amount", %{tenant: tenant} do
      attrs = %{
        booking_date: ~D[2025-08-01],
        direction: :expense,
        source_row_hash: "test_hash_#{System.unique_integer()}"
      }

      assert {:error, %Ash.Error.Invalid{}} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
    end
  end

  describe "ingest action" do
    test "creates transaction with ingest action", %{tenant: tenant} do
      attrs = %{
        booking_date: ~D[2025-08-01],
        direction: :income,
        amount: Money.new(:EUR, "100.00"),
        payment_purpose: "Invoice payment",
        counterparty_name: "Test Client",
        counterparty_iban: "LT123456789",
        source_row_hash: "ingest_hash_#{System.unique_integer()}"
      }

      assert {:ok, transaction} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
      assert transaction.counterparty_name == "Test Client"
      assert transaction.counterparty_iban == "LT123456789"
    end

    test "prevents duplicate transactions with same source_row_hash", %{tenant: tenant} do
      hash = "duplicate_hash_#{System.unique_integer()}"

      attrs = %{
        booking_date: ~D[2025-08-01],
        direction: :income,
        amount: Money.new(:EUR, "100.00"),
        source_row_hash: hash
      }

      # First creation should succeed
      assert {:ok, _transaction} = Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)

      # Second creation with same hash should fail
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(Transaction, attrs, action: :ingest, tenant: tenant)
    end
  end

  describe "tenant isolation" do
    test "transactions are isolated by tenant", %{organisation: org1, tenant: tenant1} do
      # Create second organisation
      {:ok, org2} = Ash.create(Organisation, %{name: "Test Org 2"}, action: :create)
      tenant2 = org2.id

      # Create transaction in first tenant
      attrs1 = %{
        booking_date: ~D[2025-08-01],
        direction: :income,
        amount: Money.new(:EUR, "100.00"),
        source_row_hash: "tenant1_hash_#{System.unique_integer()}"
      }

      assert {:ok, tx1} = Ash.create(Transaction, attrs1, action: :ingest, tenant: tenant1)

      # Create transaction in second tenant
      attrs2 = %{
        booking_date: ~D[2025-08-02],
        direction: :expense,
        amount: Money.new(:EUR, "50.00"),
        source_row_hash: "tenant2_hash_#{System.unique_integer()}"
      }

      assert {:ok, tx2} = Ash.create(Transaction, attrs2, action: :ingest, tenant: tenant2)

      # Query tenant1 should only see tx1
      {:ok, tenant1_txs} = Ash.read(Transaction, tenant: tenant1)
      assert length(tenant1_txs) == 1
      assert Enum.find(tenant1_txs, &(&1.id == tx1.id))
      refute Enum.find(tenant1_txs, &(&1.id == tx2.id))

      # Query tenant2 should only see tx2
      {:ok, tenant2_txs} = Ash.read(Transaction, tenant: tenant2)
      assert length(tenant2_txs) == 1
      assert Enum.find(tenant2_txs, &(&1.id == tx2.id))
      refute Enum.find(tenant2_txs, &(&1.id == tx1.id))
    end
  end

  describe "filtering" do
    test "filters by direction", %{tenant: tenant} do
      # Create income transaction
      {:ok, _income} =
        Ash.create(
          Transaction,
          %{
            booking_date: ~D[2025-08-01],
            direction: :income,
            amount: Money.new(:EUR, "100.00"),
            source_row_hash: "income_hash_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      # Create expense transaction
      {:ok, _expense} =
        Ash.create(
          Transaction,
          %{
            booking_date: ~D[2025-08-02],
            direction: :expense,
            amount: Money.new(:EUR, "50.00"),
            source_row_hash: "expense_hash_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      # Filter for income only
      {:ok, income_txs} =
        Transaction
        |> Ash.Query.filter(expr(direction == :income))
        |> Ash.read(tenant: tenant)

      assert length(income_txs) == 1
      assert Enum.all?(income_txs, &(&1.direction == :income))

      # Filter for expense only
      {:ok, expense_txs} =
        Transaction
        |> Ash.Query.filter(expr(direction == :expense))
        |> Ash.read(tenant: tenant)

      assert length(expense_txs) == 1
      assert Enum.all?(expense_txs, &(&1.direction == :expense))
    end

    test "sorts by booking_date", %{tenant: tenant} do
      # Create transactions in random order
      {:ok, _tx1} =
        Ash.create(
          Transaction,
          %{
            booking_date: ~D[2025-08-15],
            direction: :income,
            amount: Money.new(:EUR, "100.00"),
            source_row_hash: "sort1_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      {:ok, _tx2} =
        Ash.create(
          Transaction,
          %{
            booking_date: ~D[2025-08-01],
            direction: :income,
            amount: Money.new(:EUR, "50.00"),
            source_row_hash: "sort2_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      {:ok, _tx3} =
        Ash.create(
          Transaction,
          %{
            booking_date: ~D[2025-08-30],
            direction: :income,
            amount: Money.new(:EUR, "75.00"),
            source_row_hash: "sort3_#{System.unique_integer()}"
          },
          action: :ingest,
          tenant: tenant
        )

      # Sort descending
      {:ok, sorted_desc} =
        Transaction
        |> Ash.Query.sort(booking_date: :desc)
        |> Ash.read(tenant: tenant)

      assert length(sorted_desc) == 3
      assert Enum.at(sorted_desc, 0).booking_date == ~D[2025-08-30]
      assert Enum.at(sorted_desc, 1).booking_date == ~D[2025-08-15]
      assert Enum.at(sorted_desc, 2).booking_date == ~D[2025-08-01]
    end
  end
end
