defmodule InvoiceGoblinWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  import InvoiceGoblinWeb.HookUtils

  use InvoiceGoblinWeb, :verified_routes

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {InvoiceGoblinWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    socket
    |> AshAuthentication.Phoenix.LiveSession.assign_new_resources(session)
    |> cont()
  end

  def on_mount(:live_user_optional, _params, session, socket) do
    socket
    |> assign_current_user()
    |> assign_extras(session)
    |> cont()
  end

  def on_mount(:live_user_required, _params, session, socket) do
    if socket.assigns[:current_user] do
      socket
      |> assign_current_user()
      |> assign_extras(session)
      |> cont()
    else
      socket
      |> Phoenix.LiveView.redirect(to: ~p"/sign-in")
      |> assign_extras(session)
      |> halt()
    end
  end

  def on_mount(:live_no_user, _params, session, socket) do
    if socket.assigns[:current_user] do
      socket
      |> Phoenix.LiveView.redirect(to: ~p"/admin/dashboard")
      |> assign_extras(session)
      |> halt()
    else
      socket
      |> assign(:current_user, nil)
      |> assign_extras(session)
      |> cont()
    end
  end

  defp assign_current_user(socket) do
    assign(socket, :current_user, socket.assigns[:current_user])
  end

  defp assign_extras(socket, session) do
    assign_locale(socket, session)
  end

  defp assign_locale(socket, session) do
    # Get locale from session (Cldr.Plug.PutSession stores it as "cldr_locale")
    locale_string = Map.get(session, "cldr_locale", InvoiceGoblinCldr.default_locale().cldr_locale_name)

    # Set the CLDR locale (this will normalize "lt" to "lt-LT" etc.)
    {:ok, cldr_locale} = InvoiceGoblinCldr.put_locale(locale_string)

    # Get just the language part for Gettext (e.g., "lt" from "lt-LT")
    gettext_locale = cldr_locale.language

    # Set the Gettext locale
    InvoiceGoblinGettext.put_locale(gettext_locale)

    assign(socket, :locale, gettext_locale)
  end
end
