defmodule UI.Components.Layout do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use InvoiceGoblinWeb, :html
  use InvoiceGoblinGettext

  use InvoiceGoblinCldr.VerifiedRoutes,
    endpoint: InvoiceGoblinWeb.Endpoint,
    router: InvoiceGoblinWeb.Router,
    statics: InvoiceGoblinWeb.static_paths()

  alias InvoiceGoblin.Accounts.User
  alias InvoiceGoblinWeb.Navigation

  def root_app(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="overscroll-contain min-h-svh">
      <head>
        {Application.get_env(:live_debugger, :live_debugger_tags)}

        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title default="InvoiceGoblin" suffix=" · InvoiceGoblin">
          {assigns[:page_title]}
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
        </script>
        
    <!-- Favicon -->
        <link rel="icon" type="image/svg+xml" href="favicon.svg" />

        <.home_fonts />
        <.plausible_analytics />
      </head>
      <body class="overscroll-contain min-h-svh">
        {@inner_content}
      </body>
    </html>
    """
  end

  def root_admin(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="overscroll-contain">
      <head>
        {Application.get_env(:live_debugger, :live_debugger_tags)}

        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={get_csrf_token()} />
        <.live_title default="InvoiceGoblin" suffix=" · InvoiceGoblin">
          {assigns[:page_title]}
        </.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
        </script>
        <script>
          (() => {
            const setTheme = (theme) => {
              if (theme === "system") {
                localStorage.removeItem("phx:theme");
                document.documentElement.removeAttribute("data-theme");
              } else {
                localStorage.setItem("phx:theme", theme);
                document.documentElement.setAttribute("data-theme", theme);
              }
            };
            if (!document.documentElement.hasAttribute("data-theme")) {
              setTheme(localStorage.getItem("phx:theme") || "system");
            }
            window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"));
            window.addEventListener("phx:set-theme", ({ detail: { theme } }) => setTheme(theme));
          })();
        </script>
      </head>
      <body class="overscroll-contain">
        {@inner_content}
      </body>
    </html>
    """
  end

  attr :padding?, :boolean, default: false
  attr :class, :string, default: ""
  attr :root_class, :string, default: "min-h-svh"
  attr :current_user, User, required: true
  attr :flash, :map, default: %{}

  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <.admin_base
      current_user={@current_user}
      flash={@flash}
      padding?={@padding?}
      class={@class}
      root_class={@root_class}
    >
      <:navigation>
        <%!-- <.navigation_list options={Navigation.main_nav()} /> --%>
      </:navigation>
      {render_slot(@inner_block)}
    </.admin_base>
    """
  end

  attr :padding?, :boolean, default: false
  attr :class, :string, default: ""
  attr :root_class, :string, default: "min-h-svh"
  attr :current_user, User, required: true
  attr :flash, :map, default: %{}

  slot :inner_block, required: true
  slot :navigation, required: true

  def admin_base(assigns) do
    ~H"""
    <%!-- <.sheet id="mobile-sidebar-nav" placement="left" class="w-full flex flex-col max-w-xs">
      <div class="flex mb-6 gap-4 items-center">
        <img src={Navigation.logo_path()} alt={Navigation.company_name()} class="h-7 w-auto" />
      </div>

      {render_slot(@navigation)}
      <.navigation_list class="mt-auto!" options={Navigation.settings_nav()} />
    </.sheet> --%>

    <div class={[
      "relative isolate flex w-full bg-base-100 max-md:flex-col md:bg-base-200",
      @root_class
    ]}>
      <div class="fixed inset-y-0 left-0 w-64 max-md:hidden">
        <div class="flex h-full flex-col">
          <div class="flex flex-1 flex-col overflow-y-auto p-6">
            <div class="grid mb-8 gap-4">
              <div class="flex items-center gap-2">
                <img src={Navigation.logo_path()} alt={Navigation.company_name()} class="h-6 w-auto" />
                <span class="text-xl font-extrabold text-base-content">
                  {Navigation.company_name()}
                </span>
              </div>
            </div>

            {render_slot(@navigation)}
            <%!-- <.navigation_list class="mt-auto!" options={Navigation.settings_nav()} /> --%>
          </div>

          <div class="max-md:hidden flex flex-col border-t border-zinc-200 dark:border-white/10 p-4">
            <%!-- <.profile_menu current_user={@current_user} /> --%>
          </div>
        </div>
      </div>

      <.mobile_header current_user={@current_user} />
      <main class="flex flex-1 flex-col md:min-w-0 md:p-2 md:pl-64">
        <div class={["grow md:rounded-lg md:bg-base-100 md:border md:border-base-300", @class]}>
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    <Flash.group flash={@flash} />
    """
  end

  # attr :options, :map, required: true
  # attr :class, :string, default: nil

  # def navigation_list(assigns) do
  #   ~H"""
  #   <.navlist heading={@options.title} class={@class}>
  #     <div :for={item <- @options.items}>
  #       <.navlink
  #         navigate={item[:navigate]}
  #         patch={item[:patch]}
  #         active={item[:active?]}
  #         phx-click={item[:children] && JS.toggle_attribute({"data-expanded", ""})}
  #         class="flex items-center gap-1.5"
  #       >
  #         <Icon.icon
  #           :if={item[:icon_name]}
  #           name={item.icon_name}
  #           class={["size-[1.2em]", item[:icon_class]]}
  #         /> {item.label}
  #         <Icon.icon
  #           :if={item[:children]}
  #           name="hero-chevron-right"
  #           class="size-3 ml-auto in-data-expanded:rotate-90 transition-transform duration-200"
  #         />
  #       </.navlink>
  #       <.navlist_children :if={item[:children]} options={item[:children]} />
  #     </div>
  #   </.navlist>
  #   """
  # end

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

  attr :options, :map, required: true
  attr :class, :string, default: nil

  def navlist_children(assigns) do
    ~H"""
    <div class="grid grid-rows-[0fr] [[data-expanded]+&]:grid-rows-[1fr] transition-all duration-200">
      <div class="overflow-hidden px-4 border-l border-zinc-200 ml-3">
        <%!-- <.navlist>
          <.navlink
            :for={item <- @options}
            navigate={item[:navigate]}
            patch={item[:patch]}
            active={item[:active?]}
            class="flex items-center gap-1.5"
          >
            <Icon.icon
              :if={item[:icon_name]}
              name={item.icon_name}
              class={["size-[1.2em]", item[:icon_class]]}
            /> {item.label}
          </.navlink>
        </.navlist> --%>
      </div>
    </div>
    """
  end

  attr :current_user, User, required: true

  defp mobile_header(assigns) do
    ~H"""
    <header class="flex items-center px-4 md:hidden border-b border-base-300">
      <div class="py-2.5">
        <span class="relative">
          <button
            phx-click={UI.open_dialog("mobile-sidebar-nav")}
            class="cursor-default relative flex min-w-0 items-center gap-3 rounded-lg p-2"
          >
            <Icon.icon name="hero-bars-3" class="size-6 text-base-content/80" />
          </button>
        </span>
      </div>
      <div class="min-w-0 flex-1">
        <nav class="flex flex-1 items-center gap-4 py-2.5">
          <div class="flex items-center gap-3 ml-auto">
            <%!-- <.dropdown placement="bottom-end">
              <:toggle class="w-full flex items-center">
                <button class="cursor-default">
                  <.user_avatar current_user={@current_user} />
                </button>
              </:toggle>

              <.dropdown_link :for={item <- Navigation.profile_nav()} navigate={item.navigate}>
                {item.label}
              </.dropdown_link>
            </.dropdown> --%>
          </div>
        </nav>
      </div>
    </header>
    """
  end

  # attr :current_user, User, required: true

  # defp profile_menu(assigns) do
  #   ~H"""
  #   <.dropdown class="w-56">
  #     <:toggle class="w-full">
  #       <button class="cursor-default flex w-full items-center gap-3 rounded-lg px-2 py-2.5">
  #         <div class="flex min-w-0 items-center gap-3">
  #           <.user_avatar current_user={@current_user} />

  #           <div class="min-w-0 text-left">
  #             <span class="block truncate text-sm font-medium text-zinc-800 dark:text-white">
  #               {username(@current_user)}
  #             </span>
  #             <span class="block truncate text-xs font-normal text-zinc-500 dark:text-zinc-400">
  #               {@current_user.email}
  #             </span>
  #           </div>
  #         </div>

  #         <Icon.icon
  #           name="hero-chevron-up"
  #           class="size-3 text-zinc-500 group-hover:text-zinc-700 dark:group-hover:text-zinc-200 ml-auto"
  #         />
  #       </button>
  #     </:toggle>

  #     <.dropdown_link
  #       :for={item <- Navigation.profile_nav()}
  #       navigate={item.navigate}
  #       id={"profile-link-desktop-#{item.id}"}
  #     >
  #       {item.label}
  #     </.dropdown_link>
  #   </.dropdown>
  #   """
  # end

  attr :class, :string, default: nil

  defp theme_toggle(assigns) do
    ~H"""
    <div class={["flex justify-center", @class]}>
      <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
        <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
          class="flex p-2 cursor-pointer w-1/3"
        >
          <Icon.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
          class="flex p-2 cursor-pointer w-1/3"
        >
          <Icon.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>

        <button
          phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
          class="flex p-2 cursor-pointer w-1/3"
        >
          <Icon.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
        </button>
      </div>
    </div>
    """
  end

  attr :current_user, User, required: true

  defp user_avatar(assigns) do
    ~H"""
    <div class="avatar avatar-placeholder">
      <div class="bg-neutral text-neutral-content w-8 rounded-full">
        <span class="text-xs">
          {user_avatar_username(@current_user)}
        </span>
      </div>
    </div>
    """
  end

  defp user_avatar_username(%{email: email}) do
    email
    |> to_string()
    |> String.slice(0, 1)
    |> String.upcase()
  end

  defp username(%User{} = user) do
    user.email
    |> to_string()
    |> String.split("@")
    |> List.first()
    |> String.capitalize()
  end

  defp plausible_analytics(assigns) do
    ~H"""
    <script
      defer
      data-domain="invoicegoblin.com"
      src="https://plausible-octafest.themykolas.com/js/script.pageview-props.tagged-events.js"
    >
    </script>
    <script>
      window.plausible = window.plausible || function() { (window.plausible.q = window.plausible.q || []).push(arguments) }
    </script>
    """
  end

  defp home_fonts(assigns) do
    ~H"""
    <style>
      @font-face {
        font-family: 'Baloo 2';
        font-style: normal;
        font-weight: 400;
        font-display: swap;
        src: url({~p"/fonts/baloo2-regular.woff2"}) format('woff2');
      }
      @font-face {
        font-family: 'Baloo 2';
        font-style: normal;
        font-weight: 500;
        font-display: swap;
        src: url({~p"/fonts/baloo2-medium.woff2"}) format('woff2');
      }
      @font-face {
        font-family: 'Baloo 2';
        font-style: normal;
        font-weight: 600;
        font-display: swap;
        src: url({~p"/fonts/baloo2-semibold.woff2"}) format('woff2');
      }
      @font-face {
        font-family: 'Baloo 2';
        font-style: normal;
        font-weight: 700;
        font-display: swap;
        src: url({~p"/fonts/baloo2-bold.woff2"}) format('woff2');
      }
      @font-face {
        font-family: 'Baloo 2';
        font-style: normal;
        font-weight: 800;
        font-display: swap;
        src: url({~p"/fonts/baloo2-extrabold.woff2"}) format('woff2');
      }
    </style>
    """
  end

  # defp theme_script(assigns) do
  #   ~H"""
  #   <script>
  #     (() => {
  #       const setTheme = (theme) => {
  #         if (theme === "system") {
  #           localStorage.removeItem("phx:theme");
  #           document.documentElement.removeAttribute("data-theme");
  #         } else {
  #           localStorage.setItem("phx:theme", theme);
  #           document.documentElement.setAttribute("data-theme", theme);
  #         }
  #       };
  #       if (!document.documentElement.hasAttribute("data-theme")) {
  #         setTheme(localStorage.getItem("phx:theme") || "system");
  #       }
  #       window.addEventListener("storage", (e) => e.key === "phx:theme" && setTheme(e.newValue || "system"));
  #       window.addEventListener("phx:set-theme", ({ detail: { theme } }) => setTheme(theme));
  #     })();
  #   </script>
  #   """
  # end
end
