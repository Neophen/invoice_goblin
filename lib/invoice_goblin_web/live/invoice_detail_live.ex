defmodule InvoiceGoblinWeb.InvoiceDetailLive do
  use InvoiceGoblinWeb, :live_view
  alias InvoiceGoblin.Finance
  alias UI.Components.Layout
  require Ash.Query

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tenant = get_tenant(socket)

    case Ash.get(Finance.Invoice, id, load: [:counter_party, :transaction], tenant: tenant) do
      {:ok, invoice} ->
        {:ok,
         socket
         |> assign(:invoice, invoice)
         |> assign(:available_transactions, [])}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Invoice not found")
         |> redirect(to: ~p"/invoices")}
    end
  end

  @impl true
  def handle_event("match_transaction", %{"transaction_id" => transaction_id}, socket) do
    invoice = socket.assigns.invoice

    case Ash.update(invoice, %{transaction_id: transaction_id}, action: :match_transaction) do
      {:ok, updated_invoice} ->
        {:noreply,
         socket
         |> assign(:invoice, Ash.load!(updated_invoice, [:counter_party, :transaction]))
         |> put_flash(:info, "Invoice matched to transaction")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to match transaction: #{inspect(error)}")}
    end
  end

  @impl true
  def handle_event("search_transactions", %{"amount" => amount_str}, socket) do
    tenant = get_tenant(socket)

    # Parse amount and search for similar transactions
    case Decimal.parse(amount_str) do
      {amount, _} ->
        # Search for transactions with similar amounts
        lower_bound = Decimal.mult(amount, Decimal.new("0.95"))
        upper_bound = Decimal.mult(amount, Decimal.new("1.05"))

        query = Finance.Transaction |> Ash.Query.limit(1000)

        {:ok, all} = Ash.read(query, tenant: tenant)

        transactions =
          Enum.filter(all, fn t ->
            amt =
              cond do
                is_map(t.amount) and Map.has_key?(t.amount, :amount) and
                    is_struct(t.amount.amount, Decimal) ->
                  t.amount.amount

                is_struct(t.amount, Decimal) ->
                  t.amount

                is_map(t.amount) and Map.has_key?(t.amount, "amount") ->
                  t.amount["amount"]

                true ->
                  nil
              end

            if amt do
              Decimal.compare(amt, lower_bound) != :lt and
                Decimal.compare(amt, upper_bound) != :gt
            else
              false
            end
          end)

        {:noreply, assign(socket, :available_transactions, transactions)}

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <div class="mb-6 flex items-center justify-between">
          <h1 class="text-3xl font-bold">Invoice Details</h1>
          <.link navigate={~p"/invoices"} class="text-blue-600 hover:text-blue-800">
            ← Back to Invoices
          </.link>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2">
            <div class="bg-white rounded-lg shadow-md p-6">
              <h2 class="text-xl font-semibold mb-4">Invoice Information</h2>

              <div class="grid grid-cols-2 gap-4">
                <div>
                  <p class="text-sm text-gray-500">Title</p>
                  <p class="font-medium">{@invoice.title}</p>
                </div>

                <div>
                  <p class="text-sm text-gray-500">Status</p>
                  <span class={[
                    "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                    @invoice.status == :processing && "bg-yellow-100 text-yellow-800",
                    @invoice.status == :parsed && "bg-green-100 text-green-800",
                    @invoice.status == :matched && "bg-blue-100 text-blue-800",
                    @invoice.status == :error && "bg-red-100 text-red-800"
                  ]}>
                    {@invoice.status}
                  </span>
                </div>

                <div>
                  <p class="text-sm text-gray-500">Direction</p>
                  <p class="font-medium">{@invoice.direction}</p>
                </div>

                <div>
                  <p class="text-sm text-gray-500">Amount</p>
                  <p class="font-medium text-lg">
                    {if @invoice.amount,
                      do: "#{@invoice.currency} #{@invoice.amount}",
                      else: "Not parsed"}
                  </p>
                </div>

                <div>
                  <p class="text-sm text-gray-500">Invoice Date</p>
                  <p class="font-medium">
                    {if @invoice.invoice_date,
                      do: Calendar.strftime(@invoice.invoice_date, "%B %d, %Y"),
                      else: "Not parsed"}
                  </p>
                </div>

                <div>
                  <p class="text-sm text-gray-500">Due Date</p>
                  <p class="font-medium">
                    {if @invoice.due_date,
                      do: Calendar.strftime(@invoice.due_date, "%B %d, %Y"),
                      else: "Not parsed"}
                  </p>
                </div>
              </div>

              <div
                :if={@invoice.processing_errors}
                class="mt-4 p-4 bg-red-50 border border-red-200 rounded-md"
              >
                <p class="text-sm text-red-800">
                  <strong>Processing Error:</strong> {@invoice.processing_errors}
                </p>
              </div>

              <div :if={@invoice.counter_party} class="mt-6">
                <h3 class="text-lg font-semibold mb-2">Counterparty</h3>
                <div class="bg-gray-50 rounded-md p-4">
                  <p class="font-medium">{@invoice.counter_party.name}</p>
                  <p :if={@invoice.counter_party.email} class="text-sm text-gray-600">
                    {@invoice.counter_party.email}
                  </p>
                  <p :if={@invoice.counter_party.tax_number} class="text-sm text-gray-600">
                    Tax: {@invoice.counter_party.tax_number}
                  </p>
                </div>
              </div>

              <div :if={@invoice.parsed_data && map_size(@invoice.parsed_data) > 0} class="mt-6">
                <h3 class="text-lg font-semibold mb-2">Parsed Data</h3>
                <div class="bg-gray-50 rounded-md p-4">
                  <pre class="text-xs overflow-x-auto">{Jason.encode!(@invoice.parsed_data, pretty: true)}</pre>
                </div>
              </div>
            </div>
          </div>

          <div>
            <div class="bg-white rounded-lg shadow-md p-6">
              <h2 class="text-xl font-semibold mb-4">Document</h2>

              <div class="aspect-[3/4] bg-gray-100 rounded-md flex items-center justify-center mb-4">
                <div :if={String.ends_with?(@invoice.file_type || "", "pdf")} class="text-center">
                  <svg class="mx-auto h-16 w-16 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fill-rule="evenodd"
                      d="M4 4a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2H4zm3 5a1 1 0 011-1h4a1 1 0 110 2H8a1 1 0 01-1-1zm0 3a1 1 0 011-1h4a1 1 0 110 2H8a1 1 0 01-1-1z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <p class="mt-2 text-sm text-gray-500">PDF Document</p>
                </div>

                <img
                  :if={String.contains?(@invoice.file_type || "", "image")}
                  src={@invoice.file_url}
                  alt="Invoice"
                  class="w-full h-full object-contain rounded-md"
                />
              </div>

              <a
                href={get_download_url(@invoice)}
                target="_blank"
                class="block w-full bg-blue-600 text-white text-center py-2 px-4 rounded-md hover:bg-blue-700 transition-colors"
              >
                Download Original
              </a>
            </div>

            <div
              :if={@invoice.status == :parsed && !@invoice.transaction_id}
              class="bg-white rounded-lg shadow-md p-6 mt-6"
            >
              <h2 class="text-xl font-semibold mb-4">Match Transaction</h2>

              <form phx-submit="search_transactions" class="mb-4">
                <input
                  type="text"
                  name="amount"
                  value={@invoice.amount}
                  placeholder="Search by amount"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button
                  type="submit"
                  class="mt-2 w-full bg-gray-600 text-white py-2 px-4 rounded-md hover:bg-gray-700"
                >
                  Search Transactions
                </button>
              </form>

              <div :if={@available_transactions != []} class="space-y-2">
                <div
                  :for={transaction <- @available_transactions}
                  class="p-3 border border-gray-200 rounded-md hover:bg-gray-50 cursor-pointer"
                  phx-click="match_transaction"
                  phx-value-transaction_id={transaction.id}
                >
                  <p class="text-sm font-medium">{transaction.counterparty_name || "Unknown"}</p>
                  <p class="text-xs text-gray-500">
                    {Calendar.strftime(transaction.booking_date, "%B %d, %Y")} • {transaction.direction} • {transaction.amount}
                  </p>
                </div>
              </div>
            </div>

            <div :if={@invoice.transaction} class="bg-white rounded-lg shadow-md p-6 mt-6">
              <h2 class="text-xl font-semibold mb-4">Matched Transaction</h2>
              <div class="p-3 bg-green-50 border border-green-200 rounded-md">
                <p class="text-sm font-medium">
                  {@invoice.transaction.counterparty_name || "Unknown"}
                </p>
                <p class="text-xs text-gray-600">
                  {Calendar.strftime(@invoice.transaction.booking_date, "%B %d, %Y")} • {@invoice.transaction.direction} • {@invoice.transaction.amount}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout.app>
    """
  end

  defp get_download_url(invoice) do
    if invoice.file_url do
      slug = String.downcase(invoice.title) |> String.replace(" ", "_")

      S3Uploader.presign_get_url(invoice.file_url,
        as_attachment?: true,
        filename: "#{slug}.#{get_file_extension(invoice.file_type)}",
        content_type: invoice.file_type,
        expires_in: 300
      )
    else
      "#"
    end
  end

  defp get_file_extension(file_type) do
    case file_type do
      "application/pdf" -> "pdf"
      "image/png" -> "png"
      "image/jpeg" -> "jpg"
      "image/jpg" -> "jpg"
      _ -> "bin"
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
