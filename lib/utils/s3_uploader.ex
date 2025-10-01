defmodule S3Uploader do
  @moduledoc """
  Dependency-free S3 Form Upload using HTTP POST SigV4 (compatible with DigitalOcean Spaces).

  - Adds optional `Content-Disposition` at **upload time** (object metadata) via `as_attachment?`.
  - Provides `download_url/2` to **override** disposition at **read time** (query params).

  Docs:
  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
  https://docs.digitalocean.com/products/spaces/reference/s3-api/
  """

  @otp_app :invoice_goblin

  # ————————————————————————————————————————————————————————————————————————
  # Public API
  # ————————————————————————————————————————————————————————————————————————

  @doc """
  Build form fields for a browser POST upload (LiveView external upload).

  Required opts:
    * `:key` - object key to store at
    * `:max_file_size` - max size in bytes
    * `:content_type` - MIME type of the file
    * `:expires_in` - milliseconds the policy is valid

  Optional opts:
    * `:content_disposition` - e.g. `attachment; filename="foo.xml"`
  """
  def sign_form_upload(opts) do
    key = Keyword.fetch!(opts, :key)
    max_file_size = Keyword.fetch!(opts, :max_file_size)
    content_type = Keyword.fetch!(opts, :content_type)
    expires_in = Keyword.fetch!(opts, :expires_in)

    expires_at = DateTime.add(DateTime.utc_now(), expires_in, :millisecond)
    amz_date = amz_date(expires_at)
    cred = credential(config(), expires_at)

    conditions = [
      %{"bucket" => bucket()},
      ["eq", "$key", key],
      %{"acl" => "public-read"},
      ["eq", "$Content-Type", content_type],
      ["content-length-range", 0, max_file_size],
      %{"x-amz-server-side-encryption" => "AES256"},
      %{"x-amz-credential" => cred},
      %{"x-amz-algorithm" => "AWS4-HMAC-SHA256"},
      %{"x-amz-date" => amz_date}
    ]

    encoded_policy =
      %{"expiration" => DateTime.to_iso8601(expires_at), "conditions" => conditions}
      |> Jason.encode!()
      |> Base.encode64()

    {:ok,
     %{
       "key" => key,
       "acl" => "public-read",
       "content-type" => content_type,
       "x-amz-server-side-encryption" => "AES256",
       "x-amz-credential" => cred,
       "x-amz-algorithm" => "AWS4-HMAC-SHA256",
       "x-amz-date" => amz_date,
       "policy" => encoded_policy,
       "x-amz-signature" => signature(config(), expires_at, encoded_policy)
     }}
  end

  @doc """
  Returns the meta block LiveView expects for `external` uploads.

  Pass `as_attachment?: true` to store the object with `Content-Disposition: attachment`
  so simple cross-origin `<a href>` will download.

  Options:
    * `:as_attachment?` (boolean) – default `false`
    * `:download_filename` (string) – default `entry.client_name`
  """
  def meta(entry, uploads) do
    s3_filepath = s3_filepath(entry)
    config = Map.get(uploads, entry.upload_config)

    {:ok, fields} =
      sign_form_upload(
        key: s3_filepath,
        content_type: entry.client_type,
        max_file_size: config.max_file_size,
        expires_in: :timer.hours(1)
      )

    %{
      uploader: "S3",
      key: s3_filepath,
      url: bucket_url(),
      fields: fields
    }
  end

  @doc """
  Public bucket name.
  """
  def bucket do
    Application.fetch_env!(@otp_app, :s3_bucket)
  end

  @doc """
  Region short code, e.g. "fra1".
  """
  def region do
    Application.fetch_env!(@otp_app, :s3_region)
  end

  @doc """
  Compute a stable filepath: `<uuid>.<ext>`
  """
  def s3_filepath(entry) do
    "#{entry.uuid}.#{ext(entry)}"
  end

  @doc """
  Public URL for an uploaded entry.
  """
  def entry_url(entry) do
    bucket_url("/#{entry.uuid}.#{ext(entry)}")
  end

  # ————————————————————————————————————————————————————————————————————————
  # Internals
  # ————————————————————————————————————————————————————————————————————————

  defp config do
    %{
      region: region(),
      access_key_id: Application.fetch_env!(@otp_app, :s3_access_key_id),
      secret_access_key: Application.fetch_env!(@otp_app, :s3_secret_access_key)
    }
  end

  defp ext(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    ext
  end

  defp amz_date(time) do
    time
    |> NaiveDateTime.to_iso8601()
    |> String.split(".")
    |> List.first()
    |> String.replace("-", "")
    |> String.replace(":", "")
    |> Kernel.<>("Z")
  end

  defp credential(%{} = cfg, %DateTime{} = expires_at) do
    "#{cfg.access_key_id}/#{short_date(expires_at)}/#{cfg.region}/s3/aws4_request"
  end

  defp signature(cfg, %DateTime{} = now, string_to_sign) do
    cfg
    |> signing_key(now, "s3")
    |> sha256(string_to_sign)
    |> Base.encode16(case: :lower)
  end

  defp signing_key(%{} = cfg, %DateTime{} = expires_at, service) when service in ["s3"] do
    amz_date = short_date(expires_at)
    %{secret_access_key: secret, region: region} = cfg

    ("AWS4" <> secret)
    |> sha256(amz_date)
    |> sha256(region)
    |> sha256(service)
    |> sha256("aws4_request")
  end

  defp short_date(%DateTime{} = expires_at) do
    expires_at
    |> amz_date()
    |> String.slice(0..7)
  end

  defp sha256(secret, msg), do: :crypto.mac(:hmac, :sha256, secret, msg)

  defp bucket_url(path \\ "") do
    "https://#{bucket()}.#{region()}.digitaloceanspaces.com" <> path
  end

  defp cd_value(false, _filename), do: nil
  defp cd_value(true, nil), do: "attachment"
  defp cd_value(true, filename), do: ~s(attachment; filename="#{filename}")

  @doc """
  Presign a GET URL for a Spaces object, optionally forcing download.

  opts:
    * :expires_in (integer seconds, default 300)
    * :as_attachment? (boolean, default false)
    * :filename (string, when forcing attachment)
    * :content_type (string, optional)

  Example:
    S3Uploader.presign_get_url("358a3ede-...545.xml",
      as_attachment?: true,
      filename: "statement.xml",
      content_type: "application/xml",
      expires_in: 300
    )
  """
  def presign_get_url(key_or_url, opts \\ []) do
    {bucket, region} = {bucket(), region()}

    {key, host_override} =
      case URI.parse(key_or_url) do
        # plain key
        %URI{scheme: nil} -> {key_or_url, nil}
        # full URL
        %URI{host: host, path: path} -> {String.trim_leading(path || "", "/"), host}
      end

    host = host_override || "#{bucket}.#{region}.digitaloceanspaces.com"

    expires_in = Keyword.get(opts, :expires_in, 300)
    as_attachment? = Keyword.get(opts, :as_attachment?, false)
    filename = Keyword.get(opts, :filename, nil)
    content_type = Keyword.get(opts, :content_type, nil)

    now = DateTime.utc_now()
    amzdate = amz_date(now)
    datestamp = short_date(now)
    credential = credential(config(), now)

    base_params = %{
      "X-Amz-Algorithm" => "AWS4-HMAC-SHA256",
      "X-Amz-Credential" => credential,
      "X-Amz-Date" => amzdate,
      "X-Amz-Expires" => Integer.to_string(expires_in),
      "X-Amz-SignedHeaders" => "host"
    }

    override_params =
      %{}
      |> maybe_put("response-content-disposition", cd_value(as_attachment?, filename))
      |> maybe_put("response-content-type", content_type)

    params = Map.merge(base_params, override_params)

    canonical_query = aws_canonical_query(params)
    canonical_headers = "host:#{host}\n"
    signed_headers = "host"

    canonical_request =
      Enum.join(
        [
          "GET",
          "/" <> key,
          canonical_query,
          canonical_headers,
          signed_headers,
          "UNSIGNED-PAYLOAD"
        ],
        "\n"
      )

    string_to_sign =
      Enum.join(
        [
          "AWS4-HMAC-SHA256",
          amzdate,
          "#{datestamp}/#{region}/s3/aws4_request",
          sha256_hex(canonical_request)
        ],
        "\n"
      )

    sig = signature(config(), now, string_to_sign)

    "https://#{host}/#{key}?#{canonical_query}&X-Amz-Signature=#{sig}"
  end

  # — helpers (add alongside your other privates) —

  defp maybe_put(map, _k, nil), do: map
  defp maybe_put(map, k, v), do: Map.put(map, k, v)

  # AWS query must be RFC 3986 percent-encoded and keys sorted.
  defp aws_canonical_query(params) do
    params
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.map(fn {k, v} -> aws_encode(k) <> "=" <> aws_encode(v) end)
    |> Enum.join("&")
  end

  # RFC 3986 encode (space -> %20, keep ~)
  defp aws_encode(nil), do: ""

  defp aws_encode(str) when is_binary(str) do
    str
    |> URI.encode_www_form()
    |> String.replace("+", "%20")
    |> String.replace("%7E", "~")
  end

  defp sha256_hex(data) do
    :crypto.hash(:sha256, data)
    |> Base.encode16(case: :lower)
  end
end
