defmodule InvoiceGoblinWeb.SocketHelpers do
  @moduledoc """
  A collection of functions to help express pipes when processing live view responses.
  """

  alias Phoenix.LiveView.Socket

  @spec ok(Socket.t()) :: {:ok, Socket.t()}
  def ok(%Socket{} = socket), do: {:ok, socket}

  @spec noreply(Socket.t()) :: {:noreply, Socket.t()}
  def noreply(%Socket{} = socket), do: {:noreply, socket}

  @spec cont(Socket.t()) :: {:cont, Socket.t()}
  def cont(%Socket{} = socket), do: {:cont, socket}

  @spec halt(Socket.t()) :: {:halt, Socket.t()}
  def halt(%Socket{} = socket), do: {:halt, socket}

  @spec user(Socket.t()) :: map() | nil
  def user(%Socket{assigns: %{current_user: current_user}}), do: current_user

  @spec notify_parent(Socket.t(), any()) :: atom() | nil
  def notify_parent(%Socket{} = socket, message) do
    send(self(), message)
    socket
  end
end
