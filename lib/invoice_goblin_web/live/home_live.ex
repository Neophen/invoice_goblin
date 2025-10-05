defmodule InvoiceGoblinWeb.HomeLive do
  use InvoiceGoblinWeb, :live_view

  alias InvoiceGoblin.Accounts.Waitlist
  alias AshPhoenix.Form
  alias Plausible

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_no_user}

  @impl LiveView
  def render(assigns) do
    ~H"""
    <Flash.group flash={@flash} />

    <.hero form={@form} />
    <.how_it_works />
    <.why_invoice_goblin />
    <.testimonials />
    <.cta_form form={@form} />
    """
  end

  @impl LiveView
  def mount(_params, session, socket) do
    InvoiceGoblinGettext.put_locale(socket.assigns.locale)

    socket
    |> assign(:submitted, false)
    |> assign(:plausible_session, session["plausible_session"])
    |> assign_form(Form.for_create(Waitlist, :create))
    |> ok()
  end

  @impl LiveView
  def handle_event("validate", %{"form" => params}, socket) do
    InvoiceGoblinGettext.put_locale(socket.assigns.locale)

    socket
    |> validate_form(params)
    |> noreply()
  end

  @impl LiveView
  def handle_event("save", %{"form" => params} = raw_params, socket) do
    InvoiceGoblinGettext.put_locale(socket.assigns.locale)

    case submit_form(socket, params) do
      {:ok, _waitlist} ->
        socket
        |> track_waitlist_submit(Map.get(raw_params, "location", "unknown"))
        |> assign(:submitted, true)
        |> put_flash(:info, dgettext("home_live", "Thanks! You've been added to our waitlist."))
        |> noreply()

      {:error, form} ->
        case form do
          %{errors: [email: {"has already been taken", []}]} ->
            socket
            |> assign(:submitted, true)
            |> put_flash(:info, dgettext("home_live", "You're already on our waitlist!"))
            |> noreply()

          _ ->
            socket
            |> assign(:error, dgettext("home_live", "Something went wrong. Please try again."))
            |> assign(:form, form)
            |> noreply()
        end
    end
  end

  defp track_waitlist_submit(socket, location) do
    if plausible_session = socket.assigns.plausible_session do
      Plausible.track_event("waitlist_submit", plausible_session,
        props: %{
          "location" => location,
          "page" => "home"
        }
      )
    end

    socket
  end

  # Components ___________________________________________________________________________

  attr :form, :any, required: true

  defp hero(assigns) do
    ~H"""
    <section class="min-h-screen bg-gradient-hero flex items-center justify-center px-4 py-20">
      <div class="container mx-auto max-w-6xl 2xl:max-w-7xl">
        <div class="grid lg:grid-cols-[1.2fr_1fr] gap-16 lg:gap-20 xl:gap-24 items-center">
          <div class="text-center lg:text-left space-y-8">
            <div class="space-y-4">
              <h1 class="text-4xl md:text-5xl lg:text-5xl xl:text-6xl font-bold text-foreground leading-tight">
                {dgettext("home_live", "Forget invoice hunting, the goblin")}
                <span class="text-transparent bg-gradient-primary bg-clip-text">
                  {dgettext("home_live", "will find everything for you")}
                </span>
              </h1>
              <p class="text-xl lg:text-2xl text-muted-foreground max-w-2xl leading-relaxed font-inter">
                {dgettext(
                  "home_live",
                  "No more searching for all invoices at the end of the month and sending them to your accountant – the goblin collects and organizes everything for you."
                )}
              </p>
            </div>
            <div class="space-y-6">
              <FormUI.root
                id="hero-form"
                for={@form}
                phx-change="validate"
                phx-submit="save"
                class="flex flex-wrap gap-3 md:gap-4"
              >
                <input type="hidden" name="location" value="hero" />
                <input
                  type="email"
                  class="flex w-full bg-background py-2 ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 flex-1 rounded-xl md:rounded-2xl border-2 border-primary/20 focus:border-primary shadow-card-goblin h-12 md:h-16 text-base md:text-lg px-4 md:px-6"
                  placeholder={dgettext("home_live", "Enter your email")}
                  name={@form[:email].name}
                  value={@form[:email].value}
                  autocomplete="email"
                />
                <button
                  class="inline-flex items-center justify-center gap-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&amp;_svg]:pointer-events-none [&amp;_svg]:size-4 [&amp;_svg]:shrink-0 bg-gradient-primary text-white shadow-button-goblin hover:shadow-goblin hover:scale-105 transition-all duration-200 rounded-xl py-2 whitespace-nowrap font-bold h-12 md:h-16 text-lg md:text-xl px-5 md:px-7 md:rounded-2xl"
                  type="submit"
                  phx-disable-with={dgettext("home_live", "Summoning..")}
                >
                  {dgettext("home_live", "🧙‍♂️ Summon the Goblin")}
                </button>
              </FormUI.root>

              <p class="text-sm text-muted-foreground">
                {dgettext(
                  "home_live",
                  "Join other businesses that have already tamed invoice chaos"
                )}
              </p>
            </div>
          </div>

          <Image.show
            src={~p"/images/goblinas-hero.png"}
            src_avif={~p"/images/goblinas-hero.avif"}
            src_webp={~p"/images/goblinas-hero.webp"}
            alt={dgettext("home_live", "Friendly goblin organizing invoices")}
            class="w-full animate-goblin-bounce"
          />
        </div>
      </div>
    </section>
    """
  end

  defp how_it_works(assigns) do
    ~H"""
    <.section class="bg-background">
      <:block_start>
        <.section_header>
          {dgettext("home_live", "How it")}
          <.section_header_highlight
            class="bg-gradient-primary"
            text={dgettext("home_live", "works")}
          />
        </.section_header>
        <.section_subtitle text={
          dgettext(
            "home_live",
            "Three simple steps to order. You grow your business – the goblin takes care of invoices."
          )
        } />
      </:block_start>
      <div class="rounded-2xl bg-white shadow-card-goblin p-6 lg:p-10">
        <div class="space-y-10 md:space-y-32">
          <.how_it_works_item :for={item <- how_it_works_items()} {item} />
        </div>
      </div>
    </.section>
    """
  end

  attr :flip?, :boolean, default: false
  attr :img_src, :string, required: true
  attr :img_src_avif, :string, required: true
  attr :img_src_webp, :string, required: true
  attr :img_alt, :string, required: true
  attr :icon_name, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  defp how_it_works_item(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 gap-6 items-stretch">
      <div
        class="rounded-2xl overflow-hidden h-full md:order-last data-flip:md:order-first"
        data-flip={@flip?}
      >
        <Image.show
          src={@img_src}
          src_avif={@img_src_avif}
          src_webp={@img_src_webp}
          alt={@img_alt}
          class="w-full h-full object-cover"
        />
      </div>
      <div
        class="text-left space-y-4 p-6 rounded-2xl bg-goblin-green shadow-card-goblin h-full md:order-first data-flip:md:order-last"
        data-flip={@flip?}
      >
        <div class="w-16 h-16 rounded-2xl flex items-center justify-center shadow-button-goblin bg-white/20 border border-white/20">
          <Icon.icon name={@icon_name} class="w-8 h-8 text-white" />
        </div>
        <div class="space-y-3">
          <h3 class="text-2xl md:text-3xl font-bold text-white">
            {@title}
          </h3>
          <p class="font-light text-lg md:text-2xl text-white/90 leading-relaxed">
            {@description}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp why_invoice_goblin(assigns) do
    ~H"""
    <.section class="bg-muted/30">
      <:block_start>
        <.section_header>
          {dgettext("home_live", "Why")}
          <.section_header_highlight
            class="bg-gradient-primary"
            text={dgettext("home_live", "InvoiceGoblin?")}
          />
        </.section_header>
      </:block_start>
      <div class="grid md:grid-cols-2 gap-8">
        <.why_card :for={item <- feature_items()} {item} />
      </div>
    </.section>
    """
  end

  attr :description, :string, required: true
  attr :icon_bg, :string, required: true
  attr :icon_name, :string, required: true
  attr :title, :string, required: true

  defp why_card(assigns) do
    ~H"""
    <div class="group p-8 rounded-2xl bg-card shadow-card-goblin hover:shadow-goblin transition-all duration-300 hover:scale-105">
      <div class="flex items-start gap-4">
        <div class={[
          "flex-shrink-0 size-14 rounded-2xl flex items-center justify-center shadow-button-goblin group-hover:animate-goblin-bounce",
          @icon_bg
        ]}>
          <Icon.icon name={@icon_name} class="size-7" />
        </div>
        <div class="space-y-3">
          <h3 class="text-xl font-bold text-foreground">
            {@title}
          </h3>
          <p class="text-muted-foreground leading-relaxed">
            {@description}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp testimonials(assigns) do
    ~H"""
    <.section class="bg-muted/30">
      <:block_start>
        <.section_header>
          <.section_header_highlight
            class="bg-gradient-accent"
            text={dgettext("home_live", "Business experiences")}
          />
          {dgettext("home_live", "with the Goblin")}
        </.section_header>
        <.section_subtitle text={
          dgettext(
            "home_live",
            "Join companies that have already made life easier without lost invoices and end-of-month chaos."
          )
        } />
      </:block_start>

      <div class="grid md:grid-cols-3 gap-12 md:gap-8">
        <.testimonial_card :for={item <- testimonial_items()} {item} />
      </div>
    </.section>
    """
  end

  attr :class, :string, default: nil
  attr :text, :string, required: true
  attr :name, :string, required: true
  attr :job, :string, required: true
  attr :icon, :string, required: true

  defp testimonial_card(assigns) do
    ~H"""
    <div class={[
      "relative p-6 bg-card rounded-2xl shadow-card-goblin hover:shadow-goblin transition-all duration-300 hover:scale-105 relative hover:-translate-y-5 hover:rotate-0",
      @class
    ]}>
      <div class="absolute -bottom-2.5 left-7.5 w-0 h-0 border-l-[15px] border-r-[15px] border-t-[15px] border-l-transparent border-r-transparent border-t-white">
      </div>

      <div class="space-y-4">
        <p class="text-muted-foreground italic leading-relaxed">
          {@text}
        </p>
        <div class="flex items-center space-x-3">
          <div class="w-12 h-12 bg-gradient-primary rounded-full flex items-center justify-center text-2xl">
            {@icon}
          </div>
          <div>
            <p class="font-bold text-foreground">{@name}</p>
            <p class="text-sm text-muted-foreground">{@job}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true

  defp cta_form(assigns) do
    ~H"""
    <.section class="bg-background">
      <div class="grid lg:grid-cols-2 gap-12 items-center">
        <div class="flex justify-center lg:justify-start order-2 lg:order-1">
          <Image.show
            src={~p"/images/goblin-welcome.png"}
            src_avif={~p"/images/goblin-welcome.avif"}
            src_webp={~p"/images/goblin-welcome.webp"}
            alt={dgettext("home_live", "Happy goblin celebrating organized invoices")}
            class="w-full max-w-lg animate-goblin-wiggle"
          />
        </div>
        <div class="text-center lg:text-left space-y-8 order-1 lg:order-2">
          <div class="space-y-4 text-center lg:text-left">
            <.section_header>
              {dgettext("home_live", "Let the")}
              <.section_header_highlight
                class="bg-gradient-primary"
                text={dgettext("home_live", "Goblin")}
              />
              {dgettext("home_live", "organize all invoices")}
            </.section_header>
            <.section_subtitle text={
              dgettext(
                "home_live",
                "Enter your email and get early access with no risk."
              )
            } />
          </div>
          <div class="space-y-6">
            <FormUI.root
              id="cta-form"
              class="flex flex-wrap gap-3 md:gap-4"
              for={@form}
              phx-validate="validate"
              phx-submit="save"
            >
              <input type="hidden" name="location" value="cta_bottom" />
              <input
                type="email"
                class="flex w-full bg-background py-2 ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 flex-1 rounded-xl md:rounded-2xl border-2 border-primary/20 focus:border-primary shadow-card-goblin h-12 md:h-16 text-base md:text-lg px-4 md:px-6 min-w-[200px]"
                placeholder={dgettext("home_live", "Enter your email")}
                value={@form[:email].value}
                name={@form[:email].name}
                autocomplete="email"
              />
              <button
                class="block ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-gradient-secondary text-white shadow-button-goblin hover:shadow-goblin hover:scale-105 transition-all duration-200 rounded-xl py-2 whitespace-nowrap font-bold h-12 md:h-16 text-lg md:text-xl px-5 md:px-7 md:rounded-2xl min-w-fit flex-1"
                type="submit"
                phx-disable-with={dgettext("home_live", "Sending...")}
              >
                {dgettext("home_live", "🎯 Get early access")}
              </button>
            </FormUI.root>
            <div class="flex flex-wrap justify-center lg:justify-start gap-6 text-sm text-muted-foreground">
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Try it free")}</span>
              </div>
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Early adopter privileges")}</span>
              </div>
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Finally invoices – no more headache")}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.section>
    """
  end

  attr :class, :string, required: true

  slot :block_start
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section class={["py-20 px-4", @class]}>
      <div class="container mx-auto max-w-6xl">
        <div :if={@block_start != []} class="text-center space-y-4 mb-16">
          {render_slot(@block_start)}
        </div>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr :text, :string, required: true

  defp section_subtitle(assigns) do
    ~H"""
    <p class="text-xl text-muted-foreground max-w-2xl mx-auto font-inter">
      {@text}
    </p>
    """
  end

  slot :inner_block, required: true

  defp section_header(assigns) do
    ~H"""
    <h2 class="text-4xl lg:text-5xl font-bold text-foreground leading-tight">
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :string, required: true
  attr :text, :string, required: true

  defp section_header_highlight(assigns) do
    ~H"""
    <span class={["text-transparent bg-clip-text", @class]}>
      {@text}
    </span>
    """
  end

  # Template items _______________________________________________________________________
  defp how_it_works_items() do
    [
      %{
        img_src: ~p"/images/goblinas-dziaugiasi.png",
        img_src_avif: ~p"/images/goblinas-dziaugiasi.avif",
        img_src_webp: ~p"/images/goblinas-dziaugiasi.webp",
        img_alt: dgettext("home_live", "Illustration: upload or forward"),
        icon_name: "lucide-upload",
        title: dgettext("home_live", "1. Upload invoices and bank statement"),
        description:
          dgettext(
            "home_live",
            "Upload files or forward by email. The goblin will accept everything."
          ),
        flip?: false
      },
      %{
        img_src: ~p"/images/goblinas-magija.png",
        img_src_avif: ~p"/images/goblinas-magija.avif",
        img_src_webp: ~p"/images/goblinas-magija.webp",
        img_alt: dgettext("home_live", "Illustration: magical reconciliation"),
        icon_name: "lucide-calculator",
        title: dgettext("home_live", "2. The goblin reconciles everything"),
        description:
          dgettext(
            "home_live",
            "It checks which invoices match the payments in the bank statement."
          ),
        flip?: true
      },
      %{
        img_src: ~p"/images/goblinas-iesko.png",
        img_src_avif: ~p"/images/goblinas-iesko.avif",
        img_src_webp: ~p"/images/goblinas-iesko.webp",
        img_alt: dgettext("home_live", "Illustration: detect the tricky ones"),
        icon_name: "lucide-search",
        title: dgettext("home_live", "3. Finds missing invoices"),
        description:
          dgettext(
            "home_live",
            "The goblin shows which invoices are unpaid or which invoices are missing."
          ),
        flip?: false
      }
    ]
  end

  defp feature_items() do
    [
      %{
        img_src: ~p"/images/goblinas-visos-saskaitos.png",
        img_src_avif: ~p"/images/goblinas-visos-saskaitos.avif",
        img_src_webp: ~p"/images/goblinas-visos-saskaitos.webp",
        icon_name: "lucide-shield",
        icon_bg: "bg-gradient-primary text-white",
        title: dgettext("home_live", "All invoices in one place"),
        description:
          dgettext(
            "home_live",
            "No more searching through email or folders – all invoices are neatly uploaded and accessible."
          )
      },
      %{
        img_src: ~p"/images/goblinas-automatinis-patikrinimas.png",
        img_src_avif: ~p"/images/goblinas-automatinis-patikrinimas.avif",
        img_src_webp: ~p"/images/goblinas-automatinis-patikrinimas.webp",
        icon_name: "lucide-zap",
        icon_bg: "bg-gradient-secondary text-white",
        title: dgettext("home_live", "Automatic invoice verification"),
        description:
          dgettext(
            "home_live",
            "Upload a bank statement, and the system will automatically reconcile it with invoices. You'll see what's paid and what's still pending."
          )
      },
      %{
        img_src: ~p"/images/goblinas-klaidu-aptikimas.png",
        img_src_avif: ~p"/images/goblinas-klaidu-aptikimas.avif",
        img_src_webp: ~p"/images/goblinas-klaidu-aptikimas.webp",
        icon_name: "lucide-target",
        icon_bg: "bg-gradient-accent text-white",
        title: dgettext("home_live", "Error detection"),
        description:
          dgettext(
            "home_live",
            "The system immediately shows if an invoice is unpaid, duplicated, or doesn't match a payment."
          )
      },
      %{
        img_src: ~p"/images/goblinas-lengvas-pradetas.png",
        img_src_avif: ~p"/images/goblinas-lengvas-pradetas.avif",
        img_src_webp: ~p"/images/goblinas-lengvas-pradetas.webp",
        icon_name: "lucide-brain",
        icon_bg: "bg-gradient-primary text-white",
        title: dgettext("home_live", "Easy to get started"),
        description:
          dgettext(
            "home_live",
            "No complicated installations or integrations – just upload the bank statement and invoices."
          )
      }
    ]
  end

  defp testimonial_items() do
    [
      %{
        name: dgettext("home_live", "Andrius P."),
        job: dgettext("home_live", "Cafe owner"),
        class: "-rotate-3 md:translate-y-8",
        icon: "🧑‍💼",
        text:
          dgettext(
            "home_live",
            "Every month I used to waste half a day collecting invoices for the accountant. Now I just forward them to the Goblin and everything is sorted. Saved a lot of nerves."
          )
      },
      %{
        name: dgettext("home_live", "Darius K."),
        job: dgettext("home_live", "Auto service manager"),
        class: nil,
        icon: "👨‍💻",
        text:
          dgettext(
            "home_live",
            "My job is to repair cars, not search for invoices. The Goblin helped me collect everything in one place. Sending to the accountant became much easier."
          )
      },
      %{
        name: dgettext("home_live", "Simona V."),
        job: dgettext("home_live", "Marketing company director"),
        class: "rotate-3 md:translate-y-8",
        icon: "👩‍💼",
        text:
          dgettext(
            "home_live",
            "End of month used to be a real headache for me. Now I just upload the bank statement, and the goblin organizes what's paid and what's still missing."
          )
      }
    ]
  end
end
