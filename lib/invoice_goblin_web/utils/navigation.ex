defmodule InvoiceGoblinWeb.Navigation do
  @moduledoc false

  use Phoenix.VerifiedRoutes,
    endpoint: InvoiceGoblinWeb.Endpoint,
    router: InvoiceGoblinWeb.Router,
    statics: InvoiceGoblinWeb.static_paths()

  def logo_path do
    ~p"/images/logo.svg"
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
          navigate: ~p"/admin/dashboard"
        }
        # %{
        #   label: "Analytics",
        #   icon_name: "hero-chart-bar",
        #   navigate: ~p"/admin/analytics"
        # },
        # %{
        #   label: "Posts",
        #   icon_name: "lucide-pen-line",
        #   children: [
        #     %{
        #       label: "Articles",
        #       navigate: ~p"/admin/articles"
        #     },
        #     %{
        #       label: "Categories",
        #       navigate: ~p"/admin/categories"
        #     },
        #     %{
        #       label: "Tags",
        #       navigate: ~p"/admin/tags"
        #     }
        #   ]
        # },
        # %{
        #   label: "Users",
        #   icon_name: "hero-users",
        #   navigate: ~p"/admin/users"
        # },
        # %{
        #   label: "Groups",
        #   icon_name: "lucide-users",
        #   navigate: ~p"/admin/groups"
        # }
      ]
    }
  end

  def settings_nav do
    %{
      title: nil,
      items: [
        # %{
        #   label: "Chat",
        #   icon_name: "hero-chat-bubble-bottom-center-text",
        #   navigate: ~p"/admin/chat-room"
        # },
        # %{
        #   label: "Settings",
        #   icon_name: "hero-cog-6-tooth",
        #   # navigate: ~p"/admin/settings"
        #   navigate: ~p"/admin/dashboard"
        # },
        # %{
        #   label: "Help & Support",
        #   icon_name: "hero-question-mark-circle",
        #   # navigate: ~p"/admin/help"
        #   navigate: ~p"/admin/dashboard"
        # }
      ]
    }
  end

  def profile_nav do
    [
      # %{
      #   id: "profile",
      #   label: "Profile",
      #   navigate: ~p"/admin/profile"
      # },
      # %{
      #   id: "settings",
      #   label: "Settings",
      #   navigate: ~p"/admin/settings"
      # },
      # %{
      #   id: "notifications",
      #   label: "Notifications",
      #   navigate: ~p"/admin/notifications"
      # },
      # %{
      #   id: "billing-plans",
      #   label: "Billing & Plans",
      #   navigate: ~p"/admin/billing-plans"
      # },
      # %{
      #   id: "support",
      #   label: "Support",
      #   navigate: ~p"/admin/support"
      # },
      # %{
      #   id: "documentation",
      #   label: "Documentation",
      #   navigate: ~p"/admin/documentation"
      # },
      %{
        id: "sign-out",
        label: "Sign Out",
        navigate: ~p"/sign-out"
      }
    ]
  end
end
