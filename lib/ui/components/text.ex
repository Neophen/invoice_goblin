defmodule UI.Components.Text do
  @moduledoc """
   Render a Typography component


  ## Examples:

      <Text.h1 text="some text" />
      <Text.h2 text="some text" />
      <Text.h3 text="some text" />
      <Text.h4 text="some text" />
      <Text.h5 text="some text" />
      <Text.subtitle text="some text" />
      <Text.lg text="some text" />
      <Text.body text="some text" />
      <Text.xs text="some text" />
      <Text.menu text="some text" />
      <Text.subtext text="some text" />
  """
  use UI, :component

  @tags ~w(p span h1 h2 h3 h4 h5)
  @default_tag "p"

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: "h1", values: @tags
  attr :rest, :global
  slot :inner_block

  def h1(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-3xl leading-none font-bold", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: "h2", values: @tags
  attr :rest, :global
  slot :inner_block

  def h2(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-2xl leading-none font-bold", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: "h3", values: @tags
  attr :rest, :global
  slot :inner_block

  def h3(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-xl leading-none font-bold", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: "h4", values: @tags
  attr :rest, :global
  slot :inner_block

  def h4(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-lg leading-none font-bold", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: "h5", values: @tags
  attr :rest, :global
  slot :inner_block

  def h5(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-base leading-none font-bold", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def subtitle(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-lg font-medium", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def lg(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-lg", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def body(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-base", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def xs(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-xs", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def menu(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-sm", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  attr :text, :string, default: nil
  attr :class, :string, default: nil
  attr :as, :string, default: @default_tag, values: @tags
  attr :rest, :global
  slot :inner_block

  def subtext(assigns) do
    ~H"""
    <.dynamic_tag tag_name={@as} class={["text-xs", @class]} {@rest}>
      {@text || render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end
end
