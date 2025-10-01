defmodule UI do
  @moduledoc """
  Entrypoint and module templates for UI.

  UI is our app-agnostic UI component library.
  """

  use InvoiceGoblinGettext

  import Phoenix.LiveView, only: [push_event: 3]

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket

  @spec component() :: Macro.t()
  def component do
    quote do
      use Phoenix.Component, global_prefixes: ~w(octa-)
      use InvoiceGoblinGettext

      # import UI.ClassMerge, only: [merge: 1]
      # import UI.ComponentHelpers
      # import UI.DOM, only: [gen_id: 0]

      alias Phoenix.LiveView.JS
      alias Phoenix.LiveView.Rendered
      alias Phoenix.LiveView.Socket

      unquote(components())
    end
  end

  @spec components() :: Macro.t()
  def components do
    quote do
      alias UI.Components.Action
      alias UI.Components.Card
      alias UI.Components.Field
      alias UI.Components.Flash
      alias UI.Components.Icon
      alias UI.Components.Layout
      alias UI.Components.Modal
      alias UI.Components.RichText
      alias UI.Components.Text
      alias UI.Components.UIForm

      # Add helper functions for modal
      def show_modal(id), do: UI.open_dialog(id)
      def hide_modal(id), do: UI.close_dialog(id)
    end
  end

  @doc """
  When used, dispatch to the appropriate module template.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  @doc ~S'''
  Opens a dialog component (modal, sheet).

  ## Example

  ```heex
  <Action.button phx-click={UI.open_dialog("my-modal")}>Open modal</Action.button>
  <.modal id="my-modal"></.modal>
  ```
  '''
  def open_dialog(id) do
    JS.dispatch("fluxon:dialog:open", to: "##{id}")
    # JS.set_attribute({"data-open", "true"}, to: "##{id}")
  end

  @doc ~S'''
  Closes a dialog component (modal, sheet).

  ## Parameters

    * `id` - The ID of the dialog element to close.

  ## Example

  ```heex
  <Action.button phx-click={UI.close_dialog("my-modal")}>Close modal</Action.button>
  <.modal id="my-modal"></.modal>
  ```
  '''
  def close_dialog(id) do
    JS.dispatch("fluxon:dialog:close", to: "##{id}")
    # JS.set_attribute({"data-open", "false"}, to: "##{id}")
  end

  @doc ~S'''
  Closes a dialog via push event.

  ## Parameters

    * `socket` - The `Phoenix.LiveView.Socket` struct.
    * `id` - The ID of the dialog element to close.

  ## Example

  ```elixir
  def handle_event("close_dialog", _, socket) do
    {:noreply, UI.close_dialog(socket, "my-dialog")}
  end
  ```
  '''

  def close_dialog(%Socket{} = socket, id) do
    push_event(socket, "fluxon:dialog:close", %{id: "##{id}"})
  end

  def close_dialog(%JS{} = js, id) do
    JS.set_attribute(js, {"data-open", "false"}, to: "##{id}")
  end

  @doc ~S'''
  Opens a dialog via push event.

  ## Parameters

    * `socket` - The `Phoenix.LiveView.Socket` struct.
    * `id` - The ID of the dialog element to open.

  ## Example

  ```elixir
  def handle_event("open_dialog", _, socket) do
    {:noreply, UI.open_dialog(socket, "my-dialog")}
  end
  ```
  '''
  def open_dialog(%Socket{} = socket, id) do
    push_event(socket, "fluxon:dialog:open", %{id: "##{id}"})
  end

  def open_dialog(%JS{} = js, id) do
    JS.set_attribute(js, {"data-open", "true"}, to: "##{id}")
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(InvoiceGoblinGettext.Backend, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(InvoiceGoblinGettext.Backend, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
