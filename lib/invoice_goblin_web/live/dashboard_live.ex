defmodule InvoiceGoblinWeb.Admin.DashboardLive do
  @moduledoc false
  use InvoiceGoblinWeb, :live_view

  @impl LiveView
  def render(assigns) do
    ~H"""
    <Layout.admin flash={@flash} current_user={@current_user}>
      <Layout.header title={@page_title} />
    </Layout.admin>
    """
  end

  @impl LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, dgettext("admin", "Dashboard"))
    |> ok()
  end
end
