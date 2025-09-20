defmodule InvoiceGoblinWeb.Router do
  use InvoiceGoblinWeb, :router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers
  import Oban.Web.Router

  alias InvoiceGoblin.Accounts.User
  alias UI.Components.Layout

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Layout, :root_app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :browser_admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Layout, :root_admin}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/api/json" do
    pipe_through [:api]

    forward "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
      path: "/api/json/open_api",
      default_model_expand_depth: 4

    forward "/", InvoiceGoblinWeb.AshJsonApiRouter
  end

  scope "/", InvoiceGoblinWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_no_user}
    end
  end

  scope "/admin", InvoiceGoblinWeb.Admin do
    pipe_through :browser_admin

    ash_authentication_live_session :admin_routes,
      on_mount: [
        {InvoiceGoblinWeb.LiveUserAuth, :live_user_required},
        {InvoiceGoblinWeb.Hooks.CurrentPath, :current_path}
      ] do
      localize do
        live "/#{locale}/dashboard", DashboardLive
        # live "/#{locale}/analytics", AnalyticsLive
        # live "/#{locale}/posts", PostsLive
        # live "/#{locale}/users", UsersLive
        # live "/#{locale}/chat-room", ChatRoomLive.Index
        # live "/#{locale}/chat-room/:id", ChatRoomLive.Index
        # live "/#{locale}/chat-room/:id/edit", ChatRoomLive.EditRoom

        # Posts
        # Posts.Category
        # live "/#{locale}/categories", CategoryLive.Index, :index
        # live "/#{locale}/categories/new", CategoryLive.Form, :new
        # live "/#{locale}/categories/:id/edit", CategoryLive.Form, :edit
        # live "/#{locale}/categories/:id", CategoryLive.Show, :show
        # live "/#{locale}/categories/:id/show/edit", CategoryLive.Show, :edit

        # Posts.Tag
        # live "/#{locale}/tags", TagLive.Index, :index
        # live "/#{locale}/tags/new", TagLive.Form, :new
        # live "/#{locale}/tags/:id/edit", TagLive.Form, :edit
        # live "/#{locale}/tags/:id", TagLive.Show, :show
        # live "/#{locale}/tags/:id/show/edit", TagLive.Show, :edit

        # Posts.Article
        # live "/#{locale}/articles", ArticleLive.Index, :index
        # live "/#{locale}/articles/new", ArticleLive.Form, :new
        # live "/#{locale}/articles/:id/edit", ArticleLive.Form, :edit
        # live "/#{locale}/articles/:id", ArticleLive.Show, :show
        # live "/#{locale}/articles/:id/show/edit", ArticleLive.Show, :edit

        # Accounts
        # Accounts.Group
        # live "/#{locale}/groups", GroupLive.Index
        # live "/#{locale}/groups/:id", GroupLive.Show

        # live "/#{locale}/profile", ProfileLive
        # live "/#{locale}/settings", SettingsLive
        # live "/#{locale}/notifications", NotificationsLive
        # live "/#{locale}/billing-plans", BillingPlansLive
        # live "/#{locale}/support", SupportLive
        # live "/#{locale}/documentation", DocumentationLive
        # live "/#{locale}/sign-out", SignOutLive
      end
    end
  end

  scope "/", InvoiceGoblinWeb do
    pipe_through :browser

    live "/", HomeLive
    auth_routes AuthController, User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{InvoiceGoblinWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    InvoiceGoblinWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  InvoiceGoblinWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route InvoiceGoblin.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [InvoiceGoblinWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(InvoiceGoblin.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [InvoiceGoblinWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", InvoiceGoblinWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:invoice_goblin, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import AshAdmin.Router
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard",
        metrics: InvoiceGoblinWeb.Telemetry,
        ecto_repos: [InvoiceGoblin.Repo],
        ecto_psql_extras_options: [
          index_cache_hit: [format: :ra],
          long_running_queries: [threshold: "200 milliseconds"]
        ]

      oban_dashboard("/oban")
      ash_admin "/ash-admin"

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
