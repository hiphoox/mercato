defmodule MercatoWeb.UI.FilterBarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.FilterBar

  defp slot(name, text) do
    [{name, [%{__slot__: name, inner_block: fn _, _ -> text end}]}]
  end

  defp render(fun, assigns), do: LazyHTML.from_fragment(render_component(fun, assigns))

  describe "the bar" do
    defp bar(extra \\ []) do
      render(
        &FilterBar.filter_bar/1,
        [id: "browse-filters"] ++ slot(:inner_block, "Controls") ++ extra
      )
    end

    test "renders the controls it is given" do
      assert bar() |> LazyHTML.text() =~ "Controls"
    end

    test "sticks to the top of the column it scrolls in" do
      assert bar() |> LazyHTML.query("#browse-filters") |> LazyHTML.attribute("class") |> hd() =~
               "sticky"
    end

    test "shows no chip row until something is applied" do
      assert bar() |> LazyHTML.query("#browse-filters-chips") |> Enum.empty?()
    end

    test "shows the applied filters when there are any" do
      chips = bar(slot(:chips, "Category: Bikes")) |> LazyHTML.query("#browse-filters-chips")

      assert LazyHTML.text(chips) =~ "Category: Bikes"
    end
  end

  describe "a menu of choices" do
    defp menu(assigns, extra \\ []) do
      defaults = [id: "sort", label: "Newest"]

      render(
        &FilterBar.filter_menu/1,
        Keyword.merge(defaults, assigns) ++ slot(:inner_block, "Options") ++ extra
      )
    end

    defp trigger(assigns \\ []), do: menu(assigns) |> LazyHTML.query("#sort-trigger")

    test "labels the pill with the value in force, not the facet's name" do
      assert trigger() |> LazyHTML.text() |> String.trim() =~ "Newest"
    end

    test "renders the choices in the panel" do
      assert menu([]) |> LazyHTML.query("#sort-panel") |> LazyHTML.text() =~ "Options"
    end

    test "stays black and white while it is doing nothing" do
      class = trigger() |> LazyHTML.attribute("class") |> hd()

      refute class =~ "bg-primary"
      assert class =~ "rounded-full"
    end

    test "inverts to solid ink once the facet is narrowing the grid" do
      class = trigger(active: true) |> LazyHTML.attribute("class") |> hd()

      assert class =~ "bg-ink-900"
      assert class =~ "border-[1.5px]"
    end

    test "is a menu of choices by default" do
      assert menu([]) |> LazyHTML.query("#sort-panel") |> LazyHTML.attribute("role") == ["menu"]
    end

    test "becomes a dialog when the panel is something to fill in rather than pick from" do
      panel = menu(role: "dialog", name: "Price range") |> LazyHTML.query("#sort-panel")

      assert LazyHTML.attribute(panel, "role") == ["dialog"]
      assert LazyHTML.attribute(panel, "aria-label") == ["Price range"]
    end
  end

  describe "an option row" do
    defp option(assigns) do
      render(&FilterBar.filter_option/1, Keyword.merge([label: "Newest"], assigns))
    end

    test "renders a button when it only reports a choice" do
      row = option([]) |> LazyHTML.query("button")

      assert LazyHTML.text(row) =~ "Newest"
      assert LazyHTML.attribute(row, "role") == ["menuitemradio"]
    end

    test "renders a link when choosing it goes somewhere" do
      row = option(patch: "/?category=bikes") |> LazyHTML.query("a")

      assert LazyHTML.attribute(row, "href") == ["/?category=bikes"]
      assert LazyHTML.attribute(row, "role") == ["menuitemradio"]
    end

    test "says whether it is the choice in force" do
      assert option([])
             |> LazyHTML.query("[role=menuitemradio]")
             |> LazyHTML.attribute("aria-checked") == ["false"]

      assert option(selected: true)
             |> LazyHTML.query("[role=menuitemradio]")
             |> LazyHTML.attribute("aria-checked") == ["true"]
    end

    test "marks the chosen row with a tick, so the state is not carried by weight alone" do
      assert option([]) |> LazyHTML.query(".hero-check") |> Enum.empty?()
      assert option(selected: true) |> LazyHTML.query(".hero-check") |> Enum.count() == 1
    end

    test "hides the tick from screen readers, which are told by aria-checked" do
      ticks = option(selected: true) |> LazyHTML.query(".hero-check")

      assert LazyHTML.attribute(ticks, "aria-hidden") == ["true"]
    end
  end

  describe "a bar button" do
    defp bar_button(assigns) do
      render(&FilterBar.filter_button/1, Keyword.merge([label: "All filters"], assigns))
    end

    test "wears the same pill as the menus beside it" do
      class = bar_button([]) |> LazyHTML.query("button") |> LazyHTML.attribute("class") |> hd()

      assert class =~ "rounded-full"
    end

    test "renders the icon it is given" do
      assert bar_button(icon: "hero-adjustments-horizontal")
             |> LazyHTML.query(".hero-adjustments-horizontal")
             |> Enum.count() == 1
    end

    test "passes a click through, since the bar does not know what it opens" do
      buttons = bar_button("phx-click": "open") |> LazyHTML.query("button")

      assert LazyHTML.attribute(buttons, "phx-click") == ["open"]
    end
  end
end
