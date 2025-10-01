defmodule InvoiceGoblinWeb.StatementDetailLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  alias InvoiceGoblin.Finance.Statement
  alias InvoiceGoblin.Finance.Transaction

  require Ash.Query

  @impl true
  def mount(%{"id" => statement_id}, _session, socket) do
    case Ash.get(Statement, statement_id, load: [:transactions]) do
      {:ok, statement} ->
        socket
        |> assign(:statement, statement)
        |> assign(:download_url, Statement.download_url(statement))
        |> assign(:page, 1)
        |> assign(:page_size, 25)
        |> assign(:loading, false)
        |> assign(:total_revenue, calculate_total_revenue(statement.id))
        |> load_transactions()
        |> ok()

      {:error, %Ash.Error.Query.NotFound{}} ->
        socket
        |> put_flash(:error, "Statement not found")
        |> push_navigate(to: ~p"/statements")
        |> ok()

      {:error, _error} ->
        socket
        |> put_flash(:error, "Failed to load statement")
        |> push_navigate(to: ~p"/statements")
        |> ok()
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()

    socket
    |> assign(:page, page)
    |> load_transactions()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.app flash={@flash} current_user={@current_user}>
      <!-- Header -->
      <div class="flex items-center space-x-4">
        <.link
          navigate={~p"/statements"}
          class="inline-flex items-center text-gray-500 hover:text-gray-700"
        >
          <.icon name="hero-arrow-left" class="h-5 w-5 mr-1" /> Back to Statements
        </.link>
      </div>
      
    <!-- Statement Info -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="flex items-center justify-between">
            <div class="flex-1 min-w-0">
              <h1 class="text-xl font-bold leading-7 text-gray-900 sm:truncate sm:tracking-tight">
                {@statement.title}
              </h1>
              <div class="mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6">
                <div
                  :if={@statement.account_iban}
                  class="mt-2 flex items-center text-sm text-gray-500"
                >
                  <.icon name="hero-credit-card" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
                  {@statement.account_iban}
                </div>
                <div
                  :if={@statement.statement_date}
                  class="mt-2 flex items-center text-sm text-gray-500"
                >
                  <.icon name="hero-calendar" class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" />
                  {@statement.statement_date}
                </div>
                <div
                  :if={@statement.statement_period_start && @statement.statement_period_end}
                  class="mt-2 flex items-center text-sm text-gray-500"
                >
                  <.icon
                    name="hero-calendar-days"
                    class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                  />
                  {@statement.statement_period_start} - {@statement.statement_period_end}
                </div>
                <div
                  :if={@statement.file_size}
                  class="mt-2 flex items-center text-sm text-gray-500"
                >
                  <.icon
                    name="hero-document"
                    class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                  />
                  {format_file_size(@statement.file_size)}
                </div>
              </div>
            </div>
            <div class="flex space-x-3">
              <a
                href={@download_url}
                download
                class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <.icon name="hero-arrow-down-tray" class="h-4 w-4 mr-1" /> Download File
              </a>
            </div>
          </div>
          
    <!-- Statement Metadata -->
          <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-3">
            <div class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-banknotes" class="h-6 w-6 text-gray-400" />
                </div>
                <div class="ml-3">
                  <p class="text-sm font-medium text-gray-500">Transactions</p>
                  <p class="text-lg font-semibold text-gray-900">
                    {length(@transactions)}
                  </p>
                </div>
              </div>
            </div>

            <div class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-chart-bar" class="h-6 w-6 text-gray-400" />
                </div>
                <div class="ml-3">
                  <p class="text-sm font-medium text-gray-500">Total Revenue</p>
                  <p class={[
                    "text-lg font-semibold",
                    if(Money.negative?(@total_revenue), do: "text-red-600", else: "text-green-600")
                  ]}>
                    {format_currency(@total_revenue)}
                  </p>
                </div>
              </div>
            </div>

            <div class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center">
                <div class="flex-shrink-0">
                  <.icon name="hero-clock" class="h-6 w-6 text-gray-400" />
                </div>
                <div class="ml-3">
                  <p class="text-sm font-medium text-gray-500">Uploaded</p>
                  <p class="text-lg font-semibold text-gray-900">
                    {format_datetime(@statement.inserted_at)}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Transactions List -->
      <div :if={@loading} class="text-center py-8">
        <.icon name="hero-arrow-path" class="h-8 w-8 animate-spin mx-auto text-gray-400" />
        <p class="text-gray-500 mt-2">Loading transactions...</p>
      </div>

      <div :if={!@loading && Enum.empty?(@transactions)} class="text-center py-8">
        <.icon name="hero-banknotes" class="h-12 w-12 mx-auto text-gray-400" />
        <h3 class="mt-2 text-sm font-medium text-gray-900">No transactions</h3>
        <p class="mt-1 text-sm text-gray-500">
          This statement doesn't contain any transactions.
        </p>
      </div>

      <div
        :if={!@loading && !Enum.empty?(@transactions)}
        class="overflow-hidden shadow md:rounded-lg"
      >
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Date
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Purpose
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Amount
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Status
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr :for={transaction <- @transactions} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {transaction.booking_date}
              </td>
              <td class="px-6 py-4">
                <div class="text-sm text-gray-900 max-w-xs truncate">
                  {transaction.payment_purpose || "No purpose specified"}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class={[
                  "text-sm font-medium",
                  if(transaction.direction == :income,
                    do: "text-green-600",
                    else: "text-red-600"
                  )
                ]}>
                  {if transaction.direction == :income, do: "+", else: "-"}{transaction.amount}
                </div>
              </td>
              <%!-- <td class="px-6 py-4 whitespace-nowrap">
                      <span
                        :if={transaction.invoice_id}
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                      >
                        Linked
                      </span>
                      <span
                        :if={!transaction.invoice_id}
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
                      >
                        Unlinked
                      </span>
                    </td> --%>
            </tr>
          </tbody>
        </table>
      </div>
      
    <!-- Pagination -->
      <div :if={!@loading && !Enum.empty?(@transactions)} class="mt-6">
        <.pagination_controls
          page={@page}
          page_size={@page_size}
          total_count={length(@transactions)}
          base_path={~p"/statements/#{@statement.id}"}
        />
      </div>
    </Layout.app>
    """
  end

  defp load_transactions(
         %{
           assigns: %{
             statement: statement,
             page: page,
             page_size: page_size
           }
         } = socket
       ) do
    socket = assign(socket, :loading, true)

    query =
      Transaction
      |> Ash.Query.filter(statement_id == ^statement.id)
      |> Ash.Query.sort(booking_date: :desc)
      |> Ash.Query.limit(page_size)
      |> Ash.Query.offset((page - 1) * page_size)

    case Ash.read(query) do
      {:ok, transactions} ->
        socket
        |> assign(:transactions, transactions)
        |> assign(:total_revenue, calculate_total_revenue(statement.id))
        |> assign(:loading, false)

      {:error, _error} ->
        socket
        |> assign(:transactions, [])
        |> assign(:total_revenue, Money.new(:EUR, 0))
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load transactions")
    end
  end

  defp calculate_total_revenue(statement_id) do
    query =
      Transaction
      |> Ash.Query.filter(statement_id == ^statement_id)

    case Ash.read(query) do
      {:ok, transactions} ->
        zero_eur = Money.new(:EUR, 0)

        {income, expenses} =
          transactions
          |> Enum.reduce({zero_eur, zero_eur}, fn transaction, {income_acc, expense_acc} ->
            case transaction.direction do
              :income ->
                {:ok, new_income} = Money.add(income_acc, transaction.amount)
                {new_income, expense_acc}

              :expense ->
                {:ok, new_expense} = Money.add(expense_acc, transaction.amount)
                {income_acc, new_expense}
            end
          end)

        {:ok, total_revenue} = Money.sub(income, expenses)
        total_revenue

      {:error, _} ->
        Money.new(:EUR, 0)
    end
  end

  defp format_currency(money) do
    {:ok, formatted} = Money.to_string(money)
    formatted
  end

  defp format_file_size(nil), do: "Unknown"

  defp format_file_size(size) when is_integer(size) do
    cond do
      size >= 1_000_000 -> "#{Float.round(size / 1_000_000, 1)} MB"
      size >= 1_000 -> "#{Float.round(size / 1_000, 1)} KB"
      true -> "#{size} B"
    end
  end

  defp format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp format_datetime(_), do: "Unknown"

  attr :page, :integer, required: true
  attr :page_size, :integer, required: true
  attr :total_count, :integer, required: true
  attr :base_path, :string, required: true

  defp pagination_controls(assigns) do
    ~H"""
    <div class="flex items-center justify-between border-t border-gray-200 px-4 py-3 sm:px-6">
      <div class="flex flex-1 justify-between sm:hidden">
        <.link
          :if={@page > 1}
          patch={"#{@base_path}?page=#{@page - 1}"}
          class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Previous
        </.link>
        <.link
          :if={@total_count == @page_size}
          patch={"#{@base_path}?page=#{@page + 1}"}
          class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Next
        </.link>
      </div>
      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing <span class="font-medium">{(@page - 1) * @page_size + 1}</span>
            to <span class="font-medium">{@page * @page_size}</span>
            results
          </p>
        </div>
        <div>
          <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <.link
              :if={@page > 1}
              patch={"#{@base_path}?page=#{@page - 1}"}
              class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
            >
              <span class="sr-only">Previous</span>
              <.icon name="hero-chevron-left" class="h-5 w-5" aria-hidden="true" />
            </.link>
            <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">
              {@page}
            </span>
            <.link
              :if={@total_count == @page_size}
              patch={"#{@base_path}?page=#{@page + 1}"}
              class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
            >
              <span class="sr-only">Next</span>
              <.icon name="hero-chevron-right" class="h-5 w-5" aria-hidden="true" />
            </.link>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  defp get_tenant(socket) do
    # Get the first organisation from the current user
    # TODO: Add proper organisation selection in production
    case socket.assigns.current_user do
      %{organisations: [%{id: org_id} | _]} -> org_id
      _ -> nil
    end
  end
end