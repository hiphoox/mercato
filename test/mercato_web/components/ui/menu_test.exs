defmodule MercatoWeb.UI.MenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Menu

  defp item(assigns) do
    LazyHTML.from_fragment(render_component(&Menu.menu_item/1, assigns))
  end

  defp menu(assigns, block) do
    LazyHTML.from_fragment(render_component(&Menu.menu/1, assigns ++ block))
  end

  describe "menu_item as a link" do
    test "renders an anchor when given a navigate target" do
      hrefs =
        [label: "Profile", icon: "hero-user", navigate: "/profile"]
        |> item()
        |> LazyHTML.query("a")
        |> LazyHTML.attribute("href")

      assert hrefs == ["/profile"]
    end

    test "renders a button when there is no navigation target" do
      buttons = [label: "Log out"] |> item() |> LazyHTML.query("button")

      assert LazyHTML.attribute(buttons, "type") == ["button"]
    end

    test "renders no anchor when there is no navigation target" do
      assert [label: "Log out"] |> item() |> LazyHTML.query("a") |> Enum.count() == 0
    end

    test "passes through a phx-click so the caller controls the action" do
      buttons = [label: "Log out", "phx-click": "sign_out"] |> item() |> LazyHTML.query("button")

      assert LazyHTML.attribute(buttons, "phx-click") == ["sign_out"]
    end
  end

  describe "menu_item content" do
    test "renders the label" do
      assert [label: "Profile"] |> item() |> LazyHTML.text() |> String.trim() == "Profile"
    end

    test "renders the named heroicon" do
      icons = [label: "Profile", icon: "hero-user"] |> item() |> LazyHTML.query(".hero-user")

      assert Enum.count(icons) == 1
    end

    test "hides the icon from screen readers, since the label already names the item" do
      icons = [label: "Profile", icon: "hero-user"] |> item() |> LazyHTML.query(".hero-user")

      assert LazyHTML.attribute(icons, "aria-hidden") == ["true"]
    end

    test "renders no icon element when no icon is given" do
      assert [label: "Profile"] |> item() |> LazyHTML.query("span[class*=hero-]") |> Enum.count() ==
               0
    end
  end

  describe "menu_item active state" do
    test "marks the active item as the current page" do
      links =
        [label: "Profile", navigate: "/profile", active: true]
        |> item()
        |> LazyHTML.query("a")

      assert LazyHTML.attribute(links, "aria-current") == ["page"]
    end

    test "does not mark an inactive item" do
      links = [label: "Profile", navigate: "/profile"] |> item() |> LazyHTML.query("a")

      assert LazyHTML.attribute(links, "aria-current") == []
    end

    test "styles the active item with the primary tint" do
      class =
        [label: "Profile", navigate: "/profile", active: true]
        |> item()
        |> LazyHTML.query("a")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "bg-primary-050"
      assert class =~ "text-primary-700"
    end
  end

  describe "menu_item danger variant" do
    test "styles a destructive item with the error tokens" do
      class =
        [label: "Log out", variant: :danger]
        |> item()
        |> LazyHTML.query("button")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "text-error-text"
    end
  end

  describe "menu_item collapsed rail" do
    test "keeps the label available to screen readers when collapsed" do
      assert [label: "Profile", icon: "hero-user", collapsed: true]
             |> item()
             |> LazyHTML.query(".sr-only")
             |> LazyHTML.text()
             |> String.trim() == "Profile"
    end

    test "adds a tooltip so a sighted user can still identify the icon" do
      buttons = [label: "Profile", collapsed: true] |> item() |> LazyHTML.query("button")

      assert LazyHTML.attribute(buttons, "title") == ["Profile"]
    end

    test "does not hide the label when expanded" do
      assert [label: "Profile"] |> item() |> LazyHTML.query(".sr-only") |> Enum.count() == 0
    end
  end

  describe "menu popup" do
    defp slot(name, text) do
      [{name, [%{__slot__: name, inner_block: fn _, _ -> text end}]}]
    end

    defp slots, do: slot(:trigger, "Open") ++ slot(:inner_block, "Contents")

    defp user_menu(selector) do
      [id: "user-menu"] |> menu(slots()) |> LazyHTML.query(selector)
    end

    test "wires the trigger to the panel it controls" do
      trigger = user_menu("#user-menu-trigger")

      assert LazyHTML.attribute(trigger, "aria-controls") == ["user-menu-panel"]
    end

    test "announces the trigger as opening a menu" do
      trigger = user_menu("#user-menu-trigger")

      assert LazyHTML.attribute(trigger, "aria-haspopup") == ["menu"]
    end

    test "starts closed" do
      panel = user_menu("#user-menu-panel")

      assert LazyHTML.attribute(panel, "class") |> hd() =~ "hidden"
    end

    test "closes with a class, not the hidden attribute" do
      # Tailwind's preflight marks [hidden] as `display:none !important`, which beats
      # the inline display JS.toggle sets — the panel could never open.
      panel = user_menu("#user-menu-panel")

      assert LazyHTML.attribute(panel, "hidden") == []
    end

    test "opens the panel as a flex column, not the default block" do
      # The panel lays its rows out with flex-col; revealing it as display:block
      # would silently drop the column layout and the row gaps.
      click = user_menu("#user-menu-trigger") |> LazyHTML.attribute("phx-click") |> hd()

      assert click =~ ~s("display":"flex")
    end

    test "gives the panel a menu role" do
      panel = user_menu("#user-menu-panel")

      assert LazyHTML.attribute(panel, "role") == ["menu"]
    end

    test "closes when the user clicks elsewhere" do
      wrapper = user_menu("[phx-click-away]")

      assert Enum.count(wrapper) == 1
    end

    test "puts click-away on the wrapper, so opening it does not immediately close it" do
      # The trigger is outside the panel. A panel-scoped click-away would fire on
      # the same click that opens the menu, and it would never appear.
      assert user_menu("#user-menu-panel[phx-click-away]") |> Enum.empty?()
    end

    test "closes on escape" do
      panel = user_menu("#user-menu-panel")

      assert LazyHTML.attribute(panel, "phx-key") == ["escape"]
    end

    test "anchors the panel to its trigger, so it can be positioned outside a clipping ancestor" do
      # An absolutely-positioned panel is clipped by any scrolling ancestor —
      # the admin users table is one. The hook lifts it out; it needs to know
      # which element to measure against.
      panel = user_menu("#user-menu-panel")

      assert LazyHTML.attribute(panel, "phx-hook") == ["AnchoredPanel"]
      assert LazyHTML.attribute(panel, "data-anchor") == ["user-menu-trigger"]
    end

    test "carries the command that closes it once an item is chosen" do
      # Only the closest phx-click binding fires, so a click on an item never
      # reaches a handler on the panel — the panel publishes the close command
      # instead and the hook runs it.
      close = user_menu("#user-menu-panel") |> LazyHTML.attribute("data-close") |> hd()

      assert close =~ ~s("hide")
      assert close =~ "user-menu-panel"
      assert close =~ ~s("aria-expanded","false")
    end

    test "gives the trigger a raised surface by default" do
      trigger = user_menu("#user-menu-trigger") |> LazyHTML.attribute("class") |> hd()

      assert trigger =~ "shadow-sm"
    end

    test "replaces the trigger's chrome outright when the caller supplies its own" do
      # Two conflicting Tailwind utilities on one element resolve by stylesheet
      # order, not attribute order, so the default cannot merely be appended to.
      trigger =
        [id: "user-menu", trigger_class: "hover:bg-bg-2"]
        |> menu(slots())
        |> LazyHTML.query("#user-menu-trigger")
        |> LazyHTML.attribute("class")
        |> hd()

      assert trigger =~ "hover:bg-bg-2"
      refute trigger =~ "shadow-sm"
    end

    test "renders the trigger and panel slots" do
      html = [id: "user-menu"] |> menu(slots()) |> LazyHTML.text()

      assert html =~ "Open"
      assert html =~ "Contents"
    end
  end
end
