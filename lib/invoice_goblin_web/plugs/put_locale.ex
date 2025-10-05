defmodule InvoiceGoblinWeb.Plug.PutLocale do
  @moduledoc false
  use Plug.Builder

  plug(Cldr.Plug.PutLocale,
    apps: [cldr: InvoiceGoblinCldr, gettext: InvoiceGoblinGettext.Backend],
    from: [:route, {__MODULE__, :locale_from_user}, :accept_language]
  )

  plug(Cldr.Plug.PutSession, as: :string)

  @spec locale_from_user(Plug.Conn.t(), keyword) :: {:ok, Cldr.LanguageTag.t()} | nil
  def locale_from_user(conn, _opts) do
    case conn.assigns do
      %{current_user: %{locale: locale}} -> Cldr.Locale.new(locale, InvoiceGoblinCldr)
      _assigns -> nil
    end
  end
end
