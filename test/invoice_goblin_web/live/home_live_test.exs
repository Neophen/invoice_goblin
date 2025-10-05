defmodule InvoiceGoblinWeb.HomeLiveTest do
  use InvoiceGoblinWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "mount with default locale (English)" do
    test "renders the home page with English translations", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      # Check English text appears
      assert html =~ "Forget invoice hunting, the goblin"
      assert html =~ "will find everything for you"
      assert html =~ "Enter your email"
      assert html =~ "Summon the Goblin"
    end
  end

  describe "mount with Lithuanian locale" do
    test "renders the home page with Lithuanian translations when locale is in session", %{
      conn: conn
    } do
      # Set Lithuanian locale by putting the Accept-Language header
      # which the Cldr.Plug.PutLocale will pick up
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, html} = live(conn, ~p"/")

      # Check Lithuanian text appears
      assert html =~ "Pamirškite sąskaitų medžioklę, goblinas"
      assert html =~ "viską suras už jus"
      assert html =~ "Įveskite savo el. paštą"
      assert html =~ "Iškviesti Gobliną"

      # Verify English text does NOT appear
      refute html =~ "Forget invoice hunting, the goblin"
      refute html =~ "will find everything for you"
      refute html =~ "Summon the Goblin"
    end

    test "renders 'How it works' section in Lithuanian", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, html} = live(conn, ~p"/")

      # Check Lithuanian section headers
      assert html =~ "Kaip tai"
      assert html =~ "veikia"

      # Check Lithuanian step descriptions
      assert html =~ "1. Įkelkite sąskaitas ir banko išrašą"
      assert html =~ "2. Goblinas viską sulygina"
      assert html =~ "3. Suranda praleistas sąskaitas"
    end

    test "renders 'Why InvoiceGoblin?' section in Lithuanian", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, html} = live(conn, ~p"/")

      # Check Lithuanian feature titles
      assert html =~ "Kodėl"
      assert html =~ "Visos sąskaitos vienoje vietoje"
      assert html =~ "Automatinis sąskaitų patikrinimas"
      assert html =~ "Klaidų aptikimas"
      assert html =~ "Lengva pradėti"
    end

    test "renders testimonials in Lithuanian", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, html} = live(conn, ~p"/")

      # Check Lithuanian testimonial content
      assert html =~ "Verslų patirtys"
      assert html =~ "su Goblinu"
      assert html =~ "Kavinės savininkas"
      assert html =~ "Autoserviso vadovas"
      assert html =~ "Marketingo įmonės vadovė"
    end

    test "renders CTA section in Lithuanian", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, html} = live(conn, ~p"/")

      # Check Lithuanian CTA text
      assert html =~ "Leiskite"
      assert html =~ "Gobliui"
      assert html =~ "sutvarkyti visas sąskaitas"
      assert html =~ "Gauti ankstyvą prieigą"
      assert html =~ "Išbandykite nemokamai"
      assert html =~ "Ankstyvųjų naudotojų privilegijos"
    end
  end

  describe "form submission" do
    test "shows success message in Lithuanian when email is submitted", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, _html} = live(conn, ~p"/")

      # Submit the form with a valid email
      view
      |> form("#hero-form", %{
        "form" => %{"email" => "test@example.com"},
        "location" => "hero"
      })
      |> render_submit()

      # Check for Lithuanian success message
      assert render(view) =~ "Ačiū! Buvote įtrauktas į mūsų laukiančiųjų sąrašą."
    end

    test "shows already registered message in Lithuanian", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, _html} = live(conn, ~p"/")

      # Submit the form with an email that's already on the waitlist
      # First submission
      view
      |> form("#hero-form", %{
        "form" => %{"email" => "duplicate@example.com"},
        "location" => "hero"
      })
      |> render_submit()

      # Get a new view and submit the same email again
      {:ok, view2, _html} = live(conn, ~p"/")

      view2
      |> form("#hero-form", %{
        "form" => %{"email" => "duplicate@example.com"},
        "location" => "hero"
      })
      |> render_submit()

      # Check for Lithuanian "already on waitlist" message
      assert render(view2) =~ "Jūs jau esate mūsų laukiančiųjų sąraše!"
    end
  end

  describe "locale persistence" do
    test "maintains Lithuanian locale across page interactions", %{conn: conn} do
      conn = Plug.Conn.put_req_header(conn, "accept-language", "lt")

      {:ok, view, _html} = live(conn, ~p"/")

      # Interact with the form (validation)
      html =
        view
        |> form("#hero-form", %{"form" => %{"email" => "test"}})
        |> render_change()

      # Verify Lithuanian text is still present
      assert html =~ "Įveskite savo el. paštą"

      # Submit the form
      view
      |> form("#hero-form", %{
        "form" => %{"email" => "test@example.com"},
        "location" => "hero"
      })
      |> render_submit()

      # Verify Lithuanian success message
      assert render(view) =~ "Ačiū! Buvote įtrauktas į mūsų laukiančiųjų sąrašą."
    end
  end
end
