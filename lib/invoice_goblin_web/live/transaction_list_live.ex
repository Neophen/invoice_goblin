defmodule InvoiceGoblinWeb.TransactionListLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout
  alias InvoiceGoblin.Finance
  import Ash.Expr

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, transactions} =
      Finance.Transaction
      |> Ash.Query.load(:counter_party)
      |> Ash.Query.sort(booking_date: :desc)
      |> Ash.read()

    {:ok,
     socket
     |> assign(:transactions, transactions)
     |> assign(:filter_direction, nil)}
  end

  @impl true
  def handle_event("filter", %{"direction" => direction}, socket) do
    filter_direction = if direction == "all", do: nil, else: String.to_existing_atom(direction)

    filter =
      if filter_direction do
        expr(direction == ^filter_direction)
      else
        []
      end

    {:ok, transactions} =
      Ash.read(Finance.Transaction,
        filter: filter,
        load: [:counter_party],
        sort: [booking_date: :desc]
      )

    {:noreply,
     socket
     |> assign(:transactions, transactions)
     |> assign(:filter_direction, filter_direction)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-6">Transactions</h1>

        <div class="bg-white rounded-lg shadow-md">
          <div class="p-4 border-b border-gray-200">
            <div class="flex items-center space-x-4">
              <label class="text-sm font-medium text-gray-700">Filter by direction:</label>
              <select
                phx-change="filter"
                name="direction"
                class="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all" selected={@filter_direction == nil}>All</option>
                <option value="income" selected={@filter_direction == :income}>Income</option>
                <option value="expense" selected={@filter_direction == :expense}>Expense</option>
              </select>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Counterparty
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Purpose
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Amount
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Direction
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr :for={transaction <- @transactions} class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {Calendar.strftime(transaction.booking_date, "%B %d, %Y")}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={transaction.counter_party} class="text-sm font-medium text-gray-900">
                      {transaction.counter_party.name}
                    </div>
                    <div :if={!transaction.counter_party} class="text-sm text-gray-900">
                      {transaction.counterparty_name || "Unknown"}
                    </div>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-900">
                    {transaction.payment_purpose || "-"}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <span class={[
                      transaction.direction == :income && "text-green-600",
                      transaction.direction == :expense && "text-red-600"
                    ]}>
                      {transaction.amount}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                      transaction.direction == :income && "bg-green-100 text-green-800",
                      transaction.direction == :expense && "bg-red-100 text-red-800"
                    ]}>
                      {transaction.direction}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>

            <div :if={@transactions == []} class="text-center py-8">
              <p class="text-gray-500">No transactions found</p>
            </div>
          </div>
        </div>
      </div>
    </Layout.app>
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