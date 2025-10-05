defmodule InvoiceGoblinWeb.HomeLive do
  use InvoiceGoblinWeb, :live_view

  alias InvoiceGoblin.Accounts.Waitlist
  alias AshPhoenix.Form

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
  def mount(_params, _session, socket) do
    socket
    |> assign(:submitted, false)
    |> assign_form(Form.for_create(Waitlist, :create))
    |> ok()
  end

  @impl LiveView
  def handle_event("validate", %{"form" => params}, socket) do
    socket
    |> validate_form(params)
    |> noreply()
  end

  @impl LiveView
  def handle_event("save", %{"form" => params}, socket) do
    case submit_form(socket, params) do
      {:ok, _waitlist} ->
        socket
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

  attr :form, :any, required: true

  defp hero(assigns) do
    ~H"""
    <section class="min-h-screen bg-gradient-hero flex items-center justify-center px-4 py-20">
      <div class="container mx-auto max-w-6xl 2xl:max-w-7xl">
        <div class="grid lg:grid-cols-[1.2fr_1fr] gap-16 lg:gap-20 xl:gap-24 items-center">
          <div class="text-center lg:text-left space-y-8">
            <div class="space-y-4">
              <h1 class="text-4xl md:text-5xl lg:text-5xl xl:text-6xl font-bold text-foreground leading-tight">
                {dgettext("home_live", "Pamirškite sąskaitų medžioklę, goblinas")}
                <span class="text-transparent bg-gradient-primary bg-clip-text">
                  {dgettext("home_live", "viską suras už jus")}
                </span>
              </h1>
              <p class="text-xl lg:text-2xl text-muted-foreground max-w-2xl leading-relaxed font-inter">
                {dgettext(
                  "home_live",
                  "Nebereikės mėnesio pabaigoje ieškoti visų sąskaitų ir siųsti jų buhalterei – goblinas viską surenka ir sudėlioja už jus."
                )}
              </p>
            </div>
            <div class="space-y-6">
              <FormUI.root
                for={@form}
                phx-change="validate"
                phx-submit="save"
                class="flex flex-wrap gap-3 md:gap-4 plausible-event-name=Waitlist+Submit plausible-event-position=hero"
              >
                <input
                  type="email"
                  class="flex w-full bg-background py-2 ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 flex-1 rounded-xl md:rounded-2xl border-2 border-primary/20 focus:border-primary shadow-card-goblin h-12 md:h-16 text-base md:text-lg px-4 md:px-6"
                  placeholder={dgettext("home_live", "Įveskite savo el. paštą")}
                  name={@form[:email].name}
                  value={@form[:email].value}
                  autocomplete="email"
                />
                <button
                  class="inline-flex items-center justify-center gap-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 [&amp;_svg]:pointer-events-none [&amp;_svg]:size-4 [&amp;_svg]:shrink-0 bg-gradient-primary text-white shadow-button-goblin hover:shadow-goblin hover:scale-105 transition-all duration-200 rounded-xl py-2 whitespace-nowrap font-bold h-12 md:h-16 text-lg md:text-xl px-5 md:px-7 md:rounded-2xl"
                  type="submit"
                  phx-disable-with={dgettext("home_live", "Iškviečiama..")}
                >
                  {dgettext("home_live", "🧙‍♂️ Iškviesti Gobliną")}
                </button>
              </FormUI.root>

              <p class="text-sm text-muted-foreground">
                {dgettext(
                  "home_live",
                  "Prisijunkite prie kitų verslų, kurie jau sutramdė sąskaitų chaosą"
                )}
              </p>
            </div>
          </div>

          <Image.show
            src={~q"/images/goblinas-hero.png"}
            alt={dgettext("home_live", "Draugiškas goblinas, tvarkantis sąskaitas")}
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
          {dgettext("home_live", "Kaip tai")}
          <.section_header_highlight
            class="bg-gradient-primary"
            text={dgettext("home_live", "veikia")}
          />
        </.section_header>
        <.section_subtitle text={
          dgettext(
            "home_live",
            "Trys paprasti žingsniai iki tvarkos. Jūs auginate verslą – goblinas pasirūpina sąskaitomis."
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
          {dgettext("home_live", "Kodėl")}
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
            text={dgettext("home_live", "Verslų patirtys")}
          />
          {dgettext("home_live", "su Goblinu")}
        </.section_header>
        <.section_subtitle text={
          dgettext(
            "home_live",
            "Prisijunkite prie įmonių, kurios jau palengvino sau gyvenimą be pamestų sąskaitų ir mėnesio pabaigos chaoso."
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
            src={~q"/images/goblin-welcome.png"}
            alt={dgettext("home_live", "Laimingas goblinas, švenčiantis sutvarkytas sąskaitas")}
            class="w-full max-w-lg animate-goblin-wiggle"
          />
        </div>
        <div class="text-center lg:text-left space-y-8 order-1 lg:order-2">
          <div class="space-y-4 text-center lg:text-left">
            <.section_header>
              {dgettext("home_live", "Leiskite")}
              <.section_header_highlight
                class="bg-gradient-primary"
                text={dgettext("home_live", "Goblinui")}
              />
              {dgettext("home_live", "sutvarkyti visas sąskaitas")}
            </.section_header>
            <.section_subtitle text={
              dgettext(
                "home_live",
                "Įrašykite savo el. paštą ir gaukite ankstyvą prieigą be jokios rizikos."
              )
            } />
          </div>
          <div class="space-y-6">
            <FormUI.root
              class="flex flex-wrap gap-3 md:gap-4 plausible-event-name=Waitlist+Submit plausible-event-position=cta_bottom"
              for={@form}
              phx-validate="validate"
              phx-submit="save"
            >
              <input
                type="email"
                class="flex w-full bg-background py-2 ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 flex-1 rounded-xl md:rounded-2xl border-2 border-primary/20 focus:border-primary shadow-card-goblin h-12 md:h-16 text-base md:text-lg px-4 md:px-6 min-w-[200px]"
                placeholder={dgettext("home_live", "Įveskite savo el. paštą")}
                value={@form[:email].value}
                name={@form[:email].name}
                autocomplete="email"
              />
              <button
                class="block ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-gradient-secondary text-white shadow-button-goblin hover:shadow-goblin hover:scale-105 transition-all duration-200 rounded-xl py-2 whitespace-nowrap font-bold h-12 md:h-16 text-lg md:text-xl px-5 md:px-7 md:rounded-2xl min-w-fit flex-1"
                type="submit"
                phx-disable-with={dgettext("home_live", "Siunčiama...")}
              >
                {dgettext("home_live", "🎯 Gauti ankstyvą prieigą")}
              </button>
            </FormUI.root>
            <div class="flex flex-wrap justify-center lg:justify-start gap-6 text-sm text-muted-foreground">
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Išbandykite nemokamai")}</span>
              </div>
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Ankstyvųjų naudotojų privilegijos")}</span>
              </div>
              <div class="flex items-center space-x-2">
                <span class="text-green-500">✓</span><span>{dgettext("home_live", "Pagaliau sąskaitos – nebe galvos skausmas")}</span>
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
        img_src: ~q"/images/goblinas-dziaugiasi.png",
        img_alt: dgettext("home_live", "Iliustracija: įkėlimas arba persiuntimas"),
        icon_name: "lucide-upload",
        title: dgettext("home_live", "1. Įkelkite sąskaitas ir banko išrašą"),
        description:
          dgettext(
            "home_live",
            "Įkelkite failus arba persiųskite el. paštu. Goblinas viską priims."
          ),
        flip?: false
      },
      %{
        img_src: ~q"/images/goblinas-magija.png",
        img_alt: dgettext("home_live", "Iliustracija: magiškas suderinimas"),
        icon_name: "lucide-calculator",
        title: dgettext("home_live", "2. Goblinas viską sulygina"),
        description:
          dgettext(
            "home_live",
            "Jis patikrina, kurios sąskaitos atitinka banko išraše esančius mokėjimus."
          ),
        flip?: true
      },
      %{
        img_src: ~q"/images/goblinas-iesko.png",
        img_alt: dgettext("home_live", "Iliustracija: aptikite klastinguosius"),
        icon_name: "lucide-search",
        title: dgettext("home_live", "3. Suranda praleistas sąskaitas"),
        description:
          dgettext(
            "home_live",
            "Goblinas parodo, kurios sąskaitos nesumokėtos arba kurių sąskaitų trūksta."
          ),
        flip?: false
      }
    ]
  end

  defp feature_items() do
    [
      %{
        icon_name: "lucide-shield",
        icon_bg: "bg-gradient-primary text-white",
        title: dgettext("home_live", "Visos sąskaitos vienoje vietoje"),
        description:
          dgettext(
            "home_live",
            "Nebereikės ieškoti po el. paštą ar segtuvus – visos sąskaitos tvarkingai sukeltos ir pasiekiamos."
          )
      },
      %{
        icon_name: "lucide-zap",
        icon_bg: "bg-gradient-secondary text-white",
        title: dgettext("home_live", "Automatinis sąskaitų patikrinimas"),
        description:
          dgettext(
            "home_live",
            "Įkelkite banko išrašą, ir sistema pati sulygina jį su sąskaitomis. Matysite, kas apmokėta, o kas dar laukia."
          )
      },
      %{
        icon_name: "lucide-target",
        icon_bg: "bg-gradient-accent text-white",
        title: dgettext("home_live", "Klaidų aptikimas"),
        description:
          dgettext(
            "home_live",
            "Sistema iškart parodo, jei sąskaita neapmokėta, pasikartoja ar neatitinka mokėjimo."
          )
      },
      %{
        icon_name: "lucide-brain",
        icon_bg: "bg-gradient-primary text-white",
        title: dgettext("home_live", "Lengva pradėti"),
        description:
          dgettext(
            "home_live",
            "Jokių sudėtingų diegimų ar integracijų – užtenka įkelti banko išrašą ir sąskaitas."
          )
      }
    ]
  end

  defp testimonial_items() do
    [
      %{
        name: dgettext("home_live", "Andrius P."),
        job: dgettext("home_live", "Kavinės savininkas"),
        class: "-rotate-3 md:translate-y-8",
        icon: "🧑‍💼",
        text:
          dgettext(
            "home_live",
            "Kiekvieną mėnesį gaišdavau pusę dienos rinkdamas sąskaitas buhalterei. Dabar tiesiog persiunčiu jas Gobliui ir viskas sutvarkyta. Sutaupau daug nervų."
          )
      },
      %{
        name: dgettext("home_live", "Darius K."),
        job: dgettext("home_live", "Autoserviso vadovas"),
        class: nil,
        icon: "👨‍💻",
        text:
          dgettext(
            "home_live",
            "Mano darbas yra remontuoti automobilius, o ne ieškoti sąskaitų. Goblinas man padėjo viską sukaupti vienoje vietoje. Buhalterei siųsti tapo daug paprasčiau."
          )
      },
      %{
        name: dgettext("home_live", "Simona V."),
        job: dgettext("home_live", "Marketingo įmonės vadovė"),
        class: "rotate-3 md:translate-y-8",
        icon: "👩‍💼",
        text:
          dgettext(
            "home_live",
            "Mėnesio pabaigos man būdavo tikras galvos skausmas. Dabar tiesiog įkeliu banko išrašą, o goblinas pats sudėlioja, kas apmokėta, o ko dar trūksta."
          )
      }
    ]
  end
end
