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
          navigate: ~q"/admin/dashboard"
        }
        # %{
        #   label: "Analytics",
        #   icon_name: "hero-chart-bar",
        #   navigate: ~q"/admin/analytics"
        # },
        # %{
        #   label: "Posts",
        #   icon_name: "lucide-pen-line",
        #   children: [
        #     %{
        #       label: "Articles",
        #       navigate: ~q"/admin/articles"
        #     },
        #     %{
        #       label: "Categories",
        #       navigate: ~q"/admin/categories"
        #     },
        #     %{
        #       label: "Tags",
        #       navigate: ~q"/admin/tags"
        #     }
        #   ]
        # },
        # %{
        #   label: "Users",
        #   icon_name: "hero-users",
        #   navigate: ~q"/admin/users"
        # },
        # %{
        #   label: "Groups",
        #   icon_name: "lucide-users",
        #   navigate: ~q"/admin/groups"
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
        #   navigate: ~q"/admin/chat-room"
        # },
        # %{
        #   label: "Settings",
        #   icon_name: "hero-cog-6-tooth",
        #   # navigate: ~q"/admin/settings"
        #   navigate: ~q"/admin/dashboard"
        # },
        # %{
        #   label: "Help & Support",
        #   icon_name: "hero-question-mark-circle",
        #   # navigate: ~q"/admin/help"
        #   navigate: ~q"/admin/dashboard"
        # }
      ]
    }
  end

  def profile_nav do
    [
      # %{
      #   id: "profile",
      #   label: "Profile",
      #   navigate: ~q"/admin/profile"
      # },
      # %{
      #   id: "settings",
      #   label: "Settings",
      #   navigate: ~q"/admin/settings"
      # },
      # %{
      #   id: "notifications",
      #   label: "Notifications",
      #   navigate: ~q"/admin/notifications"
      # },
      # %{
      #   id: "billing-plans",
      #   label: "Billing & Plans",
      #   navigate: ~q"/admin/billing-plans"
      # },
      # %{
      #   id: "support",
      #   label: "Support",
      #   navigate: ~q"/admin/support"
      # },
      # %{
      #   id: "documentation",
      #   label: "Documentation",
      #   navigate: ~q"/admin/documentation"
      # },
      %{
        id: "sign-out",
        label: "Sign Out",
        navigate: ~q"/sign-out"
      }
    ]
  end
end
