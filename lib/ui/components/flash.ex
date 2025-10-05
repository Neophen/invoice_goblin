defmodule UI.Components.Flash do
  @moduledoc false
  use UI, :component

  @doc """
  Renders flash notices.

  ## Examples

      <Flash.item kind={:info} flash={@flash} />
      <Flash.item kind={:info} phx-mounted={UI.show("#flash")}>Welcome Back!</.item>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def item(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> UI.hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <Icon.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <Icon.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button
          type="button"
          class="group self-start cursor-pointer"
          aria-label={dgettext("global", "close")}
        >
          <Icon.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <Flash.group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="fixed top-0 left-0 w-full z-50 p-4">
      <.item kind={:info} flash={@flash} />
      <.item kind={:error} flash={@flash} />
      <.item
        id="client-error"
        kind={:error}
        title={dgettext("flash", "We can't find the internet")}
        phx-disconnected={UI.show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={UI.hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {dgettext("flash", "Attempting to reconnect")}
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.item>

      <.item
        id="server-error"
        kind={:error}
        title={dgettext("flash", "Something went wrong!")}
        phx-disconnected={UI.show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={UI.hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {dgettext("flash", "Hang in there while we get back on track")}
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 motion-safe:animate-spin" />
      </.item>
    </div>
    """
  end
end
