defmodule UI.Headless.Tags do
  @moduledoc """
  A Phoenix component module for creating interactive tags inputs with add/remove functionality.

  This module provides components that work with a LiveView Hook (`TagsHook`) to create
  a dynamic tags input system. Features include:

  - Adding items via Enter key or blur event
  - Removing items via button click or backspace (when empty)
  - Maximum item limit enforcement
  - Duplicate item detection with optional animation
  - Hidden input fields for form submission

  The components must be used together with the corresponding JavaScript hook for full functionality.
  """

  use UI, :component

  @doc """
  Renders the root container for the tags input component.

  ## Parameters
  - `id`: Unique identifier for the component (required)
  - `name`: Form field name for the tags items (required)
  - `max_items`: Maximum number of items allowed (optional)
  - `remove_on_backspace?`: Enable removal of last item on backspace when input is empty (default: false)
  - `class`: CSS classes for the container (optional)
  - `inner_block`: Content to render inside the container (required)

  ## Example
      <Tags.root id="tags" name="tags" max_items="5" remove_on_backspace?>

        <Tags.input id="tags" placeholder="Type and press Enter" />
      </Tags.root>
  """
  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :case_sensitive?, :boolean, default: false
  attr :limit_to_options?, :boolean, default: false
  attr :max_items, :string, default: nil
  attr :remove_on_backspace?, :boolean, default: false
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def root(assigns) do
    ~H"""
    <div
      id={container_id(@id)}
      phx-hook="TagsHook"
      tags-case-sensitive={@case_sensitive?}
      tags-input-id={input_id(@id)}
      tags-input-name={input_name(@name)}
      tags-max-items={@max_items}
      tags-prevent-input-add={@limit_to_options?}
      tags-remove-on-backspace={@remove_on_backspace?}
      class={@class}
    >
      <%!-- Set name/value depending on how you want to handle 'empty' state --%>
      <input tags-empty-input disabled readonly type="hidden" name={input_name(@name)} value="" />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an individual tags item with a hidden input field.

  ## Parameters
  - `name`: Form field name for the item (required)
  - `value`: Value of the item (optional)
  - `animate_duplicate?`: Animate when duplicate is attempted (default: false)
  - `animate_remove?`: Animate when item is removed (default: false)
  - `class`: CSS classes for the item (optional)
  - `inner_block`: Content to display for the item (required)

  ## Example
      <Tags.item name="tags" value="phoenix" animate_duplicate?={true}>
        <span>phoenix</span>
        <Tags.item_remove><i>X</i></.item_remove>
      </Tags.item>
  """
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :animate_duplicate?, :boolean, default: false
  attr :animate_remove?, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def item(%{value: ""} = assigns), do: ~H""

  def item(assigns) do
    ~H"""
    <div
      tags-item
      animate-duplicate={@animate_duplicate?}
      animate-remove={@animate_remove?}
      class={@class}
    >
      <input readonly type="hidden" name={input_name(@name)} value={@value} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a remove button for a tags item.

  ## Parameters
  - `class`: CSS classes for the button (optional)
  - `inner_block`: Content to display in the button (required)

  ## Example
      <Tags.item_remove class="relative">
        <span class="sr-only">{dgettext("admin", "Remove item")}</span>
        <i class="fas fa-times"></i>
      </Tags.item_remove>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def item_remove(assigns) do
    ~H"""
    <button type="button" class={@class} tags-item-remove>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders the text input field for adding new items.

  ## Parameters
  - `id`: Unique identifier matching the root component (required)
  - `placeholder`: Input placeholder text (optional)
  - `disabled`: Whether the input is disabled (default: false)
  - `class`: CSS classes for the input (optional)
  - `rest`: Additional HTML attributes (optional)

  ## Example
      <Tags.input id="tags" placeholder="Add a tag" class="tag-input" />
  """
  attr :id, :string, required: true
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, default: %{}

  def input(assigns) do
    ~H"""
    <input
      type="text"
      id={input_id(@id)}
      placeholder={@placeholder}
      disabled={@disabled}
      class={@class}
      {@rest}
    />
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :search_type, :string, default: "starts_with", values: ["starts_with", "contains"]
  attr :limit_input_to_options?, :boolean, default: false
  attr :keep_open_after_add?, :boolean, default: false
  attr :loop_on_keydown?, :boolean, default: false
  slot :inner_block, required: true

  def options(assigns) do
    ~H"""
    <ul
      id={options_container_id(@id)}
      tags-options-container
      options-limit-input={@limit_input_to_options?}
      options-keep-open-after-add={@keep_open_after_add?}
      options-loop-on-keydown={@loop_on_keydown?}
      options-search-type={@search_type}
      phx-hook="TagsOptionsHook"
      anchor={container_id(@id)}
      class={@class}
    >
      <%!-- popover="manual" --%>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  attr :value, :string, required: true
  attr :label, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def option(assigns) do
    ~H"""
    <li options-item class={@class} data-value={@value} data-label={@label}>
      {render_slot(@inner_block)}
    </li>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def options_no_results(assigns) do
    ~H"""
    <li options-no-results class="hidden data-[active]:block">{render_slot(@inner_block)}</li>
    """
  end

  def item_label(value, []), do: value

  def item_label(value, options) when is_list(options) do
    case Enum.find(options, fn {key, _label} -> key == value end) do
      nil -> value
      {_key, label} -> label
    end
  end

  def input_id(id), do: "#{id}-tags-input"
  defp container_id(id), do: "#{id}-tags-container"
  defp options_container_id(id), do: "#{id}-tags-options-container"
  defp input_name(name), do: if(String.ends_with?(name, "[]"), do: name, else: "#{name}[]")
end
