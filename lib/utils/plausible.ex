defmodule PlausibleSession do
  @moduledoc """
  Struct to hold connection information for Plausible analytics events.
  """
  defstruct [:user_agent, :client_ip, :current_url]

  @type t :: %__MODULE__{
          user_agent: String.t(),
          client_ip: String.t(),
          current_url: String.t()
        }
end

defmodule Plausible do
  @moduledoc """
  `Plausible` is a library to push analytics events to [Plausible Analytics](https://plausible.io).
  This library uses the Req HTTP client for making requests to the Plausible Events API.

  ## Configuration

  Add the following to your `config/config.exs`:

  ```elixir
  config :invoice_goblin, Plausible,
    domain: "your-domain.com",
    endpoint: "https://plausible.io"
  ```

  ## Usage

  ```elixir
  # Track a pageview using PlausibleSession struct
  Plausible.track_pageview(plausible_session)

  # Track a custom event using PlausibleSession struct
  Plausible.track_event("button_click", plausible_session,
    props: %{"button_name" => "signup"})

  # Track with revenue
  Plausible.track_event("purchase", plausible_session,
    revenue: %{currency: "USD", amount: "29.99"})
  ```

  ## API Reference

  The Plausible Events API documentation can be found at:
  https://plausible.io/docs/events-api
  """

  @doc """
  Track a pageview event.

  ## Parameters

  - `plausible_session` - A PlausibleSession struct containing connection info (required)
  - `opts` - Additional options (optional)

  ## Options

  - `:referrer` - The referrer URL
  - `:props` - Custom properties as a map
  - `:revenue` - Revenue data as `%{currency: "USD", amount: "29.99"}`

  ## Examples

      iex> Plausible.track_pageview(plausible_session)
      :ok

      iex> Plausible.track_pageview(plausible_session,
      ...>   referrer: "https://google.com",
      ...>   props: %{"user_type" => "premium"})
      :ok
  """
  @spec track_pageview(PlausibleSession.t(), keyword()) :: :ok | {:error, any()}
  def track_pageview(plausible_session, opts \\ []) do
    track_event("pageview", plausible_session, opts)
  end

  @doc """
  Track a custom event.

  ## Parameters

  - `event_name` - The name of the event (required)
  - `plausible_session` - A PlausibleSession struct containing connection info (required)
  - `opts` - Additional options (optional)

  ## Options

  - `:referrer` - The referrer URL
  - `:props` - Custom properties as a map (max 30 key-value pairs)
  - `:revenue` - Revenue data as `%{currency: "USD", amount: "29.99"}`
  - `:interactive` - Whether the event is interactive (default: true)

  ## Examples

      iex> Plausible.track_event("button_click", plausible_session)
      :ok

      iex> Plausible.track_event("purchase", plausible_session,
      ...>   props: %{"product_id" => "123", "category" => "electronics"},
      ...>   revenue: %{currency: "USD", amount: "99.99"})
      :ok
  """
  @spec track_event(String.t(), PlausibleSession.t(), keyword()) ::
          {:ok, atom()} | {:error, any()}
  def track_event(event_name, plausible_session, opts \\ []) do
    config = Application.get_env(:invoice_goblin, Plausible, [])

    domain =
      Keyword.get(config, :domain) ||
        raise "Plausible domain not configured. Add `config :invoice_goblin, Plausible, domain: \"your-domain.com\"` to your config"

    endpoint =
      Keyword.get(config, :endpoint) ||
        raise "Plausible endpoint not configured. Add `config :invoice_goblin, Plausible, endpoint: \"https://plausible.io\"` to your config"

    # Build the request body
    body = build_event_body(event_name, plausible_session.current_url, domain, opts)

    # Build headers
    headers = [
      {"User-Agent", plausible_session.user_agent},
      {"X-Forwarded-For", plausible_session.client_ip},
      {"Content-Type", "application/json"}
    ]

    # Add debug header if requested
    headers =
      if opts[:debug] do
        [{"X-Debug-Request", "true"} | headers]
      else
        headers
      end

    # Make the request using Req
    case Req.post("#{endpoint}/api/event",
           json: body,
           headers: headers,
           retry: false
         ) do
      {:ok, %Req.Response{status: 200, body: debug_info}} ->
        if opts[:debug] do
          {:ok, debug_info}
        else
          {:ok, :success}
        end

      {:ok, %Req.Response{status: 202}} ->
        {:ok, :success}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Track a pageview event and raise on error.

  See `track_pageview/2` for parameters and options.
  """
  @spec track_pageview!(PlausibleSession.t(), keyword()) :: any()
  def track_pageview!(plausible_session, opts \\ []) do
    case track_pageview(plausible_session, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Plausible tracking failed: #{inspect(reason)}"
    end
  end

  @doc """
  Track a custom event and raise on error.

  See `track_event/3` for parameters and options.
  """
  @spec track_event!(String.t(), PlausibleSession.t(), keyword()) :: any()
  def track_event!(event_name, plausible_session, opts \\ []) do
    case track_event(event_name, plausible_session, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Plausible tracking failed: #{inspect(reason)}"
    end
  end

  # Private function to build the event body according to Plausible API spec
  defp build_event_body(event_name, url, domain, opts) do
    body = %{
      name: event_name,
      url: url,
      domain: domain
    }

    # Add optional fields
    body =
      if referrer = opts[:referrer] do
        Map.put(body, :referrer, referrer)
      else
        body
      end

    body =
      if props = opts[:props] do
        # Limit to 30 properties as per API spec
        limited_props = props |> Enum.take(30) |> Enum.into(%{})
        Map.put(body, :props, limited_props)
      else
        body
      end

    body =
      if revenue = opts[:revenue] do
        Map.put(body, :revenue, revenue)
      else
        body
      end

    body =
      if interactive = opts[:interactive] do
        Map.put(body, :interactive, interactive)
      else
        body
      end

    body
  end
end
