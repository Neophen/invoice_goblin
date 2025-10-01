defmodule InvoiceGoblinWeb.HomeLive do
  use InvoiceGoblinWeb, :live_view
  alias UI.Components.Layout

  on_mount {InvoiceGoblinWeb.LiveUserAuth, :live_no_user}

  @impl LiveView
  def render(assigns) do
    ~H"""
    <Flash.group flash={@flash} />

    <.hero />
    """
  end

  @impl LiveView
  def mount(_params, _session, socket) do
    socket
    |> assign(:form, to_form(%{}, as: "waitlist"))
    |> assign(:email, "")
    |> assign(:submitted, false)
    |> assign(:error, nil)
    |> assign(:current_scope, nil)
    |> ok()
  end

  @impl LiveView
  def handle_event("validate", %{"waitlist" => %{"email" => email}}, socket) do
    socket
    |> assign(:email, email)
    |> noreply()
  end

  @impl LiveView
  def handle_event("submit", %{"waitlist" => %{"email" => email}}, socket) do
    case Ash.create(InvoiceGoblin.Accounts.Waitlist, %{email: email}) do
      {:ok, _waitlist_entry} ->
        socket
        |> assign(:submitted, true)
        |> assign(:error, nil)
        |> put_flash(:info, "Thanks! You've been added to our waitlist.")
        |> noreply()

      {:error, error} ->
        case error do
          %{errors: [%{field: :email, message: "has already been taken"}]} ->
            socket
            |> assign(:submitted, true)
            |> assign(:error, nil)
            |> put_flash(:info, "You're already on our waitlist!")
            |> noreply()

          %{errors: [%{field: :email, message: message}]} ->
            socket
            |> assign(:error, message)
            |> noreply()

          _ ->
            socket
            |> assign(:error, "Something went wrong. Please try again.")
            |> noreply()
        end
    end
  end

  def notify_me(assigns) do
    ~H"""
    <div class="bg-gray-900 py-16 sm:py-24">
      <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
        <div class="relative isolate flex flex-col gap-10 overflow-hidden bg-gray-800 px-6 py-24 after:pointer-events-none after:absolute after:inset-0 after:inset-ring after:inset-ring-white/15 sm:rounded-3xl sm:px-24 after:sm:rounded-3xl xl:flex-row xl:items-center xl:py-32">
          <h2 class="max-w-xl text-3xl font-semibold tracking-tight text-balance text-white sm:text-4xl xl:flex-auto">
            Want our product updates? Sign up for our newsletter.
          </h2>
          <form class="w-full max-w-md">
            <div class="flex gap-x-4">
              <label for="email-address" class="sr-only">Email address</label>
              <input
                id="email-address"
                type="email"
                name="email"
                required
                placeholder="Enter your email"
                autocomplete="email"
                class="min-w-0 flex-auto rounded-md bg-white/5 px-3.5 py-2 text-base text-white outline-1 -outline-offset-1 outline-white/20 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-500 sm:text-sm/6"
              />
              <button
                type="submit"
                class="flex-none rounded-md bg-white/90 px-3.5 py-2.5 text-sm font-semibold text-gray-900 hover:bg-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
              >
                Notify me
              </button>
            </div>
            <p class="mt-4 text-sm/6 text-gray-300">
              We care about your data. Read our <a
                href="#"
                class="font-semibold whitespace-nowrap text-white hover:text-gray-200"
              >privacy policy</a>.
            </p>
          </form>
          <svg
            viewBox="0 0 1024 1024"
            aria-hidden="true"
            class="absolute top-1/2 left-1/2 -z-10 size-256 -translate-x-1/2"
          >
            <circle
              r="512"
              cx="512"
              cy="512"
              fill="url(#759c1415-0410-454c-8f7c-9a820de03641)"
              fill-opacity="0.7"
            />
            <defs>
              <radialGradient
                id="759c1415-0410-454c-8f7c-9a820de03641"
                r="1"
                cx="0"
                cy="0"
                gradientUnits="userSpaceOnUse"
                gradientTransform="translate(512 512) rotate(90) scale(512)"
              >
                <stop stop-color="#7775D6" />
                <stop offset="1" stop-color="#E935C1" stop-opacity="0" />
              </radialGradient>
            </defs>
          </svg>
        </div>
      </div>
    </div>
    """
  end

  def hero(assigns) do
    ~H"""
    <div class="relative isolate overflow-hidden bg-white min-h-svh">
      <svg
        aria-hidden="true"
        class="absolute inset-0 -z-10 size-full mask-[radial-gradient(100%_100%_at_top_right,white,transparent)] stroke-gray-200"
      >
        <defs>
          <pattern
            id="983e3e4c-de6d-4c3f-8d64-b9761d1534cc"
            width="200"
            height="200"
            x="50%"
            y="-1"
            patternUnits="userSpaceOnUse"
          >
            <path d="M.5 200V.5H200" fill="none" />
          </pattern>
        </defs>
        <svg x="50%" y="-1" class="overflow-visible fill-gray-50">
          <path
            d="M-200 0h201v201h-201Z M600 0h201v201h-201Z M-400 600h201v201h-201Z M200 800h201v201h-201Z"
            stroke-width="0"
          />
        </svg>
        <rect
          width="100%"
          height="100%"
          fill="url(#983e3e4c-de6d-4c3f-8d64-b9761d1534cc)"
          stroke-width="0"
        />
      </svg>
      <div
        aria-hidden="true"
        class="absolute top-10 left-[calc(50%-4rem)] -z-10 transform-gpu blur-3xl sm:left-[calc(50%-18rem)] lg:top-[calc(50%-30rem)] lg:left-48 xl:left-[calc(50%-24rem)]"
      >
        <div
          style="clip-path: polygon(73.6% 51.7%, 91.7% 11.8%, 100% 46.4%, 97.4% 82.2%, 92.5% 84.9%, 75.7% 64%, 55.3% 47.5%, 46.5% 49.4%, 45% 62.9%, 50.3% 87.2%, 21.3% 64.1%, 0.1% 100%, 5.4% 51.1%, 21.4% 63.9%, 58.9% 0.2%, 73.6% 51.7%)"
          class="aspect-1108/632 w-277 bg-linear-to-r from-[#80caff] to-[#4f46e5] opacity-20"
        >
        </div>
      </div>
      <div class="mx-auto max-w-7xl px-6 pt-10 pb-24 sm:pb-32 lg:flex lg:px-8 lg:py-40">
        <div class="mx-auto max-w-2xl shrink-0 lg:mx-0 lg:pt-8">
          <img
            src="https://tailwindcss.com/plus-assets/img/logos/mark.svg?color=indigo&shade=600"
            alt="Your Company"
            class="h-11"
          />
          <div class="mt-24 sm:mt-32 lg:mt-16">
            <a href="#" class="inline-flex space-x-6">
              <span class="rounded-full bg-indigo-50 px-3 py-1 text-sm/6 font-semibold text-indigo-600 ring-1 ring-indigo-600/20 ring-inset">
                What's new
              </span>
              <span class="inline-flex items-center space-x-2 text-sm/6 font-medium text-gray-600">
                <span>Just shipped v1.0</span>
                <svg
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  data-slot="icon"
                  aria-hidden="true"
                  class="size-5 text-gray-400"
                >
                  <path
                    d="M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z"
                    clip-rule="evenodd"
                    fill-rule="evenodd"
                  />
                </svg>
              </span>
            </a>
          </div>
          <h1 class="mt-10 text-5xl font-semibold tracking-tight text-pretty text-gray-900 sm:text-7xl">
            Be the first to try Invoice Goblin!
          </h1>
          <p class="mt-8 text-lg font-medium text-pretty text-gray-500 sm:text-xl/8">
            Effortlessly match your bank statements to invoices and receipts. Save time, reduce errors, and streamline your finances. Sign up now to get early access.
          </p>
          <div class="mt-10 flex items-center gap-x-6">
            <form class="w-full max-w-md">
              <div class="flex gap-x-4">
                <%!-- field={@form[:email]} --%>
                <UIForm.input
                  type="email"
                  name="email"
                  required
                  value=""
                  placeholder="Enter your email"
                  autocomplete="email"
                />
                <Action.button>Notify me</Action.button>
              </div>
              <p class="mt-4 text-sm/6 text-primary">
                We care about your data. Read our <a
                  href="#"
                  class="font-semibold whitespace-nowrap text-primary hover:text-primary"
                >privacy policy</a>.
              </p>
            </form>
          </div>
        </div>
        <div class="mx-auto mt-16 flex max-w-2xl sm:mt-24 lg:mt-0 lg:mr-0 lg:ml-10 lg:max-w-none lg:flex-none xl:ml-32">
          <div class="max-w-3xl flex-none sm:max-w-5xl lg:max-w-none">
            <img
              width="2432"
              height="1442"
              src="https://tailwindcss.com/plus-assets/img/component-images/project-app-screenshot.png"
              alt="App screenshot"
              class="w-304 rounded-md bg-gray-50 shadow-xl ring-1 ring-primary/10"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
