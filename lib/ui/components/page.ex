defmodule UI.Components.Page do
  @moduledoc false
  use UI, :component
  use InvoiceGoblinGettext

  use InvoiceGoblinCldr.VerifiedRoutes,
    endpoint: InvoiceGoblinWeb.Endpoint,
    router: InvoiceGoblinWeb.Router,
    statics: InvoiceGoblinWeb.static_paths()

  @doc """
  Renders a header with title.

  ## Examples

      <Page.header>
        <:title>Example</:title>
      </Page.header>
  """

  attr :back, :string, default: nil
  attr :back_text, :string, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :prefix_icon_name, :string, default: nil

  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["flex items-center gap-1", @class]}>
      <.back :if={@back} navigate={@back} text={@back_text} />
      <div>
        <div class="flex items-center gap-2 text-lg">
          <Icon.icon :if={@prefix_icon_name} name={@prefix_icon_name} class="size-[1.2em]" />
          <Text.h1 text={@title} />
        </div>
        <Text.body :if={@subtitle != []} class="mt-2 text-base-content/80">
          {render_slot(@subtitle)}
        </Text.body>
      </div>
      <div class="ml-auto flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  attr :breadcrumbs, :list, required: true
  slot :inner_block

  def breadcrumbs(assigns) do
    ~H"""
    <nav class="flex border-b border-base-300" aria-label={dgettext("page", "Breadcrumb")}>
      <ol role="list" class="mx-auto flex w-full gap-x-4 px-4 sm:px-6 lg:px-8">
        <li class="flex">
          <div class="flex items-center">
            <a
              href={~q"/admin/:locale/dashboard"}
              class="text-base-content/60 hover:text-base-content"
            >
              <svg
                class="size-5 shrink-0"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
                data-slot="icon"
              >
                <path
                  fill-rule="evenodd"
                  d="M9.293 2.293a1 1 0 0 1 1.414 0l7 7A1 1 0 0 1 17 11h-1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6H3a1 1 0 0 1-.707-1.707l7-7Z"
                  clip-rule="evenodd"
                />
              </svg>
              <span class="sr-only">{dgettext("page", "Home")}</span>
            </a>
          </div>
        </li>
        <.breadcrumb :for={breadcrumb <- @breadcrumbs} {breadcrumb} />

        <li :if={@inner_block != []} class="flex flex-1">
          <div class="flex items-center gap-4 flex-1">
            <svg
              class="h-full w-6 shrink-0 text-base-300"
              viewBox="0 0 24 44"
              preserveAspectRatio="none"
              fill="currentColor"
              aria-hidden="true"
            >
              <path d="M.293 0l22 22-22 22h1.414l22-22-22-22H.293z" />
            </svg>
            {render_slot(@inner_block)}
          </div>
        </li>
      </ol>
    </nav>
    """
  end

  attr :navigate, :string, required: true
  attr :label, :string, required: true
  attr :current, :boolean, default: false

  defp breadcrumb(assigns) do
    ~H"""
    <li class="flex">
      <div class="flex items-center">
        <svg
          class="h-full w-6 shrink-0 text-base-300"
          viewBox="0 0 24 44"
          preserveAspectRatio="none"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M.293 0l22 22-22 22h1.414l22-22-22-22H.293z" />
        </svg>

        <.link
          navigate={if @current, do: nil, else: @navigate}
          aria-current={if @current, do: "page", else: nil}
          data-hover={not @current}
          class="ml-4 text-sm font-medium text-base-content/60 data-hover:hover:text-base-content data-hover:cursor-pointer cursor-default"
        >
          {@label}
        </.link>
      </div>
    </li>
    """
  end

  def content(assigns) do
    ~H"""
    <div class="mt-6 px-4 sm:px-6 pb-8 sm:pb-12">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <Page.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  attr :text, :string, default: nil

  def back(assigns) do
    ~H"""
    <.link navigate={@navigate} class="btn btn-ghost btn-sm max-sm:btn-circle relative">
      <Icon.icon name="lucide-arrow-left" class="size-[1.2em]" />
      <span class="max-sm:sr-only">
        {@text || dgettext("page", "Back")}
      </span>
    </.link>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <Page.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </Page.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative py-4  flex items-center justify-end gap-2">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span :for={action <- @action} class="relative">
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end
end
