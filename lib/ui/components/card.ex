defmodule UI.Components.Card do
  @moduledoc false
  use UI, :component
  use InvoiceGoblinGettext

  use Phoenix.VerifiedRoutes,
    endpoint: InvoiceGoblinWeb.Endpoint,
    router: InvoiceGoblinWeb.Router,
    statics: InvoiceGoblinWeb.static_paths()

  alias Phoenix.LiveView.Rendered

  @doc """
  Render dropdown menu
  ## Examples:
    <Card.default id={@user.id} action={[{:patch, ~p"/"}, {:sr_label, dgettext("admin", "Say hello") ]} >
      <Card.header>
        <Text.h4 class="card-text-primary" text="Title" />
        <Card.menu>
          <Card.menu_action icon="lucide-settings" patch={~p"/"}>
            <%= dgettext("admin", "Settings") %>
          </Card.menu_action>
        </Card.menu>
      </Card.header>
      <Card.footer>
        <Text.xs class="card-text-muted" text={dgettext("admin", "Edited %{time}", time: @user.updated_at)} />
      </Card.footer>
    </Card.default>
  """

  attr :id, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true
  slot :action

  @spec default(map()) :: Rendered.t()
  def default(assigns) do
    ~H"""
    <li
      id={"card-#{@id}"}
      class="group/card octa-text rounded-xl gap-2 bg-base-100 relative grid [grid-template-areas:'header_menu''body_body''footer_action'] grid-rows-[min-content_1fr_min-content] grid-cols-[1fr_min-content] border border-base-300 p-4 hovered-action:border-primary pressed-action:bg-primary shadow-md hovered-action:shadow-accent shadow-primary/5"
      {@rest}
    >
      {render_slot(@action)}

      {render_slot(@inner_block)}
    </li>
    """
  end

  slot :inner_block, required: true

  def header(assigns) do
    ~H"""
    <div class="flex items-center justify-between [grid-area:header]">
      {render_slot(@inner_block)}
    </div>
    """
  end

  slot :inner_block, required: true

  def menu(assigns) do
    ~H"""
    <div class="[grid-area:menu] justify-self-end opacity-5 group-hovered/card:opacity-100 z-10 flex gap-2">
      {render_slot(@inner_block)}
    </div>
    """
  end

  slot :inner_block, required: true

  def body(assigns) do
    ~H"""
    <div class="[grid-area:body]">
      {render_slot(@inner_block)}
    </div>
    """
  end

  slot :inner_block, required: true

  def footer(assigns) do
    ~H"""
    <div class="[grid-area:footer]">
      <hr class="mb-2 w-6 border-base-300 group-hovered-action/card:border-base-content" />
      <div class="flex items-center">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :label, :string, default: nil
  attr :class, :any, default: nil

  attr :rest, :global,
    include:
      ~w(navigate patch href replace method csrf_token download hreflang referrerpolicy rel target type)

  def main_action(assigns) do
    ~H"""
    <.link
      {@rest}
      class="action [grid-area:action] justify-self-end self-end before:absolute before:inset-0 hovered:outline-none hovered:ring-0"
    >
      <Text.xs class="truncate card-text-secondary flex items-center">
        <span class="truncate underline">{@label || dgettext("admin", "View")}</span>
        <Icon.icon name="lucide-chevron-right" class="size-[1.2em] shrink-0" />
      </Text.xs>
    </.link>
    """
  end
end
