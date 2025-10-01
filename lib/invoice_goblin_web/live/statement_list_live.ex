defmodule InvoiceGoblinWeb.StatementListLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  alias InvoiceGoblin.Finance.Statement
  alias InvoiceGoblinWeb.Components.StatementFormComponent

  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:page, 1)
    |> assign(:page_size, 25)
    |> assign(:loading, false)
    |> assign(:upload_modal_open, false)
    |> load_statements()
    |> ok()
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()

    socket
    |> assign(:page, page)
    |> load_statements()
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.admin flash={@flash} current_user={@current_user}>
      <div class="space-y-6">
        <div class="flex items-center space-x-4">
          <.link
            navigate={~p"/dashboard"}
            class="inline-flex items-center text-gray-500 hover:text-gray-700"
          >
            <Icon.icon name="hero-arrow-left" class="h-5 w-5 mr-1" /> Back to Dashboard
          </.link>
        </div>
        
    <!-- Header -->
        <div class="sm:flex sm:items-center sm:justify-between">
          <div>
            <h1 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
              Bank Statements
            </h1>
            <p class="mt-1 text-sm text-gray-500">
              Manage and view your uploaded bank statements
            </p>
          </div>
          <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none space-x-3">
            <Action.button type="button" phx-click={show_modal("upload-statement-modal")}>
              <Icon.icon name="hero-plus" class="h-4 w-4 mr-1" /> Upload Statement
            </Action.button>
          </div>
        </div>
        
    <!-- Statements List -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 sm:p-6">
            <div :if={@loading} class="text-center py-8">
              <Icon.icon name="hero-arrow-path" class="h-8 w-8 animate-spin mx-auto text-gray-400" />
              <p class="text-gray-500 mt-2">Loading statements...</p>
            </div>

            <div :if={!@loading && Enum.empty?(@statements)} class="text-center py-8">
              <Icon.icon name="hero-document-text" class="h-12 w-12 mx-auto text-gray-400" />
              <h3 class="mt-2 text-sm font-medium text-gray-900">No statements</h3>
              <p class="mt-1 text-sm text-gray-500">
                Get started by uploading your first bank statement.
              </p>
              <div class="mt-6">
                <Action.button type="button" phx-click={show_modal("upload-statement-modal")}>
                  <Icon.icon name="hero-plus" class="h-4 w-4 mr-1" /> Upload Statement
                </Action.button>
              </div>
            </div>

            <div :if={!@loading && !Enum.empty?(@statements)} class="space-y-4">
              <div
                :for={statement <- @statements}
                class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
              >
                <div class="flex items-center justify-between">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center space-x-3">
                      <div class="flex-shrink-0">
                        <Icon.icon name="hero-document-text" class="h-5 w-5 text-gray-400" />
                      </div>
                      <div class="flex-1 min-w-0">
                        <h3 class="text-sm font-medium text-gray-900 truncate">
                          {statement.title}
                        </h3>
                        <div class="mt-1 flex items-center space-x-4 text-xs text-gray-500">
                          <span :if={statement.account_iban}>
                            IBAN: {statement.account_iban}
                          </span>
                          <span :if={statement.statement_date}>
                            {statement.statement_date}
                          </span>
                          <span :if={
                            statement.statement_period_start && statement.statement_period_end
                          }>
                            {statement.statement_period_start} - {statement.statement_period_end}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="flex items-center space-x-4">
                    <div class="text-right">
                      <div class="text-sm font-medium text-gray-900">
                        {length(statement.transactions)} transactions
                      </div>
                      <div class="text-xs text-gray-500">
                        {format_file_size(statement.file_size)}
                      </div>
                    </div>
                    <div class="flex space-x-2">
                      <.link
                        navigate={~p"/statements/#{statement.id}"}
                        class="inline-flex items-center px-2.5 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                      >
                        View Details
                      </.link>
                      <.link
                        href={Statement.download_url(statement)}
                        target="_blank"
                        class="inline-flex items-center px-2.5 py-1.5 border border-gray-300 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                      >
                        <Icon.icon name="hero-arrow-down-tray" class="h-3 w-3 mr-1" /> Download
                      </.link>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Pagination -->
            <div :if={!@loading && !Enum.empty?(@statements)} class="mt-6">
              <.pagination_controls
                page={@page}
                page_size={@page_size}
                total_count={length(@statements)}
              />
            </div>
          </div>
        </div>
      </div>
      
    <!-- Upload Modal -->
      <Modal.root
        :if={@upload_modal_open}
        id="upload-statement-modal"
        on_cancel={hide_modal("upload-statement-modal")}
      >
        <div class="p-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Upload Bank Statement</h3>
          <StatementFormComponent.show id="statement-form" current_user={@current_user} />
        </div>
      </Modal.root>
    </Layout.admin>
    """
  end

  defp load_statements(%{assigns: %{page: page, page_size: page_size}} = socket) do
    tenant = get_tenant(socket)

    query =
      Statement
      |> Ash.Query.load([:transactions])
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(page_size)
      |> Ash.Query.offset((page - 1) * page_size)

    case Ash.read(query, tenant: tenant) do
      {:ok, statements} ->
        socket
        |> assign(:statements, statements)
        |> assign(:loading, false)

      {:error, _error} ->
        socket
        |> assign(:statements, [])
        |> assign(:loading, false)
        |> put_flash(:error, "Failed to load statements")
    end
  end

  defp format_file_size(nil), do: "Unknown size"

  defp format_file_size(size) when is_integer(size) do
    cond do
      size >= 1_000_000 -> "#{Float.round(size / 1_000_000, 1)} MB"
      size >= 1_000 -> "#{Float.round(size / 1_000, 1)} KB"
      true -> "#{size} B"
    end
  end

  attr :page, :integer, required: true
  attr :page_size, :integer, required: true
  attr :total_count, :integer, required: true

  defp pagination_controls(assigns) do
    ~H"""
    <div class="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6">
      <div class="flex flex-1 justify-between sm:hidden">
        <.link
          :if={@page > 1}
          patch={~p"/statements?page=#{@page - 1}"}
          class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Previous
        </.link>
        <.link
          :if={@total_count == @page_size}
          patch={~p"/statements?page=#{@page + 1}"}
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
              patch={~p"/statements?page=#{@page - 1}"}
              class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
            >
              <span class="sr-only">Previous</span>
              <Icon.icon name="hero-chevron-left" class="h-5 w-5" aria-hidden="true" />
            </.link>
            <span class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0">
              {@page}
            </span>
            <.link
              :if={@total_count == @page_size}
              patch={~p"/statements?page=#{@page + 1}"}
              class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
            >
              <span class="sr-only">Next</span>
              <Icon.icon name="hero-chevron-right" class="h-5 w-5" aria-hidden="true" />
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
