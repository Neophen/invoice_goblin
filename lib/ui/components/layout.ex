defmodule UI.Components.Layout do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is rendered as component
  in regular views and live views.
  """
  use InvoiceGoblinWeb, :html
  use Fluxon

  alias InvoiceGoblin.Accounts.User
  alias InvoiceGoblinWeb.Navigation

  def root_app(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
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
      <body>
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
        <.navigation_list options={Navigation.main_nav()} />
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
    <.sheet id="mobile-sidebar-nav" placement="left" class="w-full flex flex-col max-w-xs">
      <div class="flex mb-6 gap-4 items-center">
        <img src={Navigation.logo_path()} alt={Navigation.company_name()} class="h-7 w-auto" />
      </div>

      {render_slot(@navigation)}
      <.navigation_list class="mt-auto!" options={Navigation.settings_nav()} />
    </.sheet>

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
            <.navigation_list class="mt-auto!" options={Navigation.settings_nav()} />
          </div>

          <div class="max-md:hidden flex flex-col border-t border-zinc-200 dark:border-white/10 p-4">
            <.profile_menu current_user={@current_user} />
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

  attr :options, :map, required: true
  attr :class, :string, default: nil

  def navigation_list(assigns) do
    ~H"""
    <.navlist heading={@options.title} class={@class}>
      <div :for={item <- @options.items}>
        <.navlink
          navigate={item[:navigate]}
          patch={item[:patch]}
          active={item[:active?]}
          phx-click={item[:children] && JS.toggle_attribute({"data-expanded", ""})}
          class="flex items-center gap-1.5"
        >
          <Icon.icon
            :if={item[:icon_name]}
            name={item.icon_name}
            class={["size-[1.2em]", item[:icon_class]]}
          /> {item.label}
          <Icon.icon
            :if={item[:children]}
            name="hero-chevron-right"
            class="size-3 ml-auto in-data-expanded:rotate-90 transition-transform duration-200"
          />
        </.navlink>
        <.navlist_children :if={item[:children]} options={item[:children]} />
      </div>
    </.navlist>
    """
  end

  attr :options, :map, required: true
  attr :class, :string, default: nil

  def navlist_children(assigns) do
    ~H"""
    <div class="grid grid-rows-[0fr] [[data-expanded]+&]:grid-rows-[1fr] transition-all duration-200">
      <div class="overflow-hidden px-4 border-l border-zinc-200 ml-3">
        <.navlist>
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
        </.navlist>
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
            phx-click={Fluxon.open_dialog("mobile-sidebar-nav")}
            class="cursor-default relative flex min-w-0 items-center gap-3 rounded-lg p-2"
          >
            <Icon.icon name="hero-bars-3" class="size-6 text-base-content/80" />
          </button>
        </span>
      </div>
      <div class="min-w-0 flex-1">
        <nav class="flex flex-1 items-center gap-4 py-2.5">
          <div class="flex items-center gap-3 ml-auto">
            <.dropdown placement="bottom-end">
              <:toggle class="w-full flex items-center">
                <button class="cursor-default">
                  <.user_avatar current_user={@current_user} />
                </button>
              </:toggle>

              <.dropdown_link :for={item <- Navigation.profile_nav()} navigate={item.navigate}>
                {item.label}
              </.dropdown_link>
            </.dropdown>
          </div>
        </nav>
      </div>
    </header>
    """
  end

  attr :current_user, User, required: true

  defp profile_menu(assigns) do
    ~H"""
    <.dropdown class="w-56">
      <:toggle class="w-full">
        <button class="cursor-default flex w-full items-center gap-3 rounded-lg px-2 py-2.5">
          <div class="flex min-w-0 items-center gap-3">
            <.user_avatar current_user={@current_user} />

            <div class="min-w-0 text-left">
              <span class="block truncate text-sm font-medium text-zinc-800 dark:text-white">
                {username(@current_user)}
              </span>
              <span class="block truncate text-xs font-normal text-zinc-500 dark:text-zinc-400">
                {@current_user.email}
              </span>
            </div>
          </div>

          <Icon.icon
            name="hero-chevron-up"
            class="size-3 text-zinc-500 group-hover:text-zinc-700 dark:group-hover:text-zinc-200 ml-auto"
          />
        </button>
      </:toggle>

      <.dropdown_link
        :for={item <- Navigation.profile_nav()}
        navigate={item.navigate}
        id={"profile-link-desktop-#{item.id}"}
      >
        {item.label}
      </.dropdown_link>
    </.dropdown>
    """
  end

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
end
