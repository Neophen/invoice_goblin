defmodule InvoiceGoblinWeb.PageController do
  use InvoiceGoblinWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
