defmodule InvoiceGoblinWeb.InvoiceProcessingDashboardLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout
  alias InvoiceGoblin.Finance
  require Ash.Query

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    tenant = get_tenant(socket)

    # Load recent invoices grouped by status
    processing =
      Finance.Invoice
      |> Ash.Query.filter(status == :processing)
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(50)
      |> Ash.read!(tenant: tenant)

    recent_parsed =
      Finance.Invoice
      |> Ash.Query.filter(status == :parsed)
      |> Ash.Query.sort(updated_at: :desc)
      |> Ash.Query.limit(20)
      |> Ash.Query.load(:counter_party)
      |> Ash.read!(tenant: tenant)

    recent_errors =
      Finance.Invoice
      |> Ash.Query.filter(status == :error)
      |> Ash.Query.sort(updated_at: :desc)
      |> Ash.Query.limit(20)
      |> Ash.read!(tenant: tenant)

    # Get statistics
    stats = get_processing_stats(tenant)

    if connected?(socket) do
      # Subscribe to invoice updates
      :timer.send_interval(5000, self(), :refresh_data)
    end

    {:ok,
     socket
     |> assign(:processing_invoices, processing)
     |> assign(:recent_parsed, recent_parsed)
     |> assign(:recent_errors, recent_errors)
     |> assign(:stats, stats)
     |> assign(:selected_batch, nil)}
  end

  @impl true
  def handle_info(:refresh_data, socket) do
    tenant = get_tenant(socket)

    # Refresh processing invoices
    processing =
      Finance.Invoice
      |> Ash.Query.filter(status == :processing)
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(50)
      |> Ash.read!(tenant: tenant)

    # Only refresh stats if processing count changed
    stats =
      if length(processing) != length(socket.assigns.processing_invoices) do
        get_processing_stats(tenant)
      else
        socket.assigns.stats
      end

    {:noreply,
     socket
     |> assign(:processing_invoices, processing)
     |> assign(:stats, stats)}
  end

  @impl true
  def handle_event("retry_invoice", %{"id" => invoice_id}, socket) do
    tenant = get_tenant(socket)

    case Ash.get(Finance.Invoice, invoice_id, tenant: tenant) do
      {:ok, invoice} ->
        # Reset status to processing to trigger re-processing
        case Ash.update(invoice, %{status: :processing, processing_errors: nil}) do
          {:ok, _updated} ->
            {:noreply,
             socket
             |> put_flash(:info, "Invoice queued for reprocessing")
             |> push_event("refresh", %{})}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to retry invoice")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Invoice not found")}
    end
  end

  @impl true
  def handle_event("filter_batch", %{"batch" => batch_name}, socket) do
    selected_batch = if batch_name == "", do: nil, else: batch_name
    {:noreply, assign(socket, :selected_batch, selected_batch)}
  end

  @impl true
  def handle_event("process_invoice_now", %{"id" => invoice_id}, socket) do
    tenant = get_tenant(socket)

    case Ash.get(Finance.Invoice, invoice_id, tenant: tenant) do
      {:ok, invoice} ->
        try do
          # Trigger the parse_with_ai_trigger action directly
          Ash.update!(invoice, %{}, action: :parse_with_ai_trigger)

          {:noreply,
           socket
           |> put_flash(:info, "Processing invoice: #{invoice.title}")
           |> push_event("refresh", %{})}
        rescue
          e ->
            {:noreply, put_flash(socket, :error, "Failed to process invoice: #{inspect(e)}")}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Invoice not found")}
    end
  end

  @impl true
  def handle_event("process_all_now", _params, socket) do
    # Trigger processing for all pending invoices
    processing_invoices = socket.assigns.processing_invoices

    if processing_invoices == [] do
      {:noreply, put_flash(socket, :info, "No invoices to process")}
    else
      # Use AshOban to trigger the processing immediately
      try do
        Enum.each(processing_invoices, fn invoice ->
          # Trigger the parse_with_ai_trigger action directly
          Ash.update!(invoice, %{}, action: :parse_with_ai_trigger)
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Processing #{length(processing_invoices)} invoice(s)...")
         |> assign(:processing_invoices, [])
         |> push_event("refresh", %{})}
      rescue
        e ->
          {:noreply, put_flash(socket, :error, "Failed to process invoices: #{inspect(e)}")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.admin flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <div class="mb-6 flex items-center justify-between">
          <h1 class="text-3xl font-bold">Invoice Processing Dashboard</h1>
          <.link
            navigate={~p"/invoices/upload"}
            class="bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
          >
            Upload More Invoices
          </.link>
        </div>
        
    <!-- Statistics Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="p-3 bg-yellow-100 rounded-full">
                  <svg
                    class="h-6 w-6 text-yellow-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-500">Processing</p>
                <p class="text-2xl font-semibold text-gray-900">{@stats.processing}</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="p-3 bg-green-100 rounded-full">
                  <svg
                    class="h-6 w-6 text-green-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-500">Parsed Today</p>
                <p class="text-2xl font-semibold text-gray-900">{@stats.parsed_today}</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="p-3 bg-blue-100 rounded-full">
                  <svg
                    class="h-6 w-6 text-blue-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                </div>
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-500">Matched</p>
                <p class="text-2xl font-semibold text-gray-900">{@stats.matched}</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-lg shadow p-6">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <div class="p-3 bg-red-100 rounded-full">
                  <svg
                    class="h-6 w-6 text-red-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
              </div>
              <div class="ml-4">
                <p class="text-sm font-medium text-gray-500">Errors</p>
                <p class="text-2xl font-semibold text-gray-900">{@stats.errors}</p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Currently Processing -->
        <div :if={@processing_invoices != []} class="mb-8">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-semibold flex items-center">
              <svg class="h-5 w-5 text-yellow-500 animate-spin mr-2" fill="none" viewBox="0 0 24 24">
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                >
                </circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                >
                </path>
              </svg>
              Currently Processing ({length(@processing_invoices)})
            </h2>
            <button
              phx-click="process_all_now"
              class="bg-green-600 text-white px-4 py-2 rounded-md hover:bg-green-700 transition-colors flex items-center"
            >
              <svg class="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
              Process All Now
            </button>
          </div>
          <div class="bg-white rounded-lg shadow">
            <div class="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div
                :for={invoice <- @processing_invoices}
                class="flex items-center justify-between p-3 bg-yellow-50 border border-yellow-200 rounded-md"
              >
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900 truncate">{invoice.title}</p>
                  <p class="text-xs text-gray-500">
                    Uploaded {format_relative_time(invoice.inserted_at)}
                  </p>
                </div>
                <div class="flex items-center ml-2">
                  <button
                    phx-click="process_invoice_now"
                    phx-value-id={invoice.id}
                    class="mr-2 text-green-600 hover:text-green-800 text-sm font-medium"
                  >
                    Process
                  </button>
                  <div class="h-8 w-8 bg-yellow-100 rounded-full flex items-center justify-center">
                    <svg class="h-4 w-4 text-yellow-600 animate-spin" fill="none" viewBox="0 0 24 24">
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Recent Errors -->
        <div :if={@recent_errors != []} class="mb-8">
          <h2 class="text-xl font-semibold mb-4">Recent Errors</h2>
          <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Invoice
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Error
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Time
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr :for={invoice <- @recent_errors}>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900">{invoice.title}</div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="text-sm text-red-600">
                      {invoice.processing_errors || "Unknown error"}
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format_relative_time(invoice.updated_at)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm">
                    <button
                      phx-click="retry_invoice"
                      phx-value-id={invoice.id}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      Retry
                    </button>
                    <span class="mx-2">|</span>
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
          </div>
        </div>
        
    <!-- Recently Parsed -->
        <div :if={@recent_parsed != []} class="mb-8">
          <h2 class="text-xl font-semibold mb-4">Recently Parsed</h2>
          <div class="bg-white rounded-lg shadow overflow-hidden">
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
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <tr :for={invoice <- @recent_parsed}>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900">{invoice.title}</div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={invoice.counter_party} class="text-sm text-gray-900">
                      {invoice.counter_party.name}
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div :if={invoice.amount} class="text-sm font-medium text-gray-900">
                      {invoice.currency} {invoice.amount}
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {if invoice.invoice_date, do: Calendar.strftime(invoice.invoice_date, "%B %d, %Y")}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm">
                    <.link
                      navigate={~p"/invoices/#{invoice.id}"}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      Match Transaction
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layout.admin>
    """
  end

  defp get_processing_stats(tenant) do
    today = Date.utc_today()

    # Get counts for each status
    processing_count =
      Finance.Invoice
      |> Ash.Query.filter(status == :processing)
      |> Ash.count!(tenant: tenant)

    error_count =
      Finance.Invoice
      |> Ash.Query.filter(status == :error)
      |> Ash.count!(tenant: tenant)

    matched_count =
      Finance.Invoice
      |> Ash.Query.filter(status == :matched)
      |> Ash.count!(tenant: tenant)

    # Count parsed today - we'll use a simpler approach
    all_parsed =
      Finance.Invoice
      |> Ash.Query.filter(status == :parsed)
      |> Ash.read!(tenant: tenant)

    parsed_today_count =
      Enum.count(all_parsed, fn invoice ->
        case invoice.updated_at do
          %DateTime{} = dt -> Date.compare(DateTime.to_date(dt), today) == :eq
          _ -> false
        end
      end)

    %{
      processing: processing_count,
      parsed_today: parsed_today_count,
      matched: matched_count,
      errors: error_count
    }
  end

  defp format_relative_time(datetime) do
    case DateTime.diff(DateTime.utc_now(), datetime, :second) do
      seconds when seconds < 60 ->
        "#{seconds} seconds ago"

      seconds when seconds < 3600 ->
        minutes = div(seconds, 60)
        "#{minutes} minute#{if minutes == 1, do: "", else: "s"} ago"

      seconds when seconds < 86400 ->
        hours = div(seconds, 3600)
        "#{hours} hour#{if hours == 1, do: "", else: "s"} ago"

      _ ->
        Calendar.strftime(datetime, "%B %d at %I:%M %p")
    end
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