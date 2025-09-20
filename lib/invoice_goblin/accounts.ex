defmodule InvoiceGoblin.Accounts do
  use Ash.Domain, otp_app: :invoice_goblin, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource InvoiceGoblin.Accounts.Token
    resource InvoiceGoblin.Accounts.User
    resource InvoiceGoblin.Accounts.Waitlist
  end
end
