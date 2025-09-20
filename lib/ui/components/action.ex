defmodule UI.Components.Action do
  @moduledoc false

  use UI, :component

  @doc """
  Renders a button with navigation support.

  ## Examples

      <Action.button text="Send!" />
      <Action.button text="Send!" phx-click="go" class="btn-primary" />
      <Action.button text="Home" navigate={~p"/"} />
  """

  attr :text, :string, default: nil
  attr :icon, :string, default: nil
  attr :icon_only, :string, default: nil
  attr :loading, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil

  attr :type, :string, default: "button", values: ~w(button submit reset)
  attr :rest, :global, include: ~w(form name value href navigate patch method)
  slot :inner_block

  def button(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={["btn", @class]} {@rest} title={@icon_only != nil && @text}>
        <.content icon={@icon} icon_only={@icon_only} loading={@loading}>
          {@text || render_slot(@inner_block)}
        </.content>
      </.link>
      """
    else
      ~H"""
      <button
        class={["btn", @class]}
        {@rest}
        disabled={@disabled or @loading}
        type={@type}
        title={@icon_only != nil && @text}
      >
        <.content icon={@icon} icon_only={@icon_only} loading={@loading}>
          {@text || render_slot(@inner_block)}
        </.content>
      </button>
      """
    end
  end

  attr :icon, :string, default: nil
  attr :icon_only, :string, default: nil
  attr :loading, :boolean, default: false

  slot :inner_block, required: true

  defp content(assigns) do
    ~H"""
    <span :if={@loading} class="loading loading-spinner"></span>
    <Icon.icon
      :if={(@icon || @icon_only) && !@loading}
      name={@icon || @icon_only}
      class="size-[1.2em]"
    />

    <span data-sr-only={@icon_only} class="data-sr-only:sr-only">
      {render_slot(@inner_block)}
    </span>
    """
  end
end
