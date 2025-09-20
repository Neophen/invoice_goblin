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

  @spec assign_timezone(Socket.t()) :: Socket.t()
  def assign_timezone(%Socket{} = socket) do
    # connect_params is a map of the params passed to the socket on connect from app.js
    timezone = Phoenix.LiveView.get_connect_params(socket)["timezone"]

    Phoenix.Component.assign(socket, :timezone, timezone)
  end

  @spec actor(Socket.t()) :: Keyword.t()
  def actor(%Socket{assigns: %{current_user: actor}}), do: actor
  def actor(%{current_user: actor}), do: actor

  @spec with_actor(Socket.t(), Keyword.t()) :: Keyword.t()
  def with_actor(%Socket{} = socket, opts \\ []) do
    Keyword.put(opts, :actor, actor(socket))
  end

  @spec locale(Socket.t()) :: atom() | nil
  def locale(%Socket{assigns: %{locale: locale}}), do: locale

  @spec notify_parent(Socket.t(), any()) :: atom() | nil
  def notify_parent(%Socket{} = socket, message) do
    send(self(), message)
    socket
  end

  @spec assign_form(Socket.t(), map()) :: Socket.t()
  def assign_form(%Socket{} = socket, form, key \\ :form) do
    Phoenix.Component.assign(socket, key, Phoenix.Component.to_form(form))
  end

  @spec validate_form(Socket.t(), map()) :: Socket.t()
  @spec validate_form(Socket.t(), map(), atom()) :: Socket.t()
  def validate_form(%Socket{} = socket, form_data, key \\ :form) do
    Phoenix.Component.update(socket, key, &AshPhoenix.Form.validate(&1, form_data))
  end

  @spec submit_form(Socket.t(), map()) :: {:ok, map()} | {:error, map()}
  def submit_form(%Socket{} = socket, form_data, key \\ :form) do
    AshPhoenix.Form.submit(socket.assigns[key], with_actor(socket, params: form_data))
  end

  @spec subscribe_to(Socket.t(), topic :: String.t()) :: Socket.t()
  def subscribe_to(%Socket{} = socket, topic) do
    if(Phoenix.LiveView.connected?(socket)) do
      InvoiceGoblinWeb.Endpoint.subscribe(topic)
    end

    socket
  end

  @spec unsubscribe_from(Socket.t(), topic :: String.t()) :: Socket.t()
  def unsubscribe_from(%Socket{} = socket, topic) do
    InvoiceGoblinWeb.Endpoint.unsubscribe(topic)

    socket
  end

  @spec stream_change(Socket.t(), String.t(), atom(), any()) :: Socket.t()
  def stream_change(socket, event, key, data) do
    case event do
      "destroy" -> Phoenix.LiveView.stream_delete(socket, key, data)
      "create" -> Phoenix.LiveView.stream_insert(socket, key, data)
      "update" -> Phoenix.LiveView.stream_insert(socket, key, data)
    end
  end

  # Form helpers

  @spec maybe_on_submit(Socket.t(), any()) :: Socket.t()
  def maybe_on_submit(%Socket{} = socket, item) do
    maybe_action(socket, socket.assigns.on_submit, item)
  end

  @spec maybe_on_cancel(Socket.t()) :: Socket.t()
  def maybe_on_cancel(%Socket{} = socket) do
    maybe_action(socket, socket.assigns.on_cancel, nil)
  end

  defp maybe_action(socket, nil, _args), do: socket

  defp maybe_action(socket, action, args) when is_function(action) do
    if(is_nil(args)) do
      action.(socket)
    else
      action.(socket, args)
    end
  end

  def put_component_flash(socket, type, message) do
    send(self(), {:put_flash, type, message})
    socket
  end
end
