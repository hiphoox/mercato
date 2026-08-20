defmodule MercatoWeb.Layouts.SidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.Layouts.Sidebar

  defp query(assigns, selector) do
    render_component(&Sidebar.sidebar/1, assigns)
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  describe "structure" do
    test "renders a navigation landmark" do
      assert [current_path: "/"] |> query("nav") |> LazyHTML.attribute("aria-label") == [
               "Main navigation"
             ]
    end

    test "links to the pages that exist today" do
      hrefs = [current_path: "/"] |> query("nav a") |> LazyHTML.attribute("href")

      assert "/" in hrefs
      assert "/profile" in hrefs
    end

    test "groups account links under a labelled section" do
      assert [current_path: "/"] |> query("#sidebar-section-you") |> LazyHTML.text() =~ "You"
    end
  end

  describe "admin section" do
    test "is absent for a user without admin access" do
      html = render_component(&Sidebar.sidebar/1, current_path: "/", admin?: false)

      refute html =~ "/admin/users"
    end

    test "links to the admin pages that exist today" do
      hrefs = [current_path: "/", admin?: true] |> query("nav a") |> LazyHTML.attribute("href")

      assert "/admin/users" in hrefs
    end

    test "groups admin links under a labelled section" do
      section =
        [current_path: "/", admin?: true] |> query("#sidebar-section-admin") |> LazyHTML.text()

      assert section =~ "Admin"
    end

    test "marks the admin entry active on its own page" do
      current = [current_path: "/admin/users", admin?: true] |> query("[aria-current=page]")

      assert LazyHTML.attribute(current, "href") == ["/admin/users"]
    end
  end

  describe "active item" do
    test "marks the item matching the current path" do
      current = [current_path: "/profile"] |> query("[aria-current=page]")

      assert LazyHTML.attribute(current, "href") == ["/profile"]
    end

    test "marks only one item at a time" do
      assert [current_path: "/profile"] |> query("[aria-current=page]") |> Enum.count() == 1
    end

    test "marks nothing when the path matches no nav item" do
      assert [current_path: "/somewhere-else"] |> query("[aria-current=page]") |> Enum.count() ==
               0
    end
  end

  describe "collapsed rail" do
    test "hides the section heading, which is meaningless next to bare icons" do
      heading = [current_path: "/"] |> query("#sidebar-section-you")

      assert LazyHTML.attribute(heading, "class") |> hd() =~ "sidebar-collapsed:hidden"
    end

    test "keeps each label available to screen readers when collapsed" do
      labels =
        [current_path: "/"]
        |> query("nav a span:not([aria-hidden])")
        |> LazyHTML.attribute("class")

      assert Enum.all?(labels, &(&1 =~ "sidebar-collapsed:sr-only"))
    end

    test "gives each row a tooltip, so a bare icon is still identifiable" do
      titles = [current_path: "/"] |> query("nav a") |> LazyHTML.attribute("title")

      assert "Profile" in titles
    end
  end

  # These assert the responsive wiring — which classes and handlers are emitted — not
  # that the drawer visually slides. The breakpoint behaviour itself is CSS, so only a
  # real browser at a real viewport can confirm it.
  describe "drawer below lg" do
    test "parks the sidebar off-canvas and slides it in on the open state" do
      class = [current_path: "/"] |> query("nav") |> LazyHTML.attribute("class") |> hd()

      assert class =~ "-translate-x-[calc(100%+1.5rem)]"
      assert class =~ "sidebar-drawer-open:translate-x-0"
    end

    test "returns the sidebar to the flow from lg up" do
      class = [current_path: "/"] |> query("nav") |> LazyHTML.attribute("class") |> hd()

      assert class =~ "lg:static"
      assert class =~ "lg:translate-x-0"
      assert class =~ "lg:w-58"
    end

    test "renders a scrim that is hidden once the sidebar is in flow" do
      class =
        [current_path: "/"] |> query("#sidebar-scrim") |> LazyHTML.attribute("class") |> hd()

      assert class =~ "lg:hidden"
      assert class =~ "sidebar-drawer-open:opacity-100"
    end

    test "closes the drawer when the scrim is clicked" do
      click =
        [current_path: "/"] |> query("#sidebar-scrim") |> LazyHTML.attribute("phx-click") |> hd()

      assert click =~ ~s(["data-sidebar-drawer","closed"])
    end

    test "closes the drawer on escape" do
      nav = [current_path: "/"] |> query("nav")

      assert LazyHTML.attribute(nav, "phx-key") == ["escape"]
      assert LazyHTML.attribute(nav, "phx-window-keydown") |> hd() =~ ~s("data-sidebar-drawer")
    end

    test "closes the drawer when a nav entry is followed" do
      # Otherwise the drawer would stay open over the page the user just navigated to.
      clicks = [current_path: "/"] |> query("nav a") |> LazyHTML.attribute("phx-click")

      assert Enum.count(clicks) == 2
      assert Enum.all?(clicks, &(&1 =~ ~s(["data-sidebar-drawer","closed"])))
    end
  end
end
