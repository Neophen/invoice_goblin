defmodule InvoiceGoblin.Accounts.AccountSecrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :strategies, :google, :client_id],
        InvoiceGoblin.Accounts.User,
        _opts,
        _context
      ),
      do: Application.fetch_env(:invoice_goblin, :oauth_client_id)

  def secret_for(
        [:authentication, :strategies, :google, :redirect_uri],
        InvoiceGoblin.Accounts.User,
        _opts,
        _context
      ),
      do: Application.fetch_env(:invoice_goblin, :oauth_redirect_uri)

  def secret_for(
        [:authentication, :strategies, :google, :client_secret],
        InvoiceGoblin.Accounts.User,
        _opts,
        _context
      ),
      do: Application.fetch_env(:invoice_goblin, :oauth_client_secret)
end
