defmodule InvoiceGoblinWeb.Admin.OnboardingUploadLive do
  use InvoiceGoblinWeb, :live_view

  alias InvoiceGoblin.Accounts.Onboarding
  alias InvoiceGoblin.Finance.{Statement, Camt}
  alias InvoiceGoblin.Finance.Transaction

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    # Check if user has only placeholder organization
    has_only_placeholder =
      Onboarding.has_only_placeholder_organization?(socket.assigns.current_user.id)

    if has_only_placeholder do
      socket
      |> assign(:page_title, "Welcome! Upload your first bank statement")
      |> assign(:show_upload, true)
      |> assign(:show_org_confirmation, false)
      |> assign(:extracted_org_data, nil)
      |> assign(:statement_id, nil)
      |> assign(:placeholder_org_id, nil)
      |> assign(:processing, false)
      |> assign(:vat_id, "")
      |> assign(:has_vat_id, true)
      |> assign(:selected_currency, nil)
      |> allow_upload(:statement,
        accept: [".xml"],
        max_entries: 1,
        max_file_size: 10_000_000
      )
      |> ok()
    else
      # User already has a real organization, redirect to dashboard
      socket
      |> put_flash(:info, "Welcome back!")
      |> push_navigate(to: ~p"/admin/dashboard")
      |> ok()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center px-4">
      <div class="max-w-2xl w-full">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900 mb-4">Welcome to Invoice Goblin!</h1>
          <p :if={@show_upload} class="text-lg text-gray-600">
            Let's get started by uploading your first bank statement.
            We'll extract your organization details automatically.
          </p>
          <p :if={@processing} class="text-lg text-gray-600">
            Processing your statement...
          </p>
          <p :if={@show_org_confirmation} class="text-lg text-gray-600">
            We've extracted your organization details from the statement.
          </p>
        </div>

        <%!-- Upload section --%>
        <div :if={@show_upload} class="bg-white rounded-2xl shadow-xl p-8">
          <.form for={%{}} phx-change="validate" phx-submit="submit" id="upload-form">
            <div class="border-2 border-dashed border-gray-300 rounded-xl p-12 text-center hover:border-indigo-500 transition-colors">
              <.live_file_input upload={@uploads.statement} class="sr-only" />

              <div phx-drop-target={@uploads.statement.ref}>
                <svg
                  class="mx-auto h-16 w-16 text-gray-400 mb-4"
                  stroke="currentColor"
                  fill="none"
                  viewBox="0 0 48 48"
                  aria-hidden="true"
                >
                  <path
                    d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>

                <label
                  for={@uploads.statement.ref}
                  class="cursor-pointer text-indigo-600 hover:text-indigo-500 font-semibold"
                >
                  Upload your bank statement
                </label>
                <span class="text-gray-600"> or drag and drop</span>

                <p class="text-sm text-gray-500 mt-2">
                  XML file (CAMT.053 or CAMT.054) up to 10MB
                </p>
              </div>
            </div>

            <.upload_errors_list upload={@uploads.statement} />

            <button
              :if={@uploads.statement.entries != []}
              type="submit"
              class="mt-6 w-full px-6 py-3 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 transition-colors"
            >
              Process Statement
            </button>
          </.form>

          <div class="mt-6 text-center text-sm text-gray-600">
            <p>Don't have a bank statement handy?</p>
            <button
              phx-click="skip_onboarding"
              class="text-indigo-600 hover:text-indigo-800 font-medium"
            >
              Skip for now
            </button>
          </div>
        </div>

        <%!-- Processing state --%>
        <div :if={@processing} class="bg-white rounded-2xl shadow-xl p-8">
          <div class="flex flex-col items-center justify-center py-12">
            <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mb-4"></div>
            <p class="text-gray-600">Extracting organization details...</p>
          </div>
        </div>

        <%!-- Organization confirmation --%>
        <div :if={@show_org_confirmation} class="bg-white rounded-2xl shadow-xl p-8">
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-4">
              <svg
                class="h-10 w-10 text-green-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </div>

            <h3 class="text-2xl font-bold text-gray-900 mb-4">Is this your organization?</h3>

            <div class="bg-gray-50 rounded-lg p-6 mb-6 text-left">
              <dl class="space-y-3">
                <div>
                  <dt class="text-sm font-medium text-gray-500">Organization Name</dt>
                  <dd class="mt-1 text-lg font-semibold text-gray-900">
                    {@extracted_org_data && @extracted_org_data.name}
                  </dd>
                </div>
                <div :if={@extracted_org_data && @extracted_org_data.company_code}>
                  <dt class="text-sm font-medium text-gray-500">Company Code</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {@extracted_org_data.company_code}
                  </dd>
                </div>
                <div :if={@extracted_org_data && @extracted_org_data.address}>
                  <dt class="text-sm font-medium text-gray-500">Address</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {@extracted_org_data.address}
                  </dd>
                </div>
                <div :if={@extracted_org_data && @extracted_org_data.country}>
                  <dt class="text-sm font-medium text-gray-500">Country</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {@extracted_org_data.country}
                  </dd>
                </div>
                <div>
                  <dt class="text-sm font-medium text-gray-500">Bank Account (IBAN)</dt>
                  <dd class="mt-1 text-sm font-mono text-gray-900">
                    {@extracted_org_data && @extracted_org_data.account_iban}
                  </dd>
                </div>
                <div :if={@extracted_org_data && @extracted_org_data.account_currency}>
                  <dt class="text-sm font-medium text-gray-500">Account Currency</dt>
                  <dd class="mt-1 text-sm text-gray-900">
                    {@extracted_org_data.account_currency}
                  </dd>
                </div>
              </dl>
            </div>

            <.form
              for={%{}}
              phx-submit="confirm_organization"
              phx-change="update_form_fields"
              id="vat-form"
            >
              <div :if={@extracted_org_data && !@extracted_org_data.account_currency} class="mb-6">
                <label for="currency" class="block text-sm font-medium text-gray-700 mb-2">
                  Account Currency <span class="text-red-500">*</span>
                </label>
                <select
                  name="currency"
                  id="currency"
                  required
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="">Select currency...</option>
                  <option value="EUR" selected={@selected_currency == "EUR"}>EUR - Euro</option>
                  <option value="USD" selected={@selected_currency == "USD"}>USD - US Dollar</option>
                  <option value="GBP" selected={@selected_currency == "GBP"}>
                    GBP - British Pound
                  </option>
                  <option value="PLN" selected={@selected_currency == "PLN"}>
                    PLN - Polish Zloty
                  </option>
                  <option value="CZK" selected={@selected_currency == "CZK"}>
                    CZK - Czech Koruna
                  </option>
                  <option value="SEK" selected={@selected_currency == "SEK"}>
                    SEK - Swedish Krona
                  </option>
                  <option value="NOK" selected={@selected_currency == "NOK"}>
                    NOK - Norwegian Krone
                  </option>
                  <option value="DKK" selected={@selected_currency == "DKK"}>
                    DKK - Danish Krone
                  </option>
                  <option value="CHF" selected={@selected_currency == "CHF"}>
                    CHF - Swiss Franc
                  </option>
                  <option value="JPY" selected={@selected_currency == "JPY"}>
                    JPY - Japanese Yen
                  </option>
                  <option value="CAD" selected={@selected_currency == "CAD"}>
                    CAD - Canadian Dollar
                  </option>
                  <option value="AUD" selected={@selected_currency == "AUD"}>
                    AUD - Australian Dollar
                  </option>
                </select>
              </div>

              <div class="mb-6">
                <label class="flex items-center mb-3">
                  <input
                    type="checkbox"
                    name="has_vat_id"
                    checked={@has_vat_id}
                    phx-click="toggle_vat_id"
                    class="mr-2 h-4 w-4 text-indigo-600 rounded border-gray-300 focus:ring-indigo-500"
                  />
                  <span class="text-sm font-medium text-gray-700">
                    I have a VAT ID
                  </span>
                </label>

                <div :if={@has_vat_id}>
                  <label for="vat_id" class="block text-sm font-medium text-gray-700 mb-2">
                    VAT ID
                  </label>
                  <input
                    type="text"
                    name="vat_id"
                    id="vat_id"
                    value={@vat_id}
                    placeholder="e.g., LT100123456789"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div class="flex gap-4">
                <button
                  type="submit"
                  class="flex-1 px-6 py-3 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  Yes, that's correct
                </button>
                <button
                  type="button"
                  phx-click="reject_organization"
                  class="flex-1 px-6 py-3 bg-gray-200 text-gray-700 font-semibold rounded-lg hover:bg-gray-300 transition-colors"
                >
                  No, let me enter manually
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", _params, socket) do
    # When file is selected, trigger form submit to start upload
    noreply(socket)
  end

  @impl true
  def handle_event("submit", _params, socket) do
    # Form submitted, show processing and consume uploads
    uploaded_files =
      consume_uploaded_entries(socket, :statement, fn meta, entry ->
        {:ok, process_file_entry(meta, entry)}
      end)

    socket =
      socket
      |> assign(:show_upload, false)
      |> assign(:processing, true)

    case uploaded_files do
      [file_info | _] ->
        process_statement_and_extract_org(socket, file_info)

      [] ->
        socket
        |> assign(:show_upload, true)
        |> assign(:processing, false)
        |> put_flash(:error, "No file uploaded")
        |> noreply()
    end
  end

  @impl true
  def handle_event("toggle_vat_id", _params, socket) do
    has_vat_id = !socket.assigns.has_vat_id

    socket =
      socket
      |> assign(:has_vat_id, has_vat_id)
      |> assign(:vat_id, "")

    noreply(socket)
  end

  @impl true
  def handle_event("update_form_fields", params, socket) do
    socket =
      socket
      |> assign(:vat_id, params["vat_id"] || socket.assigns.vat_id)
      |> assign(:selected_currency, params["currency"] || socket.assigns.selected_currency)

    noreply(socket)
  end

  @impl true
  def handle_event("confirm_organization", params, socket) do
    %{
      extracted_org_data: org_data,
      statement_id: statement_id,
      placeholder_org_id: placeholder_org_id,
      current_user: current_user,
      has_vat_id: has_vat_id,
      selected_currency: selected_currency
    } = socket.assigns

    # Add VAT ID to org_data if provided
    org_data =
      if has_vat_id && params["vat_id"] && params["vat_id"] != "" do
        Map.put(org_data, :vat_id, params["vat_id"])
      else
        org_data
      end

    # Add currency if it wasn't extracted but user selected one
    org_data =
      if !org_data.account_currency && params["currency"] && params["currency"] != "" do
        Map.put(org_data, :account_currency, params["currency"])
      else
        org_data
      end

    # Validate that currency is present
    if !org_data.account_currency || org_data.account_currency == "" do
      socket
      |> put_flash(:error, "Please select an account currency.")
      |> noreply()
    else
      case Onboarding.replace_placeholder_organization(
             current_user.id,
             placeholder_org_id,
             org_data,
             statement_id
           ) do
        {:ok, _new_org} ->
          socket
          |> put_flash(:info, "Welcome! Your organization has been set up successfully.")
          |> push_navigate(to: ~p"/admin/dashboard")
          |> noreply()

        {:error, error} ->
          socket
          |> put_flash(:error, "Failed to set up organization: #{inspect(error)}")
          |> assign(:show_org_confirmation, false)
          |> noreply()
      end
    end
  end

  @impl true
  def handle_event("reject_organization", _params, socket) do
    # For now, just close modal and redirect to dashboard
    # In a full implementation, you'd show a form to manually enter org details
    socket
    |> put_flash(:info, "You can set up your organization details later in settings.")
    |> push_navigate(to: ~p"/admin/dashboard")
    |> noreply()
  end

  @impl true
  def handle_event("skip_onboarding", _params, socket) do
    socket
    |> put_flash(:info, "You can upload your bank statement anytime from the dashboard.")
    |> push_navigate(to: ~p"/admin/dashboard")
    |> noreply()
  end

  # Private functions

  defp process_file_entry(meta, entry) do
    # Read the uploaded file from temp storage
    file_content = File.read!(meta.path)

    # Generate S3 key and URL
    s3_key = "statements/#{entry.uuid}.xml"
    bucket = S3Uploader.bucket()
    region = S3Uploader.region()
    file_url = "https://#{bucket}.#{region}.digitaloceanspaces.com/#{s3_key}"

    # Generate authorization headers for S3 PUT
    auth_headers = generate_s3_put_headers(s3_key, entry.client_type, byte_size(file_content))

    # Upload to S3 using PUT
    case Req.put(file_url, body: file_content, headers: auth_headers) do
      {:ok, %{status: status}} when status in 200..299 ->
        %{
          url: file_url,
          content: file_content,
          name: entry.client_name,
          size: entry.client_size
        }

      {:ok, %{status: status, body: body}} ->
        raise "Failed to upload to S3: HTTP #{status}, body: #{inspect(body)}"

      {:error, reason} ->
        raise "Failed to upload to S3: #{inspect(reason)}"
    end
  end

  defp generate_s3_put_headers(key, content_type, _content_length) do
    bucket = S3Uploader.bucket()
    region = S3Uploader.region()
    access_key_id = Application.fetch_env!(:invoice_goblin, :s3_access_key_id)
    secret_access_key = Application.fetch_env!(:invoice_goblin, :s3_secret_access_key)

    now = DateTime.utc_now()
    amz_date = format_amz_date(now)
    datestamp = format_date_stamp(now)

    host = "#{bucket}.#{region}.digitaloceanspaces.com"
    canonical_uri = "/#{key}"
    canonical_query = ""

    payload_hash = "UNSIGNED-PAYLOAD"

    canonical_headers =
      "content-type:#{content_type}\nhost:#{host}\nx-amz-content-sha256:#{payload_hash}\nx-amz-date:#{amz_date}\n"

    signed_headers = "content-type;host;x-amz-content-sha256;x-amz-date"

    canonical_request =
      "PUT\n#{canonical_uri}\n#{canonical_query}\n#{canonical_headers}\n#{signed_headers}\n#{payload_hash}"

    credential_scope = "#{datestamp}/#{region}/s3/aws4_request"

    string_to_sign =
      "AWS4-HMAC-SHA256\n#{amz_date}\n#{credential_scope}\n#{sha256_hex(canonical_request)}"

    signing_key = get_signature_key(secret_access_key, datestamp, region, "s3")
    signature = hmac_sha256_hex(signing_key, string_to_sign)

    authorization =
      "AWS4-HMAC-SHA256 Credential=#{access_key_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    [
      {"Authorization", authorization},
      {"Content-Type", content_type},
      {"x-amz-content-sha256", payload_hash},
      {"x-amz-date", amz_date}
    ]
  end

  defp format_amz_date(datetime) do
    datetime
    |> DateTime.to_naive()
    |> NaiveDateTime.to_iso8601()
    |> String.replace(~r/[:\-]/, "")
    |> String.replace(~r/\.\d+/, "")
    |> Kernel.<>("Z")
  end

  defp format_date_stamp(datetime) do
    datetime
    |> DateTime.to_date()
    |> Date.to_iso8601(:basic)
  end

  defp sha256_hex(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp hmac_sha256(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

  defp hmac_sha256_hex(key, data) do
    hmac_sha256(key, data) |> Base.encode16(case: :lower)
  end

  defp get_signature_key(secret, datestamp, region, service) do
    k_date = hmac_sha256("AWS4#{secret}", datestamp)
    k_region = hmac_sha256(k_date, region)
    k_service = hmac_sha256(k_region, service)
    hmac_sha256(k_service, "aws4_request")
  end

  defp process_statement_and_extract_org(socket, file_info) do
    # Get user's placeholder organization
    case Onboarding.get_user_organization(socket.assigns.current_user.id) do
      {:ok, placeholder_org} ->
        if placeholder_org.is_placeholder do
          do_process_statement(socket, file_info, placeholder_org.id)
        else
          # User already has a real org, shouldn't be here
          socket
          |> put_flash(:info, "You already have an organization set up!")
          |> push_navigate(to: ~p"/admin/dashboard")
          |> noreply()
        end

      {:error, _} ->
        socket
        |> put_flash(:error, "Could not find your organization. Please contact support.")
        |> noreply()
    end
  end

  defp do_process_statement(socket, file_info, placeholder_org_id) do
    format = Camt.detect(file_info.content)

    case format do
      :unknown ->
        socket
        |> assign(:show_upload, true)
        |> assign(:processing, false)
        |> put_flash(
          :error,
          "Unsupported file format. Please upload a valid CAMT.053 or CAMT.054 XML file."
        )
        |> noreply()

      _ ->
        # Extract organization data
        case Onboarding.extract_organization_from_statement(file_info.content) do
          {:ok, org_data} ->
            # Create statement in placeholder org
            case create_statement(file_info, format, placeholder_org_id) do
              {:ok, statement} ->
                # Show confirmation state
                socket
                |> assign(:extracted_org_data, org_data)
                |> assign(:statement_id, statement.id)
                |> assign(:placeholder_org_id, placeholder_org_id)
                |> assign(:processing, false)
                |> assign(:show_org_confirmation, true)
                |> noreply()

              {:error, error} ->
                socket
                |> assign(:show_upload, true)
                |> assign(:processing, false)
                |> put_flash(:error, "Failed to process statement: #{inspect(error)}")
                |> noreply()
            end

          {:error, :unsupported_format} ->
            socket
            |> assign(:show_upload, true)
            |> assign(:processing, false)
            |> put_flash(:error, "Could not extract organization data from statement.")
            |> noreply()
        end
    end
  end

  defp create_statement(file_info, format, org_id) do
    metadata = Camt.parse_statement_metadata(file_info.content, format)

    statement_attrs = %{
      file_url: file_info.url,
      file_name: file_info.name,
      file_size: file_info.size,
      account_iban: metadata[:account_iban],
      statement_date: metadata[:statement_date],
      statement_period_start: metadata[:period_start],
      statement_period_end: metadata[:period_end]
    }

    statement_attrs = Map.put(statement_attrs, :title, Statement.generate_title(statement_attrs))

    # Create with tenant context
    case Ash.create(Statement, statement_attrs, action: :create, tenant: org_id) do
      {:ok, statement} ->
        # Process transactions
        entries = Camt.parse_entries(file_info.content, format)
        process_transactions_for_statement(entries, statement.id, org_id)
        {:ok, statement}

      error ->
        error
    end
  end

  defp process_transactions_for_statement(entries, statement_id, org_id) do
    Enum.each(entries, fn entry ->
      transaction_attrs = %{
        booking_date: entry.booking_date,
        direction: entry.direction,
        amount: entry.amount,
        bank_mark: entry.bank_mark,
        doc_number: entry.doc_number,
        code: entry.code,
        counterparty_name: entry.counterparty_name,
        counterparty_reg_code: entry.counterparty_reg_code,
        payment_purpose: entry.payment_purpose,
        counterparty_iban: entry.counterparty_iban,
        payment_code: entry.payment_code,
        source_row_hash: entry.source_row_hash,
        statement_id: statement_id
      }

      Ash.create(Transaction, transaction_attrs, action: :ingest, tenant: org_id)
    end)
  end

  attr :upload, :map, required: true

  defp upload_errors_list(assigns) do
    ~H"""
    <div :if={@upload.errors != []} class="mt-4">
      <div :for={err <- @upload.errors} class="text-red-600 text-sm">
        {error_to_string(err)}
      </div>
    </div>
    """
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted. Please upload an XML file."

  defp error_to_string(:external_client_failure),
    do: "Upload failed. Please check your connection and try again."

  defp error_to_string(_), do: "Something went wrong with the upload."
end
