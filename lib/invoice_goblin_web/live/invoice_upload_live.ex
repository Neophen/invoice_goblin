defmodule InvoiceGoblinWeb.InvoiceUploadLive do
  use InvoiceGoblinWeb, :live_view
  alias InvoiceGoblin.Finance

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:upload_results, %{})
     |> assign(:processing_status, :idle)
     |> assign(:batch_name, "")
     |> allow_upload(:invoice_file,
       accept: ~w(.pdf .png .jpg .jpeg),
       max_entries: 50,
       max_file_size: 10_000_000,
       external: &presign_upload/2
     )}
  end

  @impl true
  def handle_event("validate", %{"batch_name" => batch_name}, socket) do
    {:noreply, assign(socket, :batch_name, batch_name)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :invoice_file, ref)}
  end

  @impl true
  def handle_event("clear-all", _params, socket) do
    {:noreply,
     socket
     |> assign(:uploaded_files, [])
     |> assign(:upload_results, %{})
     |> assign(:processing_status, :idle)}
  end

  @impl true
  def handle_event("retry-failed", _params, socket) do
    failed_files =
      socket.assigns.upload_results
      |> Enum.filter(fn {_ref, result} -> result.status == :error end)
      |> Enum.map(fn {ref, result} -> {ref, result.entry} end)

    socket = assign(socket, :processing_status, :processing)
    send(self(), {:retry_uploads, failed_files})

    {:noreply, socket}
  end

  @impl true
  def handle_event("upload", %{"batch_name" => batch_name}, socket) do
    socket = assign(socket, :processing_status, :processing)
    entries = socket.assigns.uploads.invoice_file.entries

    # Initialize results tracking
    upload_results =
      Enum.reduce(entries, %{}, fn entry, acc ->
        Map.put(acc, entry.ref, %{
          status: :pending,
          entry: %{
            client_name: entry.client_name,
            client_size: entry.client_size,
            client_type: entry.client_type
          },
          invoice: nil,
          error: nil
        })
      end)

    socket = assign(socket, :upload_results, upload_results)

    # Process uploads asynchronously
    send(self(), {:process_uploads, entries, batch_name})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:process_uploads, entries, batch_name}, socket) do
    Task.async_stream(
      entries,
      fn entry ->
        {entry.ref, process_single_upload(socket, entry, batch_name)}
      end,
      max_concurrency: 3,
      timeout: :infinity
    )
    |> Enum.each(fn {:ok, {ref, result}} ->
      send(self(), {:upload_complete, ref, result})
    end)

    send(self(), :all_uploads_complete)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:retry_uploads, failed_files}, socket) do
    Task.async_stream(
      failed_files,
      fn {ref, _entry} ->
        # Simulate re-reading the file (in real app, you'd need to store or re-upload)
        result = %{
          status: :error,
          invoice: nil,
          error: "Retry not implemented - file data not stored"
        }

        {ref, result}
      end,
      max_concurrency: 3,
      timeout: :infinity
    )
    |> Enum.each(fn {:ok, {ref, result}} ->
      send(self(), {:upload_complete, ref, result})
    end)

    send(self(), :all_uploads_complete)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:upload_complete, ref, result}, socket) do
    upload_results =
      Map.update!(socket.assigns.upload_results, ref, fn current ->
        Map.merge(current, result)
      end)

    uploaded_files =
      if result.status == :success && result.invoice do
        [result.invoice | socket.assigns.uploaded_files]
      else
        socket.assigns.uploaded_files
      end

    {:noreply,
     socket
     |> assign(:upload_results, upload_results)
     |> assign(:uploaded_files, uploaded_files)}
  end

  @impl true
  def handle_info(:all_uploads_complete, socket) do
    results = socket.assigns.upload_results

    success_count = Enum.count(results, fn {_, r} -> r.status == :success end)
    error_count = Enum.count(results, fn {_, r} -> r.status == :error end)

    flash_message =
      cond do
        error_count == 0 ->
          {:info, "Successfully uploaded and processed #{success_count} invoice(s)"}

        success_count == 0 ->
          {:error, "Failed to upload all #{error_count} invoice(s)"}

        true ->
          {:warning, "Uploaded #{success_count} invoice(s), #{error_count} failed"}
      end

    {type, message} = flash_message

    {:noreply,
     socket
     |> put_flash(type, message)
     |> assign(:processing_status, :complete)}
  end

  defp process_single_upload(socket, entry, batch_name) do
    consume_uploaded_entry(socket, entry, fn %{} ->
      title =
        if batch_name != "" do
          "#{batch_name} - #{entry.client_name}"
        else
          entry.client_name
        end

      file_url = S3Uploader.entry_url(entry)

      # Create the invoice with the file URL
      case Ash.create(
             Finance.Invoice,
             %{
               title: title,
               file_url: file_url,
               file_name: entry.client_name,
               file_size: entry.client_size,
               file_type: entry.client_type
             },
             action: :upload_and_process,
             actor: socket.assigns.current_user
           ) do
        {:ok, invoice} ->
          {:ok, %{status: :success, invoice: invoice, error: nil}}

        {:error, error} ->
          {:ok, %{status: :error, invoice: nil, error: Exception.message(error)}}
      end
    end)
  end

  defp presign_upload(entry, %{assigns: %{uploads: uploads}} = socket) do
    meta = S3Uploader.meta(entry, uploads)
    {:ok, meta, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="container mx-auto px-4 py-8">
        <h1 class="text-3xl font-bold mb-8">Bulk Invoice Upload</h1>

        <div class="bg-white rounded-lg shadow-md p-6">
          <form id="upload-form" phx-submit="upload" phx-change="validate">
            <div class="mb-4">
              <label for="batch_name" class="block text-sm font-medium text-gray-700 mb-2">
                Batch Name (Optional)
              </label>
              <input
                type="text"
                name="batch_name"
                id="batch_name"
                value={@batch_name}
                placeholder="e.g., Q1 2024 Expenses"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={@processing_status == :processing}
              />
            </div>

            <div
              class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-blue-500 transition-colors"
              phx-drop-target={@uploads.invoice_file.ref}
            >
              <svg
                class="mx-auto h-12 w-12 text-gray-400"
                stroke="currentColor"
                fill="none"
                viewBox="0 0 48 48"
              >
                <path
                  d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>

              <p class="mt-4 text-sm text-gray-600">
                <label
                  for={@uploads.invoice_file.ref}
                  class="cursor-pointer text-blue-600 hover:text-blue-500"
                >
                  Click to select files
                </label>
                or drag and drop
              </p>
              <p class="text-xs text-gray-500 mt-2">
                PDF, PNG, JPG up to 10MB each • Maximum 50 files
              </p>

              <div :if={length(@uploads.invoice_file.entries) > 0} class="mt-4 text-sm text-gray-700">
                {length(@uploads.invoice_file.entries)} file(s) selected
              </div>

              <.live_file_input upload={@uploads.invoice_file} class="hidden" />
            </div>

            <div
              :if={@processing_status == :idle && map_size(@upload_results) == 0}
              class="mt-4 max-h-60 overflow-y-auto"
            >
              <div :for={entry <- @uploads.invoice_file.entries} class="mt-2">
                <div class="flex items-center justify-between p-2 bg-gray-50 rounded-md text-sm">
                  <div class="flex items-center space-x-2 flex-1 min-w-0">
                    <svg
                      class="h-5 w-5 text-gray-400 flex-shrink-0"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M4 4a2 2 0 00-2 2v8a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2H4zm3 5a1 1 0 011-1h4a1 1 0 110 2H8a1 1 0 01-1-1zm0 3a1 1 0 011-1h4a1 1 0 110 2H8a1 1 0 01-1-1z"
                        clip-rule="evenodd"
                      />
                    </svg>
                    <span class="truncate">{entry.client_name}</span>
                    <span class="text-gray-500 text-xs">{format_file_size(entry.client_size)}</span>
                  </div>

                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    class="text-red-500 hover:text-red-700 ml-2"
                  >
                    <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fill-rule="evenodd"
                        d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <div :if={map_size(@upload_results) > 0} class="mt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-2">Processing Results</h3>
              <div class="max-h-60 overflow-y-auto space-y-2">
                <div
                  :for={{ref, result} <- @upload_results}
                  class="flex items-center justify-between p-2 bg-gray-50 rounded-md text-sm"
                >
                  <div class="flex items-center space-x-2 flex-1">
                    <div class={[
                      "h-5 w-5 rounded-full flex items-center justify-center",
                      result.status == :pending && "bg-gray-200",
                      result.status == :success && "bg-green-100",
                      result.status == :error && "bg-red-100"
                    ]}>
                      <svg
                        :if={result.status == :pending}
                        class="h-3 w-3 text-gray-500 animate-spin"
                        fill="none"
                        viewBox="0 0 24 24"
                      >
                        <circle
                          class="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          stroke-width="4"
                        >
                        </circle>
                        <path
                          class="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        >
                        </path>
                      </svg>
                      <svg
                        :if={result.status == :success}
                        class="h-3 w-3 text-green-600"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                          clip-rule="evenodd"
                        />
                      </svg>
                      <svg
                        :if={result.status == :error}
                        class="h-3 w-3 text-red-600"
                        fill="currentColor"
                        viewBox="0 0 20 20"
                      >
                        <path
                          fill-rule="evenodd"
                          d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                          clip-rule="evenodd"
                        />
                      </svg>
                    </div>
                    <span class="truncate">{result.entry.client_name}</span>
                    <span :if={result.status == :error} class="text-red-600 text-xs truncate">
                      {result.error}
                    </span>
                  </div>
                </div>
              </div>

              <div class="mt-4 flex items-center justify-between text-sm">
                <div class="space-x-4">
                  <span class="text-green-600">
                    Success: {Enum.count(@upload_results, fn {_, r} -> r.status == :success end)}
                  </span>
                  <span class="text-red-600">
                    Failed: {Enum.count(@upload_results, fn {_, r} -> r.status == :error end)}
                  </span>
                </div>

                <div class="space-x-2">
                  <button
                    :if={Enum.any?(@upload_results, fn {_, r} -> r.status == :error end)}
                    type="button"
                    phx-click="retry-failed"
                    class="text-blue-600 hover:text-blue-800"
                    disabled={@processing_status == :processing}
                  >
                    Retry Failed
                  </button>

                  <button
                    type="button"
                    phx-click="clear-all"
                    class="text-gray-600 hover:text-gray-800"
                  >
                    Clear All
                  </button>
                </div>
              </div>
            </div>

            <div class="mt-6 flex space-x-4">
              <button
                type="submit"
                disabled={@uploads.invoice_file.entries == [] || @processing_status == :processing}
                class={[
                  "flex-1 py-2 px-4 rounded-md transition-colors",
                  (@uploads.invoice_file.entries == [] || @processing_status == :processing) &&
                    "bg-gray-300 text-gray-500 cursor-not-allowed",
                  @uploads.invoice_file.entries != [] && @processing_status != :processing &&
                    "bg-blue-600 text-white hover:bg-blue-700"
                ]}
              >
                {if @processing_status == :processing,
                  do: "Processing...",
                  else: "Upload #{length(@uploads.invoice_file.entries)} Invoice(s)"}
              </button>

              <.link
                navigate={~p"/invoices"}
                class="py-2 px-4 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                View All Invoices
              </.link>

              <.link
                navigate={~p"/invoices/processing"}
                class="py-2 px-4 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Processing Dashboard
              </.link>
            </div>
          </form>
        </div>

        <div :if={@uploaded_files != []} class="mt-8">
          <h2 class="text-xl font-semibold mb-4">Recently Uploaded Invoices</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div
              :for={invoice <- Enum.take(@uploaded_files, 6)}
              class="bg-white rounded-lg shadow p-4"
            >
              <h3 class="font-medium text-gray-900 truncate">{invoice.title}</h3>
              <p class="text-sm text-gray-500 mt-1">
                Status:
                <span class={[
                  "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                  invoice.status == :processing && "bg-yellow-100 text-yellow-800",
                  invoice.status == :parsed && "bg-green-100 text-green-800",
                  invoice.status == :matched && "bg-blue-100 text-blue-800",
                  invoice.status == :error && "bg-red-100 text-red-800"
                ]}>
                  {invoice.status}
                </span>
              </p>
              <.link
                navigate={~p"/invoices/#{invoice.id}"}
                class="text-blue-600 hover:text-blue-800 text-sm mt-2 inline-block"
              >
                View Details →
              </.link>
            </div>
          </div>

          <div :if={length(@uploaded_files) > 6} class="mt-4 text-center">
            <.link navigate={~p"/invoices"} class="text-blue-600 hover:text-blue-800">
              View all {length(@uploaded_files)} uploaded invoices →
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_file_size(size) do
    cond do
      size < 1024 -> "#{size} B"
      size < 1024 * 1024 -> "#{Float.round(size / 1024, 1)} KB"
      true -> "#{Float.round(size / (1024 * 1024), 1)} MB"
    end
  end
end
