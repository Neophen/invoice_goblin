defmodule UI.Components.RichText do
  @moduledoc false
  use UI, :component

  attr :id, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true

  attr :rest, :global

  def editor(assigns) do
    ~H"""
    <div
      id={"container-#{@id}"}
      class="rich-text-editor border border-base-300 rounded-md"
      phx-update="ignore"
    >
      <div class="flex gap-2 border-b border-base-300 rounded-t-md p-1">
        <Action.button
          icon_only="lucide-bold"
          data-tiptap-command="bold"
          class="btn btn-square btn-active"
          text={dgettext("rich_text", "Bold")}
        />

        <Action.button
          icon_only="lucide-italic"
          data-tiptap-command="italic"
          class="btn btn-square"
          text={dgettext("rich_text", "Italic")}
        />

        <Action.button
          icon_only="lucide-underline"
          data-tiptap-command="underline"
          class="btn btn-square"
          text={dgettext("rich_text", "Underline")}
        />

        <div class="separator" />

        <Action.button
          icon_only="lucide-heading-1"
          data-tiptap-command="heading1"
          class="btn btn-square"
          text={dgettext("rich_text", "Heading 1")}
        />

        <Action.button
          icon_only="lucide-heading-2"
          data-tiptap-command="heading2"
          class="btn btn-square"
          text={dgettext("rich_text", "Heading 2")}
        />

        <div class="separator" />

        <Action.button
          icon_only="lucide-list"
          data-tiptap-command="bulletList"
          class="btn btn-square"
          text={dgettext("rich_text", "Bullet List")}
        />

        <Action.button
          icon_only="lucide-list-ordered"
          data-tiptap-command="orderedList"
          class="btn btn-square"
          text={dgettext("rich_text", "Ordered List")}
        />
      </div>
      <div id={@id} phx-hook="TipTapHook" class="prose" />

      <UIForm.input type="hidden" {@rest} field={@field} />
    </div>
    """
  end
end
