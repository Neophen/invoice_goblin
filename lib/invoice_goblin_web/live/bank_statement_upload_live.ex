defmodule InvoiceGoblinWeb.BankStatementUploadLive do
  use InvoiceGoblinWeb, :live_view
  alias InvoiceGoblinWeb.Components.StatementFormComponent
  alias UI.Components.Layout

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layout.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-6">Upload Bank Statement</h1>

        <div class="bg-white rounded-lg shadow-md p-6">
          <StatementFormComponent.show id="statement-form" current_user={@current_user} />
        </div>
      </div>
    </Layout.app>
    """
  end
end
