defmodule UI.Components.UIForm.Tags do
  @moduledoc false
  use UI, :component

  alias UI.Headless.Tags
  alias Phoenix.HTML.FormField

  attr :id, :string, default: nil
  attr :name, :string
  attr :label, :string, default: nil
  attr :description, :string, default: nil
  attr :value, :list, default: []
  attr :options, :list, default: []
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :max_items, :string, default: nil
  attr :search_type, :string, default: "starts_with", values: ["starts_with", "contains"]
  attr :remove_on_backspace?, :boolean, default: true
  attr :errors, :list, default: []
  attr :field, FormField

  def input(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, field_errors(field))
    |> assign_new(:name, fn -> field.name end)
    |> assign(:value, field.value || [])
    |> input()
  end

  def input(assigns) do
    ~H"""
    <fieldset>
      <legend class="sr-only">{@label}</legend>
      <div class="text-sm/6">
        <label for={Tags.input_id(@id)} class="font-medium text-gray-900">
          {@label}
          <span :if={@max_items} class="text-sm text-gray-500">
            {length(@value)} / {@max_items}
          </span>
        </label>
        <p :if={@description} id={"#{@id}-description"} class="text-gray-500">{@description}</p>
        <p :for={msg <- @errors} class="text-red-500">{msg}</p>
      </div>

      <Tags.root
        id={@id}
        name={@name}
        max_items={@max_items}
        remove_on_backspace?={@remove_on_backspace?}
        limit_to_options?={@options != []}
        class="flex flex-wrap gap-2 rounded-xl border px-2 py-1 bg-white mt-2 relative"
      >
        <Tags.item
          :for={item <- @value}
          animate_duplicate?
          name={@name}
          value={item}
          class="flex items-center gap-1 rounded-lg bg-gray-100 px-2 py-1 data-[duplicate]:animate-shake"
        >
          <span class="text-sm">{Tags.item_label(item, @options)}</span>
          <Tags.item_remove class="block text-gray-500 hover:text-gray-700 relative">
            <span class="sr-only">
              {"Remove #{Tags.item_label(item, @options)} item"}
            </span>
            x
          </Tags.item_remove>
        </Tags.item>
        <Tags.input
          id={@id}
          placeholder={@placeholder}
          disabled={@disabled}
          class="flex-1 min-w-20 bg-transparent px-2 py-1 outline-none focus:outline-none focus:ring-0 border-none"
          phx-debounce="300"
        />
        <Tags.options
          :if={@options != []}
          id={@id}
          limit_input_to_options?
          keep_open_after_add?
          loop_on_keydown?
          search_type={@search_type}
          class="open:block hidden border shadow-md rounded-lg bg-white p-2 max-h-64 overflow-scroll top-full left-0 right-0 absolute z-10  mt-2"
        >
          <Tags.option
            :for={{value, label} <- @options}
            value={value}
            label={label}
            class="px-2 py-1 hover:bg-gray-200 data-[focus]:bg-blue-200 rounded-md data-[active=false]:hidden"
          >
            {label}
          </Tags.option>
          <Tags.options_no_results>
            Sorry, no results
          </Tags.options_no_results>
        </Tags.options>
      </Tags.root>
    </fieldset>
    """
  end

  defp field_errors(field) do
    if Phoenix.Component.used_input?(field),
      do: field.errors,
      else: []
  end
end
