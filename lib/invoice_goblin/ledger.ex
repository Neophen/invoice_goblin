defmodule InvoiceGoblin.Ledger do
  use Ash.Domain,
    otp_app: :invoice_goblin

  resources do
    resource InvoiceGoblin.Ledger.Account
    resource InvoiceGoblin.Ledger.Balance
    resource InvoiceGoblin.Ledger.Transfer
  end
end
