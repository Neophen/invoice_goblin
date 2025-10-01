defmodule InvoiceGoblinWeb.DashboardLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout

  alias InvoiceGoblinWeb.Components.StatementFormComponent

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.admin flash={@flash} current_user={@current_user}>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <button type="button" class="block text-left" phx-click={show_modal("upload-statement-modal")}>
          <.action_card
            icon="hero-cog-6-tooth"
            title="Upload Bank Statement"
            description="Upload a bank statement to see transactions"
          />
        </button>
        <.link navigate={~p"/statements"}>
          <.action_card
            icon="hero-document-text"
            title="Bank Statements"
            description="View and manage uploaded bank statements"
          />
        </.link>
        <.link navigate={~p"/transactions"}>
          <.action_card
            icon="hero-banknotes"
            title="Manage Transactions"
            description="View, filter, and link transactions to invoices"
          />
        </.link>
        <.link navigate={~p"/invoices/upload"}>
          <.action_card
            icon="hero-document-arrow-up"
            title="Upload Invoice"
            description="Upload and parse invoice documents"
          />
        </.link>
        <.link navigate={~p"/invoices"}>
          <.action_card
            icon="hero-document-duplicate"
            title="View Invoices"
            description="View and manage all uploaded invoices"
          />
        </.link>
        <.link navigate={~p"/invoices/processing"}>
          <.action_card
            icon="hero-cog"
            title="Processing Dashboard"
            description="Monitor bulk invoice processing status"
          />
        </.link>
      </div>

      <.empty_state />

      <Modal.root id="upload-statement-modal" on_cancel={hide_modal("upload-statement-modal")}>
        <StatementFormComponent.show id="statement-form" current_user={@current_user} />
      </Modal.root>
    </Layout.admin>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  defp action_card(assigns) do
    ~H"""
    <div class="relative block w-full bg-white border border-gray-300 rounded-lg p-6 hover:border-gray-400 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <Icon.icon name={@icon} class="h-6 w-6 text-gray-400" />
        </div>
        <div class="ml-4">
          <h4 class="text-sm font-medium text-gray-900">{@title}</h4>
          <p class="text-sm text-gray-500">{@description}</p>
        </div>
      </div>
    </div>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-4 py-5 sm:p-6 text-center">
        <h3 class="mt-2 text-sm font-medium text-gray-900">Nothing here yet</h3>
        <p class="mt-1 text-sm text-gray-500">
          The goblin is hungry. Feed him with a bank statement to see transactions.
        </p>
        <img src={~p"/images/goblin-waiting.png"} class="mx-auto h-48 w-auto mt-4" />
      </div>
    </div>
    """
  end
end
