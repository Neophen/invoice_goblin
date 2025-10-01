defmodule InvoiceGoblinWeb.Components.StatementFormComponent do
  use InvoiceGoblinWeb, :live_component

  alias Phoenix.LiveComponent
  alias InvoiceGoblin.Finance.Statement
  alias InvoiceGoblin.Finance.Camt

  attr :id, :string, required: true
  attr :current_user, :map, required: true

  def show(assigns) do
    ~H"""
    <.live_component
      module={__MODULE__}
      id={@id}
      statement={nil}
      current_user={@current_user}
    />
    """
  end

  @impl LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="statement-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="grid min-w-0 gap-y-8"
      >
        <.statement_input id="statement" upload={@uploads.statement} value={@form[:statement].value} />
        <Action.button type="submit" phx-disable-with="Saving...">Save Statement</Action.button>
      </.form>
    </div>
    """
  end

  @impl LiveComponent
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_form()
    |> allow_upload(:statement,
      accept: [".xml"],
      max_entries: 1,
      max_file_size: 10_000_000,
      auto_upload: true,
      external: &presign_upload/2
    )
    |> ok()
  end

  @impl LiveComponent
  def handle_event("cancel-upload", %{"key" => key, "ref" => ref}, socket) do
    socket
    |> cancel_upload(String.to_existing_atom(key), ref)
    |> noreply()
  end

  def handle_event("validate", params, socket) do
    statement_params = Map.get(params, "statement", %{})

    socket
    |> assign(form: AshPhoenix.Form.validate(socket.assigns.form, statement_params))
    |> noreply()
  end

  def handle_event("save", _params, socket) do
    # Process the uploaded files first
    case consume_uploaded_entries(socket, :statement, &process_file_entry/2) do
      [file_info | _] ->
        process_statement_with_file(socket, file_info)

      [] ->
        socket
        |> put_flash(:error, "No file uploaded")
        |> noreply()
    end
  end

  defp presign_upload(entry, %{assigns: %{uploads: uploads}} = socket) do
    meta = S3Uploader.meta(entry, uploads)

    {:ok, meta, socket}
  end

  defp process_file_entry(_meta, entry) do
    # Read the file content and return both URL and content for processing
    file_url = S3Uploader.entry_url(entry)

    # Download the file content for processing
    case Req.get(file_url) do
      {:ok, %{status: 200, body: file_content}} ->
        {:ok,
         %{
           url: file_url,
           content: file_content,
           name: entry.client_name,
           size: entry.client_size
         }}

      {:error, _} = error ->
        error
    end
  end

  defp process_statement_with_file(socket, file_info) do
    # Extract metadata from XML
    format = Camt.detect(file_info.content)

    case format do
      :unknown ->
        socket
        |> put_flash(
          :error,
          "Unsupported file format. Please upload a valid CAMT.053 or CAMT.054 XML file."
        )
        |> noreply()

      _ ->
        metadata = Camt.parse_statement_metadata(file_info.content, format)
        create_statement_with_metadata(socket, format, file_info, metadata)
    end
  end

  defp create_statement_with_metadata(socket, format, file_info, metadata) do
    # Build statement attributes with extracted metadata
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

    IO.inspect(statement_attrs, label: "____statement_attrs")

    case Ash.create(Statement, statement_attrs, action: :create) do
      {:ok, statement} ->
        # Process transactions immediately and link them to the statement
        entries = Camt.parse_entries(file_info.content, format)
        IO.inspect(entries, label: "____entries")

        # Link transactions to the statement
        {created, _skipped, _errors} = process_transactions_for_statement(entries, statement.id)

        socket
        |> put_flash(:info, "Statement uploaded successfully. Processed #{created} transactions.")
        |> push_navigate(to: ~p"/statements/#{statement.id}")
        |> noreply()

      {:error, error} ->
        IO.inspect(error, label: "____error")

        socket
        |> put_flash(:error, "Failed to create statement: #{inspect(error.errors)}")
        |> noreply()
    end
  end

  defp process_transactions_for_statement(entries, statement_id) do
    results = %{created: 0, skipped: 0, errors: 0}

    final_results =
      Enum.reduce(entries, results, fn entry, acc ->
        # Add statement_id to the entry
        entry_with_statement = Map.put(entry, :statement_id, statement_id)

        case create_transaction(entry_with_statement) do
          {:ok, :created} ->
            %{acc | created: acc.created + 1}

          {:ok, :skipped} ->
            %{acc | skipped: acc.skipped + 1}

          {:error, _reason} ->
            %{acc | errors: acc.errors + 1}
        end
      end)

    {final_results.created, final_results.skipped, final_results.errors}
  end

  defp create_transaction(entry) do
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
      statement_id: entry.statement_id
    }

    case Ash.create(InvoiceGoblin.Finance.Transaction, transaction_attrs, action: :ingest) do
      {:ok, _transaction} ->
        {:ok, :created}

      {:error, %Ash.Error.Invalid{errors: errors}} ->
        # Check if it's a uniqueness violation (duplicate)
        if has_uniqueness_error?(errors) do
          {:ok, :skipped}
        else
          {:error, {:validation_failed, errors}}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp has_uniqueness_error?(errors) when is_list(errors) do
    Enum.any?(errors, fn error ->
      case error do
        %Ash.Error.Changes.InvalidAttribute{field: :source_row_hash} ->
          true

        %{message: message} when is_binary(message) ->
          String.contains?(message, "source_row_hash")

        %{errors: nested_errors} when is_list(nested_errors) ->
          has_uniqueness_error?(nested_errors)

        _ ->
          false
      end
    end)
  end

  defp assign_form(%{assigns: %{statement: statement}} = socket) do
    form =
      if statement do
        AshPhoenix.Form.for_update(statement, :update,
          as: "statement",
          actor: socket.assigns.current_user
        )
      else
        AshPhoenix.Form.for_create(Statement, :create,
          as: "statement",
          actor: socket.assigns.current_user
        )
      end

    assign(socket, form: to_form(form))
  end

  attr :upload, :map, required: true
  attr :id, :string, required: true
  attr :value, :string, default: nil

  def statement_input(assigns) do
    ~H"""
    <div class="col-span-full">
      <.live_file_input upload={@upload} class="sr-only" />
      <label for={@upload.ref}>
        Bank statement
      </label>
      <div
        :if={@upload.entries == [] && is_nil(@value)}
        phx-drop-target={@upload.ref}
        class="border-zinc-900/25 aspect-video mt-2 flex items-center justify-center rounded-lg border border-dashed px-6 py-10"
      >
        <div class="text-center">
          <svg
            class="mx-auto h-12 w-12 text-gray-300"
            viewBox="0 0 24 24"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fill-rule="evenodd"
              d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
              clip-rule="evenodd"
            />
          </svg>
          <div class="mt-4 flex text-sm leading-6 text-gray-600">
            <label
              for={@upload.ref}
              class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
            >
              <span>Upload a file</span>
            </label>
            <p class="pl-1">or drag and drop</p>
          </div>
          <p class="text-xs leading-5 text-gray-600">XML up to 10MB</p>
        </div>
      </div>

      <div
        :if={@upload.entries != [] || @value}
        phx-drop-target={@upload.ref}
        class="aspect-video relative mt-2 flex items-center justify-center border border-black"
      >
        <div class="absolute right-4 bottom-4 flex items-center justify-end gap-4">
          <label
            for={@upload.ref}
            class="block rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-zinc-800 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
          >
            Change
          </label>
          <button
            :for={entry <- @upload.entries}
            type="button"
            class="block rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-red-600 shadow-sm ring-1 ring-inset ring-red-300 hover:bg-red-50"
            phx-click="cancel-upload"
            phx-value-key={@id}
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            Remove
          </button>
        </div>
      </div>

      <.upload_errors_list upload={@upload} />
    </div>
    """
  end

  attr :upload, :map, required: true

  def upload_errors_list(assigns) do
    ~H"""
    <ul>
      <%= for entry <- @upload.entries do %>
        <.error :for={err <- upload_errors(@upload, entry)}>{error_to_string(err)}</.error>
      <% end %>

      <.error :for={err <- upload_errors(@upload)}>{error_to_string(err)}</.error>
    </ul>
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:external_client_failure), do: "External client failure"
  def error_to_string(_), do: "Something went wrong"

  @doc """
  Generates a generic error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <Icon.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end
end
