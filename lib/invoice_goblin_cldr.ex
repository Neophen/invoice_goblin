defmodule InvoiceGoblinCldr do
  @moduledoc """
  Define a backend module that will host our
  Cldr configuration and public API.

  Most function calls in Cldr will be calls
  to functions on this module.

  InvoiceGoblinCldr.default_locale/0
  InvoiceGoblinCldr.put_locale/1
  InvoiceGoblinCldr.get_locale/0
  InvoiceGoblinCldr.known_locale_names/0
  InvoiceGoblinCldr.Locale.new/1
  InvoiceGoblinCldr.validate_locale/1
  """
  use Cldr,
    default_locale: Application.compile_env(:invoice_goblin, InvoiceGoblinCldr)[:primary_locale],
    locales: Application.compile_env(:invoice_goblin, InvoiceGoblinCldr)[:allowed_locales],
    gettext: InvoiceGoblinGettext.Backend,
    otp_app: :invoice_goblin,
    generate_docs: true,
    force_locale_download: Mix.env() == :prod,
    providers: [
      Cldr.LocaleDisplay,
      Cldr.Message,
      Cldr.Number
    ]
end
