defmodule UI.Components.Field do
  @moduledoc false
  use UI, :component

  alias Phoenix.HTML.FormField

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :field, FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list
  attr :class, :string, default: nil, doc: "the fieldset class to use over defaults"
  attr :input_class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture disabled form list placeholder readonly required)

  def select(%{field: %FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &UI.translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> select()
  end

  def select(assigns) do
    ~H"""
    <fieldset class={["fieldset", @class]}>
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@input_class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <FormUI.error :for={msg <- @errors}>{msg}</FormUI.error>
    </fieldset>
    """
  end

  @doc """
  Renders a label.
  """
  attr(:for, :string, default: nil)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-medium leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  attr :upload, :map, required: true
  attr :id, :string, required: true
  attr :value, :string, default: nil

  def image(assigns) do
    ~H"""
    <div class="col-span-full">
      <.live_file_input upload={@upload} class="sr-only" />
      <.label for={@upload.ref}>
        Cover photo
      </.label>
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
          <p class="text-xs leading-5 text-gray-600">PNG, JPG, GIF up to 8MB</p>
          <p class="text-xs leading-5 text-gray-600">Resolution 1920x1080</p>
        </div>
      </div>

      <div
        :if={@upload.entries != [] || @value}
        phx-drop-target={@upload.ref}
        class="aspect-video relative mt-2 flex items-center justify-center border border-black"
      >
        <.live_img_preview :for={entry <- @upload.entries} entry={entry} class="h-auto w-full" />
        <img :if={@upload.entries == [] && @value} src={@value} class="h-auto w-full" />

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

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:external_client_failure), do: "External client failure"
  def error_to_string(_), do: "Something went wrong"
end
