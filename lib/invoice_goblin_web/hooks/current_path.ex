defmodule InvoiceGoblinWeb.Hooks.CurrentPath do
  @moduledoc false
  import Phoenix.Component
  import InvoiceGoblinWeb.HookUtils

  @doc """
  Sets the path from the connection as :current_path on the socket
  """
  def on_mount(_opts, _params, _session, socket) do
    socket
    |> Phoenix.LiveView.attach_hook(:set_current_path, :handle_params, &set_path/3)
    |> cont()
  end

  defp set_path(_params, url, socket) do
    socket
    |> assign(:current_path, URI.parse(url).path)
    |> cont()
  end
end
