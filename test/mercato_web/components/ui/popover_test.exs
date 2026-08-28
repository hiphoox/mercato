defmodule MercatoWeb.UI.PopoverTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Popover

  defp slot(name, text) do
    [{name, [%{__slot__: name, inner_block: fn _, _ -> text end}]}]
  end

  defp slots, do: slot(:trigger, "Open") ++ slot(:inner_block, "Contents")

  defp popover(assigns) do
    LazyHTML.from_fragment(render_component(&Popover.popover/1, assigns ++ slots()))
  end

  defp sort(selector, assigns \\ []) do
    [id: "sort"] |> Keyword.merge(assigns) |> popover() |> LazyHTML.query(selector)
  end

  describe "anatomy" do
    test "renders both slots" do
      html = [id: "sort"] |> popover() |> LazyHTML.text()

      assert html =~ "Open"
      assert html =~ "Contents"
    end

    test "wires the trigger to the panel it controls" do
      assert sort("#sort-trigger") |> LazyHTML.attribute("aria-controls") == ["sort-panel"]
    end

    test "starts closed" do
      assert sort("#sort-panel") |> LazyHTML.attribute("class") |> hd() =~ "hidden"
    end

    test "closes with a class, not the hidden attribute" do
      # Tailwind's preflight marks [hidden] as `display:none !important`, which beats
      # the inline display JS.toggle sets — the panel could never open.
      assert sort("#sort-panel") |> LazyHTML.attribute("hidden") == []
    end

    test "opens the panel as a flex column, not the default block" do
      click = sort("#sort-trigger") |> LazyHTML.attribute("phx-click") |> hd()

      assert click =~ ~s("display":"flex")
    end
  end

  describe "dismissal" do
    test "closes when the user clicks elsewhere" do
      assert sort("[phx-click-away]") |> Enum.count() == 1
    end

    test "puts click-away on the wrapper, so opening it does not immediately close it" do
      assert sort("#sort-panel[phx-click-away]") |> Enum.empty?()
    end

    test "closes on escape" do
      assert sort("#sort-panel") |> LazyHTML.attribute("phx-key") == ["escape"]
    end

    test "carries the command that closes it once a choice is made" do
      close = sort("#sort-panel") |> LazyHTML.attribute("data-close") |> hd()

      assert close =~ ~s("hide")
      assert close =~ "sort-panel"
      assert close =~ ~s("aria-expanded","false")
    end
  end

  describe "positioning" do
    test "anchors the panel to its trigger, so a clipping ancestor cannot cut it off" do
      panel = sort("#sort-panel")

      assert LazyHTML.attribute(panel, "phx-hook") == ["AnchoredPanel"]
      assert LazyHTML.attribute(panel, "data-anchor") == ["sort-trigger"]
    end

    test "hangs the panel off the trigger's right edge by default" do
      assert sort("#sort-panel") |> LazyHTML.attribute("data-align") == ["right"]
    end

    test "hangs it off the left edge when asked, for a control read left to right" do
      assert sort("#sort-panel", align: "left") |> LazyHTML.attribute("data-align") == ["left"]
    end
  end

  describe "role" do
    test "is a menu by default, and says so on the trigger" do
      assert sort("#sort-panel") |> LazyHTML.attribute("role") == ["menu"]
      assert sort("#sort-trigger") |> LazyHTML.attribute("aria-haspopup") == ["menu"]
    end

    test "becomes a dialog when its contents are not a list of choices" do
      assert sort("#sort-panel", role: "dialog") |> LazyHTML.attribute("role") == ["dialog"]

      assert sort("#sort-trigger", role: "dialog") |> LazyHTML.attribute("aria-haspopup") ==
               ["dialog"]
    end

    test "names the panel after its trigger, so the popup is announced with it" do
      assert sort("#sort-panel") |> LazyHTML.attribute("aria-labelledby") == ["sort-trigger"]
    end

    test "takes a label of its own when the trigger's text is not the whole story" do
      panel = sort("#sort-panel", label: "Price range")

      assert LazyHTML.attribute(panel, "aria-label") == ["Price range"]
      assert LazyHTML.attribute(panel, "aria-labelledby") == []
    end
  end

  describe "the trigger's chrome" do
    test "is a raised surface by default" do
      assert sort("#sort-trigger") |> LazyHTML.attribute("class") |> hd() =~ "shadow-sm"
    end

    test "is replaced outright when the caller supplies its own" do
      # Two conflicting Tailwind utilities on one element resolve by stylesheet
      # order, not attribute order, so the default cannot merely be appended to.
      class =
        sort("#sort-trigger", trigger_class: "hover:bg-bg-2")
        |> LazyHTML.attribute("class")
        |> hd()

      assert class =~ "hover:bg-bg-2"
      refute class =~ "shadow-sm"
    end
  end
end
