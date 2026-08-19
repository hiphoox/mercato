defmodule MercatoWeb.UI.BreadcrumbTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Breadcrumb

  @trail [
    %{label: "Home", navigate: "/"},
    %{label: "Marketplace", navigate: "/marketplace"},
    %{label: "Furniture"}
  ]

  defp document(assigns) do
    LazyHTML.from_fragment(render_component(&Breadcrumb.breadcrumb/1, assigns))
  end

  defp query(assigns, selector) do
    assigns |> document() |> LazyHTML.query(selector)
  end

  describe "structure" do
    test "renders a landmark labelled for screen readers" do
      nav = query([items: @trail], "nav")

      assert LazyHTML.attribute(nav, "aria-label") == ["Breadcrumb"]
    end

    test "renders an ordered list, since the trail's order carries meaning" do
      assert [items: @trail] |> query("nav ol") |> Enum.count() == 1
    end

    test "renders one list item per crumb" do
      assert [items: @trail] |> query("nav ol > li") |> Enum.count() == 3
    end
  end

  describe "links" do
    test "renders a link for each crumb before the last" do
      hrefs = [items: @trail] |> query("nav a") |> LazyHTML.attribute("href")

      assert hrefs == ["/", "/marketplace"]
    end

    test "does not link the final crumb, which is the page you are already on" do
      links = [items: @trail] |> query("nav a")

      refute LazyHTML.text(links) =~ "Furniture"
    end

    test "marks the final crumb as the current page" do
      current = query([items: @trail], "[aria-current=page]")

      assert LazyHTML.text(current) |> String.trim() == "Furniture"
    end

    test "does not link a crumb that has no navigate target" do
      items = [%{label: "Home", navigate: "/"}, %{label: "Orphan"}, %{label: "Here"}]
      hrefs = [items: items] |> query("nav a") |> LazyHTML.attribute("href")

      assert hrefs == ["/"]
    end
  end

  describe "separators" do
    test "renders one fewer separator than there are crumbs" do
      assert [items: @trail] |> query("[data-role=separator]") |> Enum.count() == 2
    end

    test "hides separators from screen readers, which read the list structure instead" do
      separators = query([items: @trail], "[data-role=separator]")

      assert LazyHTML.attribute(separators, "aria-hidden") == ["true", "true"]
    end

    test "renders no separator for a single crumb" do
      assert [items: [%{label: "Home"}]] |> query("[data-role=separator]") |> Enum.count() == 0
    end
  end

  describe "empty trail" do
    test "renders nothing at all rather than an empty nav landmark" do
      assert [items: []] |> query("nav") |> Enum.count() == 0
    end
  end
end
