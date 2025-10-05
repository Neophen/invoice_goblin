# User Preference-Based Locale Implementation Guide

This guide shows how to implement user-preferred locale for authenticated users in the InvoiceGoblin application.

## Step 1: Add `preferred_locale` attribute to User resource

Edit `/Users/mykolas/Projects/invoice_goblin/lib/invoice_goblin/accounts/user.ex`:

```elixir
attributes do
  uuid_primary_key :id

  attribute :email, :ci_string do
    allow_nil? false
    public? true
  end

  attribute :hashed_password, :string do
    sensitive? true
  end

  attribute :confirmed_at, :utc_datetime_usec

  # Add this new attribute
  attribute :preferred_locale, :string do
    allow_nil? true
    default "lt"
    public? true
    constraints one_of: ["lt", "en"]
  end
end
```

## Step 2: Generate migration

Run this command to create a migration:

```bash
mix ash.codegen add_preferred_locale_to_users
```

This will generate a migration file. Review it and run:

```bash
mix ash.migrate
```

## Step 3: Add update action for preferred locale

Add this action to the User resource in the `actions` section:

```elixir
update :update_preferred_locale do
  description "Update user's preferred locale"
  accept [:preferred_locale]
end
```

## Step 4: Create a LiveView hook to set locale on mount

Create `/Users/mykolas/Projects/invoice_goblin/lib/invoice_goblin_web/live/user_locale.ex`:

```elixir
defmodule InvoiceGoblinWeb.Live.UserLocale do
  @moduledoc """
  Ensures authenticated users have their preferred locale set.
  """
  import Phoenix.Component

  def on_mount(:set_locale, _params, _session, socket) do
    case socket.assigns[:current_user] do
      nil ->
        # No authenticated user, use browser locale from CLDR plug
        {:cont, socket}

      user ->
        # Set locale from user preference
        locale = user.preferred_locale || "lt"
        Gettext.put_locale(InvoiceGoblinGettext.Backend, locale)
        InvoiceGoblinCldr.put_locale(locale)
        {:cont, assign(socket, :locale, locale)}
    end
  end
end
```

## Step 5: Apply the hook to authenticated routes

Edit `/Users/mykolas/Projects/invoice_goblin/lib/invoice_goblin_web/router.ex`:

Find your authenticated `live_session` block and add the `on_mount` hook:

```elixir
live_session :authenticated,
  on_mount: [
    # ... your existing hooks ...
    {InvoiceGoblinWeb.Live.UserLocale, :set_locale}
  ] do
  # ... your authenticated routes ...
end
```

## Step 6: Create a locale switcher component

Create `/Users/mykolas/Projects/invoice_goblin/lib/ui/components/locale_switcher.ex`:

```elixir
defmodule UI.Components.LocaleSwitcher do
  @moduledoc """
  A component to allow users to switch their preferred locale.
  """
  use Phoenix.Component
  import InvoiceGoblinWeb.CoreComponents

  attr :current_user, :any, required: true
  attr :class, :string, default: ""

  def locale_switcher(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={%{}}
        as={:locale}
        phx-change="change_locale"
        id="locale-switcher-form"
      >
        <.input
          type="select"
          name="locale"
          value={@current_user.preferred_locale || "lt"}
          options={[
            {"Lietuvių", "lt"},
            {"English", "en"}
          ]}
          label="Language"
        />
      </.form>
    </div>
    """
  end
end
```

## Step 7: Handle locale change event

In any LiveView where you want to allow locale switching (e.g., user settings page):

```elixir
defmodule InvoiceGoblinWeb.SettingsLive do
  use InvoiceGoblinWeb, :live_view
  alias InvoiceGoblin.Accounts.User

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    user = socket.assigns.current_user

    case Ash.update(user, %{preferred_locale: locale}, action: :update_preferred_locale) do
      {:ok, updated_user} ->
        # Update locale for current session
        Gettext.put_locale(InvoiceGoblinGettext.Backend, locale)
        InvoiceGoblinCldr.put_locale(locale)

        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> assign(:locale, locale)
         |> put_flash(:info, "Language preference updated")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update language preference")}
    end
  end
end
```

## Step 8: Use the locale switcher in your layout or settings page

In your settings page template:

```heex
<UI.Components.LocaleSwitcher.locale_switcher current_user={@current_user} />
```

## How It Works

1. **For unauthenticated users**: The CLDR plugs in the endpoint detect locale from the browser's `Accept-Language` header
2. **For authenticated users**: The `on_mount` hook checks if a user is logged in and sets their preferred locale from the database
3. **Locale switching**: When users change their language preference, it's saved to the database and immediately applied to their session
4. **Persistence**: The user's locale preference persists across sessions and devices

## Testing

You can test the locale setup with:

```elixir
# In IEx
user = InvoiceGoblin.Accounts.User |> Ash.read_one!()
Ash.update!(user, %{preferred_locale: "en"}, action: :update_preferred_locale)

# Verify
user.preferred_locale # Should return "en"
```
