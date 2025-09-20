defmodule InvoiceGoblinWeb.HookUtils do
  @moduledoc false

  def cont(socket) do
    {:cont, socket}
  end

  def halt(socket) do
    {:halt, socket}
  end
end
