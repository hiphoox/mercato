defmodule MercatoWeb.Layouts.AppHeaderTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Mercato.Accounts.Scope
  alias MercatoWeb.Layouts.AppHeader

  @user %Mercato.Accounts.User{
    first_name: "Jane",
    last_name: "Doe",
    email: "jane@mercato.app",
    avatar_url: nil
  }

  defp query(assigns, selector) do
    assigns = Keyword.put_new(assigns, :current_scope, %Scope{})

    render_component(&AppHeader.app_header/1, assigns)
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  describe "admin indicator" do
    test "marks an admin in the header itself, not only inside the account menu" do
      assert [current_scope: %Scope{user: @user, admin?: true}]
             |> query("#admin-indicator")
             |> LazyHTML.text() =~ "Admin"
    end

    test "is absent for a non-admin" do
      assert [current_scope: %Scope{user: @user}] |> query("#admin-indicator") |> Enum.empty?()
    end

    test "is absent when the caller says nothing about admin access" do
      assert [current_scope: %Scope{user: @user}] |> query("#admin-indicator") |> Enum.empty?()
    end

    test "is absent for a signed-out visitor" do
      assert [current_scope: %Scope{}] |> query("#admin-indicator") |> Enum.empty?()
    end
  end

  @categories [
    %Mercato.Listings.Category{name: "Electronics", slug: "electronics"},
    %Mercato.Listings.Category{name: "Fashion", slug: "fashion"}
  ]

  describe "category scope" do
    test "offers the catalog, plus a way to search across all of it" do
      options = [categories: @categories] |> query("#app-search-scope option")

      assert LazyHTML.attribute(options, "value") == ["", "electronics", "fashion"]
      assert LazyHTML.text(options) =~ "All categories"
    end

    test "names each category the way a person reads it, not by its slug" do
      assert [categories: @categories]
             |> query(~s{#app-search-scope option[value="electronics"]})
             |> LazyHTML.text()
             |> String.trim() == "Electronics"
    end

    test "marks the scope in force, so a search does not blank its own filter" do
      assert [categories: @categories, category: "fashion"]
             |> query("#app-search-scope option[selected]")
             |> LazyHTML.attribute("value") == ["fashion"]
    end

    test "falls back to all categories when none is in force" do
      assert [categories: @categories]
             |> query("#app-search-scope option[selected]")
             |> LazyHTML.attribute("value") == [""]
    end

    test "submits alongside the term rather than as a control of its own" do
      assert [categories: @categories]
             |> query(~s{form[role="search"] select[name="category"]})
             |> Enum.count() == 1
    end

    test "names itself for screen readers" do
      assert [categories: @categories]
             |> query("#app-search-scope")
             |> LazyHTML.attribute("aria-label") == ["Search within"]
    end

    test "is left out when the caller names no catalog" do
      assert [current_scope: %Scope{}] |> query("#app-search-scope") |> Enum.empty?()
    end
  end

  describe "brand" do
    test "links the wordmark home" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#app-brand")
             |> LazyHTML.attribute("href") == ["/"]
    end

    test "renders the logo" do
      assert [current_scope: %Scope{user: @user}] |> query("#app-brand img") |> Enum.count() == 1
    end
  end

  describe "sidebar toggle" do
    test "is only rendered for signed-in users, who are the only ones with a sidebar" do
      assert [current_scope: %Scope{}] |> query("#sidebar-toggle") |> Enum.count() == 0
    end

    test "names itself for screen readers" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#sidebar-toggle")
             |> LazyHTML.attribute("aria-label") ==
               ["Toggle navigation"]
    end

    test "points at the sidebar it controls" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#sidebar-toggle")
             |> LazyHTML.attribute("aria-controls") == ["app-sidebar"]
    end

    test "meets the minimum touch target" do
      class =
        [current_scope: %Scope{user: @user}]
        |> query("#sidebar-toggle")
        |> LazyHTML.attribute("class")

      assert hd(class) =~ "size-11"
    end
  end

  describe "search" do
    test "renders a search input" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#app-search")
             |> LazyHTML.attribute("type") ==
               ["search"]
    end

    test "labels the input for screen readers, since the placeholder is not a label" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#app-search")
             |> LazyHTML.attribute("aria-label") ==
               ["Search listings"]
    end

    # A GET form, so a search started from any page lands on the browse grid —
    # the only page that knows what to do with a term.
    test "submits to the browse page" do
      form = [current_scope: %Scope{user: @user}] |> query("header > form")

      assert LazyHTML.attribute(form, "action") == ["/"]
      assert LazyHTML.attribute(form, "method") == ["get"]
    end

    test "names the field so the term arrives as a query parameter" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#app-search")
             |> LazyHTML.attribute("name") == ["q"]
    end

    test "carries a term already in force, so the box still reads it" do
      assert [current_scope: %Scope{user: @user}, query: "lounge chair"]
             |> query("#app-search")
             |> LazyHTML.attribute("value") == ["lounge chair"]
    end

    test "offers a submit control, so searching needs no keyboard" do
      assert [current_scope: %Scope{user: @user}]
             |> query("header > form button[type=submit]")
             |> LazyHTML.attribute("aria-label") == ["Search"]
    end

    test "searches for a signed-out visitor too, who has the most need of it" do
      assert [current_scope: %Scope{}] |> query("#app-search") |> Enum.empty?() == false
    end
  end

  describe "sell" do
    test "offers a signed-in trader a way to start a listing" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#sell-cta")
             |> LazyHTML.attribute("href") ==
               ["/listings/new"]
    end

    test "is the filled call to action, selling being what the bar is there to invite" do
      class =
        [current_scope: %Scope{user: @user}]
        |> query("#sell-cta")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "bg-primary-500"
      assert class =~ "text-white"
    end

    test "draws its look from the button vocabulary rather than restating it" do
      # Layout belongs to the wrapper, because a class given to the button
      # replaces its variant outright rather than adding to it.
      assert [current_scope: %Scope{user: @user}]
             |> query("#sell-cta")
             |> LazyHTML.attribute("class")
             |> hd() =~ "h-[52px]"
    end

    test "is hidden from signed-out visitors, who have nowhere to be sent" do
      assert [current_scope: %Scope{}] |> query("#sell-cta") |> Enum.empty?()
    end

    test "keeps its name for a screen reader at the width that drops it" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#sell-cta")
             |> LazyHTML.attribute("aria-label") ==
               ["Sell an item"]
    end

    test "shows its name from md up, where there is room for it" do
      # Not any span: the icon is one too, and it is hidden from readers rather
      # than from narrow screens.
      assert [current_scope: %Scope{user: @user}]
             |> query("#sell-cta span:not([aria-hidden])")
             |> LazyHTML.attribute("class") == ["hidden md:inline"]
    end
  end

  describe "cart" do
    test "is hidden from signed-out visitors, who have no cart" do
      assert [current_scope: %Scope{}] |> query("#app-cart") |> Enum.count() == 0
    end

    test "is shown to signed-in users" do
      assert [current_scope: %Scope{user: @user}] |> query("#app-cart") |> Enum.count() == 1
    end
  end

  describe "user menu" do
    test "is rendered for signed-in users" do
      assert [current_scope: %Scope{user: @user}] |> query("#user-menu-trigger") |> Enum.count() ==
               1
    end

    test "is rendered for signed-out visitors too, offering sign in" do
      hrefs = [current_scope: %Scope{}] |> query("[role=menu] a") |> LazyHTML.attribute("href")

      assert "/sign-in" in hrefs
    end
  end

  # Class-level assertions only: these prove the responsive utilities are emitted, not
  # that the bar reflows. Confirming the reflow needs a browser at a real viewport.
  describe "wrapping below md" do
    test "allows the bar to wrap, and stops it wrapping from md up" do
      class =
        [current_scope: %Scope{user: @user}]
        |> query("header")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "flex-wrap"
      assert class =~ "md:flex-nowrap"
    end

    test "drops search onto its own row, after the other controls" do
      wrapper =
        [current_scope: %Scope{user: @user}]
        |> query("header > form.grow")
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
        [current_scope: %Scope{user: @user}]
        |> query("header > div.order-2")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "ml-auto"
      assert class =~ "md:ml-0"
    end

    test "reserves the sidebar's width in the header only once the sidebar is in flow" do
      class =
        [current_scope: %Scope{user: @user}]
        |> query("header > div:first-child")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "lg:w-58"
      refute class =~ ~r/(?<!:)\bw-58\b/
    end
  end
end
