defmodule MercatoWeb.UI.SheetTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Sheet
  alias Phoenix.LiveView.JS

  defp slot(name, text) do
    [{name, [%{__slot__: name, inner_block: fn _, _ -> text end}]}]
  end

  defp sheet(assigns, extra \\ []) do
    defaults = [id: "filters", title: "All filters"]

    LazyHTML.from_fragment(
      render_component(
        &Sheet.sheet/1,
        Keyword.merge(defaults, assigns) ++ slot(:inner_block, "Body") ++ extra
      )
    )
  end

  defp filters(selector, assigns \\ [], extra \\ []) do
    assigns |> sheet(extra) |> LazyHTML.query(selector)
  end

  describe "anatomy" do
    test "renders its contents" do
      assert sheet([]) |> LazyHTML.text() =~ "Body"
    end

    test "titles the panel with a heading, not loose text" do
      assert filters("#filters-title") |> LazyHTML.text() |> String.trim() == "All filters"
    end

    test "names the dialog after that heading" do
      assert filters("[role=dialog]") |> LazyHTML.attribute("aria-labelledby") == [
               "filters-title"
             ]
    end

    test "traps the page behind it, so what is underneath is not read out" do
      assert filters("[role=dialog]") |> LazyHTML.attribute("aria-modal") == ["true"]
    end

    test "renders a footer only when given one" do
      assert filters("#filters-footer") |> Enum.empty?()

      assert filters("#filters-footer", [], slot(:footer, "Apply")) |> LazyHTML.text() =~ "Apply"
    end
  end

  describe "opening and closing" do
    test "starts closed" do
      assert filters("#filters") |> LazyHTML.attribute("class") |> hd() =~ "hidden"
    end

    test "closes with a class, not the hidden attribute" do
      # Tailwind's preflight marks [hidden] as `display:none !important`, which
      # beats the inline display JS.show sets — the sheet could never open.
      assert filters("#filters") |> LazyHTML.attribute("hidden") == []
    end

    test "opens as a flex row, so the panel can be pinned to an edge" do
      assert Jason.encode!(Sheet.show_sheet("filters")) =~ ~s("display":"flex")
    end

    test "closes on escape" do
      assert filters("#filters") |> LazyHTML.attribute("phx-key") == ["escape"]
    end

    test "closes when the scrim behind it is clicked" do
      click = filters("#filters-scrim") |> LazyHTML.attribute("phx-click") |> hd()

      assert click =~ ~s("hide")
      assert click =~ "filters"
    end

    test "closes from its own dismiss button" do
      assert filters("#filters-close") |> LazyHTML.attribute("phx-click") |> hd() =~ ~s("hide")
    end

    test "names the dismiss button, since its icon is hidden from screen readers" do
      assert filters("#filters-close") |> LazyHTML.attribute("aria-label") != []
    end
  end

  describe "a sheet the server opens" do
    test "starts hidden, since a sheet is closed until something opens it" do
      assert filters("#filters") |> LazyHTML.attribute("class") |> to_string() =~ "hidden"
    end

    test "tells the server it was closed when the caller asks to be told" do
      told = JS.push(%JS{}, "close")
      closer = filters("#filters-close", open: true, on_close: told)

      assert closer |> LazyHTML.attribute("phx-click") |> to_string() =~ "close"
    end

    test "starts open when the server says it is, so a refused save keeps its form on screen" do
      class = filters("#filters", open: true) |> LazyHTML.attribute("class") |> to_string()

      refute class =~ "hidden"
      assert class =~ "flex"
    end
  end
end
