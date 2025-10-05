defmodule InvoiceGoblinGettext do
  @moduledoc """
  Client wrapper around gettext.
  """

  alias InvoiceGoblinGettext.Backend
  alias InvoiceGoblinGettext.Languages

  defmacro __using__(_opts) do
    quote do
      use Gettext, backend: InvoiceGoblinGettext.Backend

      import InvoiceGoblinGettext

      # alias InvoiceGoblin.Types.Translated
    end
  end

  @spec put_locale(Gettext.locale()) :: Gettext.locale() | nil
  def put_locale(locale) when is_binary(locale), do: Gettext.put_locale(Backend, locale)
  def put_locale(locale), do: Gettext.put_locale(Backend, to_string(locale))

  @spec get_locale() :: Gettext.locale()
  def get_locale, do: Gettext.get_locale(Backend)

  def dgettext_with_locale(locale, domain, message, bindings \\ []) do
    if locale in InvoiceGoblinCldr.known_locale_names() do
      Gettext.with_locale(InvoiceGoblinGettext.Backend, to_string(locale), fn ->
        Gettext.dgettext(Backend, domain, message, bindings)
      end)
    end
  end

  @spec default_locale() :: String.t()
  def default_locale do
    InvoiceGoblinCldr.default_locale()
  end

  @spec available_locales() :: list(String.t())
  def available_locales do
    InvoiceGoblinCldr.known_locale_names()
  end

  @spec locale_name!() :: String.t()
  def locale_name! do
    locale_name!(InvoiceGoblinCldr.get_locale().language)
  end

  @spec locale_name!(String.t()) :: String.t()
  def locale_name!(locale) do
    locale
    |> Cldr.LocaleDisplay.display_name!(locale: locale, prefer: :menu, backend: InvoiceGoblinCldr)
    |> String.capitalize()
  end

  def locale_options do
    InvoiceGoblinCldr.known_locale_names()
    |> Enum.map(&{&1, locale_name!(&1)})
    |> Enum.sort()
  end

  def language_options(locale) do
    Enum.map(Languages.known_languages(), fn {code, name} ->
      case Cldr.LocaleDisplay.display_name(
             code,
             locale: locale,
             prefer: :menu,
             backend: InvoiceGoblinCldr
           ) do
        {:ok, display_name} -> {code, String.capitalize(display_name)}
        _error -> {code, name}
      end
    end)
  end
end
