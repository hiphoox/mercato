defmodule MercatoWeb.Layouts.AppHeaderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.Layouts.AppHeader

  @user %Mercato.Accounts.User{
    first_name: "Jane",
    last_name: "Doe",
    email: "jane@mercato.app",
    avatar_url: nil
  }

  defp query(assigns, selector) do
    render_component(&AppHeader.app_header/1, assigns)
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  describe "brand" do
    test "links the wordmark home" do
      assert [current_user: @user] |> query("#app-brand") |> LazyHTML.attribute("href") == ["/"]
    end

    test "renders the logo" do
      assert [current_user: @user] |> query("#app-brand img") |> Enum.count() == 1
    end
  end

  describe "sidebar toggle" do
    test "is only rendered for signed-in users, who are the only ones with a sidebar" do
      assert [current_user: nil] |> query("#sidebar-toggle") |> Enum.count() == 0
    end

    test "names itself for screen readers" do
      assert [current_user: @user] |> query("#sidebar-toggle") |> LazyHTML.attribute("aria-label") ==
               ["Toggle navigation"]
    end

    test "points at the sidebar it controls" do
      assert [current_user: @user]
             |> query("#sidebar-toggle")
             |> LazyHTML.attribute("aria-controls") == ["app-sidebar"]
    end

    test "meets the minimum touch target" do
      class = [current_user: @user] |> query("#sidebar-toggle") |> LazyHTML.attribute("class")

      assert hd(class) =~ "size-11"
    end
  end

  describe "search" do
    test "renders a search input" do
      assert [current_user: @user] |> query("#app-search") |> LazyHTML.attribute("type") ==
               ["search"]
    end

    test "labels the input for screen readers, since the placeholder is not a label" do
      assert [current_user: @user] |> query("#app-search") |> LazyHTML.attribute("aria-label") ==
               ["Search listings"]
    end
  end

  describe "cart" do
    test "is hidden from signed-out visitors, who have no cart" do
      assert [current_user: nil] |> query("#app-cart") |> Enum.count() == 0
    end

    test "is shown to signed-in users" do
      assert [current_user: @user] |> query("#app-cart") |> Enum.count() == 1
    end
  end

  describe "user menu" do
    test "is rendered for signed-in users" do
      assert [current_user: @user] |> query("#user-menu-trigger") |> Enum.count() == 1
    end

    test "is rendered for signed-out visitors too, offering sign in" do
      hrefs = [current_user: nil] |> query("[role=menu] a") |> LazyHTML.attribute("href")

      assert "/sign-in" in hrefs
    end
  end

  # Class-level assertions only: these prove the responsive utilities are emitted, not
  # that the bar reflows. Confirming the reflow needs a browser at a real viewport.
  describe "wrapping below md" do
    test "allows the bar to wrap, and stops it wrapping from md up" do
      class = [current_user: @user] |> query("header") |> LazyHTML.attribute("class") |> hd()

      assert class =~ "flex-wrap"
      assert class =~ "md:flex-nowrap"
    end

    test "drops search onto its own row, after the other controls" do
      wrapper =
        [current_user: @user]
        |> query("header > div.grow")
        |> LazyHTML.attribute("class")
        |> hd()

      # basis-full forces the wrap; flex-1 would resolve basis to 0 and keep it inline.
      assert wrapper =~ "order-4"
      assert wrapper =~ "basis-full"
      assert wrapper =~ "md:basis-0"
      refute wrapper =~ "flex-1"
    end

    test "keeps the account control on the first row, pinned right" do
      class =
        [current_user: @user]
        |> query("header > div.order-2")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "ml-auto"
      assert class =~ "md:ml-0"
    end

    test "reserves the sidebar's width in the header only once the sidebar is in flow" do
      class =
        [current_user: @user]
        |> query("header > div:first-child")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "lg:w-58"
      refute class =~ ~r/(?<!:)\bw-58\b/
    end
  end
end
