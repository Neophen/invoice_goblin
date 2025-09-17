defmodule InvoiceGoblin.Repo do
  use Ecto.Repo,
    otp_app: :invoice_goblin,
    adapter: Ecto.Adapters.Postgres
end
