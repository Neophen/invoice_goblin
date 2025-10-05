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
    plug InvoiceGoblinWeb.Plug.PutLocale
    plug :fetch_live_flash
    plug :put_root_layout, html: {Layout, :root_app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InvoiceGoblinWeb.Plugs.PlausibleSessionPlug
    plug :load_from_session
  end

  pipeline :browser_admin do
    plug :accepts, ["html"]
    plug :fetch_session
    plug InvoiceGoblinWeb.Plug.PutLocale
    plug :fetch_live_flash
    plug :put_root_layout, html: {Layout, :root_admin}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InvoiceGoblinWeb.Plugs.PlausibleSessionPlug
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

  scope "/admin", InvoiceGoblinWeb do
    pipe_through :browser_admin

    ash_authentication_live_session :admin_routes,
      on_mount: [
        {InvoiceGoblinWeb.LiveUserAuth, :live_user_required},
        {InvoiceGoblinWeb.Hooks.CurrentPath, :current_path}
      ] do
      live "/dashboard", DashboardLive
      live "/onboarding", Admin.OnboardingUploadLive

      # Finance routes
      live "/invoices", InvoiceListLive
      live "/invoices/upload", InvoiceUploadLive
      live "/invoices/processing", InvoiceProcessingDashboardLive
      live "/invoices/:id", InvoiceDetailLive

      live "/statements", StatementListLive
      live "/statements/upload", BankStatementUploadLive
      live "/statements/:id", StatementDetailLive

      live "/transactions", TransactionListLive
      # live "/analytics", AnalyticsLive
      # live "/posts", PostsLive
      # live "/users", UsersLive
      # live "/chat-room", ChatRoomLive.Index
      # live "/chat-room/:id", ChatRoomLive.Index
      # live "/chat-room/:id/edit", ChatRoomLive.EditRoom

      # Posts
      # Posts.Category
      # live "/categories", CategoryLive.Index, :index
      # live "/categories/new", CategoryLive.Form, :new
      # live "/categories/:id/edit", CategoryLive.Form, :edit
      # live "/categories/:id", CategoryLive.Show, :show
      # live "/categories/:id/show/edit", CategoryLive.Show, :edit

      # Posts.Tag
      # live "/tags", TagLive.Index, :index
      # live "/tags/new", TagLive.Form, :new
      # live "/tags/:id/edit", TagLive.Form, :edit
      # live "/tags/:id", TagLive.Show, :show
      # live "/tags/:id/show/edit", TagLive.Show, :edit

      # Posts.Article
      # live "/articles", ArticleLive.Index, :index
      # live "/articles/new", ArticleLive.Form, :new
      # live "/articles/:id/edit", ArticleLive.Form, :edit
      # live "/articles/:id", ArticleLive.Show, :show
      # live "/articles/:id/show/edit", ArticleLive.Show, :edit

      # Accounts
      # Accounts.Group
      # live "/groups", GroupLive.Index
      # live "/groups/:id", GroupLive.Show

      # live "/profile", ProfileLive
      # live "/settings", SettingsLive
      # live "/notifications", NotificationsLive
      # live "/billing-plans", BillingPlansLive
      # live "/support", SupportLive
      # live "/documentation", DocumentationLive
      # live "/sign-out", SignOutLive
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
