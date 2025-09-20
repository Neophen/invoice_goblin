defmodule InvoiceGoblinWeb.Navigation do
  @moduledoc false

  use InvoiceGoblinCldr.VerifiedRoutes,
    endpoint: InvoiceGoblinWeb.Endpoint,
    router: InvoiceGoblinWeb.Router,
    statics: InvoiceGoblinWeb.static_paths()

  def logo_path do
    ~q"/images/logo.svg"
  end

  def company_name do
    "InvoiceGoblin"
  end

  def main_nav do
    %{
      title: "Dashboard",
      items: [
        %{
          label: "Dashboard",
          icon_name: "hero-home",
          navigate: ~q"/admin/:locale/dashboard"
        },
        %{
          label: "Analytics",
          icon_name: "hero-chart-bar",
          navigate: ~q"/admin/:locale/analytics"
        },
        %{
          label: "Posts",
          icon_name: "lucide-pen-line",
          children: [
            %{
              label: "Articles",
              navigate: ~q"/admin/:locale/articles"
            },
            %{
              label: "Categories",
              navigate: ~q"/admin/:locale/categories"
            },
            %{
              label: "Tags",
              navigate: ~q"/admin/:locale/tags"
            }
          ]
        },
        %{
          label: "Users",
          icon_name: "hero-users",
          navigate: ~q"/admin/:locale/users"
        },
        %{
          label: "Groups",
          icon_name: "lucide-users",
          navigate: ~q"/admin/:locale/groups"
        }
      ]
    }
  end

  def settings_nav do
    %{
      title: nil,
      items: [
        %{
          label: "Chat",
          icon_name: "hero-chat-bubble-bottom-center-text",
          navigate: ~q"/admin/:locale/chat-room"
        },
        %{
          label: "Settings",
          icon_name: "hero-cog-6-tooth",
          # navigate: ~q"/admin/:locale/settings"
          navigate: ~q"/admin/:locale/dashboard"
        },
        %{
          label: "Help & Support",
          icon_name: "hero-question-mark-circle",
          # navigate: ~q"/admin/:locale/help"
          navigate: ~q"/admin/:locale/dashboard"
        }
      ]
    }
  end

  def profile_nav do
    [
      # %{
      #   id: "profile",
      #   label: "Profile",
      #   navigate: ~q"/admin/:locale/profile"
      # },
      %{
        id: "settings",
        label: "Settings",
        navigate: ~q"/admin/:locale/settings"
      },
      # %{
      #   id: "notifications",
      #   label: "Notifications",
      #   navigate: ~q"/admin/:locale/notifications"
      # },
      # %{
      #   id: "billing-plans",
      #   label: "Billing & Plans",
      #   navigate: ~q"/admin/:locale/billing-plans"
      # },
      # %{
      #   id: "support",
      #   label: "Support",
      #   navigate: ~q"/admin/:locale/support"
      # },
      # %{
      #   id: "documentation",
      #   label: "Documentation",
      #   navigate: ~q"/admin/:locale/documentation"
      # },
      %{
        id: "sign-out",
        label: "Sign Out",
        navigate: ~q"/:locale/sign-out"
      }
    ]
  end
end
