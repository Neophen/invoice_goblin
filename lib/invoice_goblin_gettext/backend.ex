defmodule InvoiceGoblinGettext.Backend do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.
  """
  use Gettext.Backend,
    otp_app: :invoice_goblin,
    allowed_locales:
      Application.compile_env(:invoice_goblin, InvoiceGoblinCldr)[:allowed_locales],
    split_module_by: [:locale, :domain],
    interpolation: InvoiceGoblinGettext.Interpolation
end
