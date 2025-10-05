defmodule InvoiceGoblinWeb.Plugs.PlausibleSessionPlug do
  @moduledoc """
  Plug to extract connection information (user agent, IP address, current URL)
  and store it in the session for LiveView access.
  """

  import Plug.Conn
  alias PlausibleSession

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    plausible_session = %PlausibleSession{
      user_agent: get_user_agent(conn),
      client_ip: get_client_ip(conn),
      current_url: get_current_url(conn)
    }

    conn
    |> put_session(:plausible_session, plausible_session)
  end

  # Helper function to get user agent from connection
  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      [] -> "Unknown"
    end
  end

  # Helper function to get client IP address
  defp get_client_ip(conn) do
    # Check for X-Forwarded-For header first (for proxies/load balancers)
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded_for | _] ->
        # X-Forwarded-For can contain multiple IPs, take the first one
        forwarded_for
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote IP
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          ip -> to_string(ip)
        end
    end
  end

  # Helper function to get current URL
  defp get_current_url(conn) do
    scheme = if conn.scheme == :https, do: "https", else: "http"
    host = conn.host
    port = if conn.port in [80, 443], do: "", else: ":#{conn.port}"
    path = conn.request_path
    query = if conn.query_string != "", do: "?#{conn.query_string}", else: ""

    "#{scheme}://#{host}#{port}#{path}#{query}"
  end
end
