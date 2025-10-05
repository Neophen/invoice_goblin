defmodule UI.Components.Image do
  @moduledoc """
  Image component with WebP and AVIF format support.

  This component automatically generates picture tags with multiple format sources
  for optimal performance and browser compatibility.

  ## Examples

      <Image.show src={~q"/images/goblinas-hero.png"} alt="A friendly goblin" />
      <Image.show src={~q"/images/goblinas-hero.png"} alt="A friendly goblin" class="w-full h-auto" />

  """

  use UI, :component

  attr :src, :string, required: true, doc: "Source path to the image"
  attr :alt, :string, required: true, doc: "Alt text for the image"
  attr :class, :string, default: nil, doc: "CSS classes to apply to the picture element"
  attr :root_class, :string, default: nil, doc: "CSS classes to apply to the img element"
  attr :rest, :global, doc: "Additional HTML attributes"

  attr :loading, :string,
    default: "lazy",
    values: ~w(lazy eager),
    doc: "Loading attribute for the img element"

  def show(assigns) do
    ~H"""
    <picture class={@root_class}>
      <!-- AVIF source for modern browsers that support it -->
      <source srcset={replace_ext(@src, "avif")} type="image/avif" />
      <!-- WebP source as fallback -->
      <source srcset={replace_ext(@src, "webp")} type="image/webp" />
      <!-- Fallback img element -->
      <img
        src={@src}
        alt={@alt}
        class={@class}
        loading={@loading}
        {@rest}
      />
    </picture>
    """
  end

  defp replace_ext(path, new_ext) do
    Path.rootname(path) <> "." <> new_ext
  end
end
