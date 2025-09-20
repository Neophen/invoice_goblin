defmodule InvoiceGoblinGettext.Locales do
  @moduledoc false
  @primary_locale String.to_atom(InvoiceGoblinCldr.default_locale().language)
  @allowed_locales InvoiceGoblinCldr.known_locale_names()

  def primary, do: @primary_locale
  def allowed, do: @allowed_locales
  def primary?(locale), do: locale == @primary_locale

  defmacro __using__(_opts) do
    quote do
      @primary_locale unquote(@primary_locale)
      @allowed_locales unquote(@allowed_locales)
    end
  end
end
