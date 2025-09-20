defmodule UI.Components.Icon do
  @moduledoc false
  use UI, :component

  @doc """
  Render an icon

  ## Examples:

  <.icon icon="lucide-circle" class="size-4" />
  <.icon icon="octa-alert-circle" class="size-4" />
  <.icon icon="i-block-awards" />

  """
  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "lucide-" <> _name} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "hero-" <> _name} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "octa-" <> _name} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "i-block-" <> _name} = assigns) do
    ~H"""
    <span class={[@name, @class || "w-26 h-9.25"]} {@rest} />
    """
  end
end
