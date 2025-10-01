defmodule InvoiceGoblinWeb.InvoiceListLive do
  use InvoiceGoblinWeb, :live_view
  alias InvoiceGoblin.Finance
  alias UI.Components.Layout
  import Ash.Expr

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    tenant = get_tenant(socket)
    {:ok, invoices} = Ash.read(Finance.Invoice, load: [:counter_party], tenant: tenant)

    {:ok,
     socket
     |> assign(:invoices, invoices)
     |> assign(:filter_status, nil)
     |> assign(:selected_invoices, MapSet.new())
     |> assign(:bulk_action, nil)}
  end

  @impl true
  def handle_event("toggle_invoice", %{"id" => id}, socket) do
    selected = socket.assigns.selected_invoices

    updated_selected =
      if MapSet.member?(selected, id) do
        MapSet.delete(selected, id)
      else
        MapSet.put(selected, id)
      end

    {:noreply, assign(socket, :selected_invoices, updated_selected)}
  end

  @impl true
  def handle_event("toggle_all", %{"checked" => "true"}, socket) do
    all_ids = Enum.map(socket.assigns.invoices, & &1.id) |> MapSet.new()
    {:noreply, assign(socket, :selected_invoices, all_ids)}
  end

  @impl true
  def handle_event("toggle_all", _params, socket) do
    {:noreply, assign(socket, :selected_invoices, MapSet.new())}
  end

  @impl true
  def handle_event("bulk_action", %{"action" => action}, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_invoices)

    case action do
      "export" ->
        export_invoices(socket, selected_ids)

      "delete" ->
        delete_invoices(socket, selected_ids)

      "mark_matched" ->
        update_status(socket, selected_ids, :matched)

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("export_csv", _params, socket) do
    csv_content = generate_csv(socket.assigns.invoices)

    {:noreply,
     socket
     |> push_event("download", %{
       content: csv_content,
       filename: "invoices_#{Date.to_string(Date.utc_today())}.csv",
       mime_type: "text/csv"
     })}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    tenant = get_tenant(socket)

    filter =
      if query != "" do
        expr(
          ilike(title, ^"%#{query}%") or
            (not is_nil(counter_party_id) and ilike(counter_party.name, ^"%#{query}%"))
        )
      else
        []
      end

    {:ok, invoices} = Ash.read(Finance.Invoice, filter: filter, load: [:counter_party], tenant: tenant)

    {:noreply, assign(socket, :invoices, invoices)}
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) do
    tenant = get_tenant(socket)
    filter_status = if status == "all", do: nil, else: String.to_existing_atom(status)

    filter =
      if filter_status do
        [status: filter_status]
      else
        []
      end

    {:ok, invoices} = Ash.read(Finance.Invoice, filter: filter, load: [:counter_party], tenant: tenant)

    {:noreply,
     socket
     |> assign(:invoices, invoices)
     |> assign(:filter_status, filter_status)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8" id="invoice-list" phx-hook="Download">
        <div class="mb-6 flex items-center justify-between">
          <h1 class="text-3xl font-bold">Invoices</h1>
          <.link
            navigate={~p"/invoices/upload"}
            class="bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
          >
            Upload Invoice
          </.link>
        </div>

        <div class="bg-white rounded-lg shadow-md">
          <div class="p-4 border-b border-gray-200">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <input
                  type="text"
                  name="query"
                  phx-keyup="search"
                  placeholder="Search invoices..."
                  class="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <label class="text-sm font-medium text-gray-700">Filter by status:</label>
                <select
                  phx-change="filter"
                  name="status"
                  class="px-3 py-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="all" selected={@filter_status == nil}>All</option>
                  <option value="processing" selected={@filter_status == :processing}>
                    Processing
                  </option>
                  <option value="parsed" selected={@filter_status == :parsed}>Parsed</option>
                  <option value="matched" selected={@filter_status == :matched}>Matched</option>
                  <option value="error" selected={@filter_status == :error}>Error</option>
                </select>
              </div>
              <button
                phx-click="export_csv"
                class="bg-green-600 text-white py-1 px-3 rounded-md hover:bg-green-700 transition-colors text-sm"
              >
                Export CSV
              </button>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Invoice
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Counterparty
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Amount
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr :for={invoice <- @invoices} class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div class="text-sm font-medium text-gray-900">{invoice.title}</div>
                      <div class="text-sm text-gray-500">{invoice.direction}</div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={invoice.counter_party} class="text-sm text-gray-900">
                      {invoice.counter_party.name}
                    </div>
                    <div :if={!invoice.counter_party} class="text-sm text-gray-400">
                      Not parsed
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={invoice.amount} class="text-sm font-medium text-gray-900">
                      {invoice.currency} {invoice.amount}
                    </div>
                    <div :if={!invoice.amount} class="text-sm text-gray-400">
                      Not parsed
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={invoice.invoice_date} class="text-sm text-gray-900">
                      {Calendar.strftime(invoice.invoice_date, "%B %d, %Y")}
                    </div>
                    <div :if={!invoice.invoice_date} class="text-sm text-gray-400">
                      Not parsed
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={[
                      "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                      invoice.status == :processing && "bg-yellow-100 text-yellow-800",
                      invoice.status == :parsed && "bg-green-100 text-green-800",
                      invoice.status == :matched && "bg-blue-100 text-blue-800",
                      invoice.status == :error && "bg-red-100 text-red-800"
                    ]}>
                      {invoice.status}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm">
                    <.link
                      navigate={~p"/invoices/#{invoice.id}"}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      View
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>

            <div :if={@invoices == []} class="text-center py-8">
              <p class="text-gray-500">No invoices found</p>
            </div>
          </div>
        </div>
      </div>
    </Layout.app>
    """
  end

  defp generate_csv(invoices) do
    headers = [
      "Title",
      "Counterparty",
      "Amount",
      "Currency",
      "Invoice Date",
      "Status",
      "Direction"
    ]

    rows =
      Enum.map(invoices, fn invoice ->
        [
          invoice.title,
          (invoice.counter_party && invoice.counter_party.name) || "",
          invoice.amount || "",
          invoice.currency || "",
          (invoice.invoice_date && Date.to_string(invoice.invoice_date)) || "",
          invoice.status,
          invoice.direction
        ]
      end)

    [headers | rows]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
  end

  defp export_invoices(socket, invoice_ids) do
    invoices = Enum.filter(socket.assigns.invoices, &(&1.id in invoice_ids))
    csv_content = generate_csv(invoices)

    {:noreply,
     socket
     |> push_event("download", %{
       content: csv_content,
       filename: "selected_invoices_#{Date.to_string(Date.utc_today())}.csv",
       mime_type: "text/csv"
     })
     |> put_flash(:info, "Exported #{length(invoices)} invoice(s)")
     |> assign(:selected_invoices, MapSet.new())}
  end

  defp delete_invoices(socket, invoice_ids) do
    tenant = get_tenant(socket)

    results =
      Enum.map(invoice_ids, fn id ->
        case Ash.get(Finance.Invoice, id, tenant: tenant) do
          {:ok, invoice} -> Ash.destroy(invoice)
          error -> error
        end
      end)

    success_count = Enum.count(results, &match?({:ok, _}, &1))

    {:ok, remaining_invoices} = Ash.read(Finance.Invoice, load: [:counter_party], tenant: tenant)

    {:noreply,
     socket
     |> put_flash(:info, "Deleted #{success_count} invoice(s)")
     |> assign(:invoices, remaining_invoices)
     |> assign(:selected_invoices, MapSet.new())}
  end

  defp update_status(socket, invoice_ids, new_status) do
    tenant = get_tenant(socket)

    results =
      Enum.map(invoice_ids, fn id ->
        case Ash.get(Finance.Invoice, id, tenant: tenant) do
          {:ok, invoice} -> Ash.update(invoice, %{status: new_status})
          error -> error
        end
      end)

    success_count = Enum.count(results, &match?({:ok, _}, &1))

    {:ok, updated_invoices} = Ash.read(Finance.Invoice, load: [:counter_party], tenant: tenant)

    {:noreply,
     socket
     |> put_flash(:info, "Updated #{success_count} invoice(s)")
     |> assign(:invoices, updated_invoices)
     |> assign(:selected_invoices, MapSet.new())}
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
