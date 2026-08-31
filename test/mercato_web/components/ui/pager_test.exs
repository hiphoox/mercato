defmodule MercatoWeb.UI.PagerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Pager

  defp assigns(overrides) do
    Keyword.merge([page: 1, pages: 5, path: &"/?page=#{&1}"], overrides)
  end

  defp document(overrides) do
    LazyHTML.from_fragment(render_component(&Pager.pager/1, assigns(overrides)))
  end

  defp query(overrides, selector) do
    overrides |> document() |> LazyHTML.query(selector)
  end

  defp labels(overrides, selector) do
    overrides |> query(selector) |> LazyHTML.text() |> String.split()
  end

  describe "structure" do
    test "renders a landmark labelled for screen readers" do
      assert [] |> query("nav") |> LazyHTML.attribute("aria-label") == ["Pagination"]
    end

    test "renders nothing when everything fits on one page" do
      assert render_component(&Pager.pager/1, assigns(pages: 1)) |> String.trim() == ""
    end

    test "renders nothing when there is nothing to page at all" do
      assert render_component(&Pager.pager/1, assigns(pages: 0)) |> String.trim() == ""
    end
  end

  describe "the current page" do
    test "marks the page in force for screen readers" do
      assert [page: 3] |> query("[aria-current='page']") |> LazyHTML.text() |> String.trim() ==
               "3"
    end

    test "marks exactly one page as current" do
      assert [page: 3] |> query("[aria-current='page']") |> Enum.count() == 1
    end

    test "does not link the page already being read" do
      assert [page: 3] |> query("a[aria-current='page']") |> Enum.count() == 0
    end
  end

  describe "page links" do
    test "builds each link from the given path" do
      hrefs = [page: 1, pages: 3] |> query("nav a") |> LazyHTML.attribute("href")

      assert "/?page=2" in hrefs
      assert "/?page=3" in hrefs
    end

    test "offers every page when they all fit" do
      assert labels([page: 1, pages: 5], "nav [data-role='page']") == ~w(1 2 3 4 5)
    end
  end

  describe "elision" do
    test "leaves out the stretch a long run would draw" do
      shown = labels([page: 1, pages: 40], "nav [data-role='page']")

      assert length(shown) < 40
      assert "1" in shown
      assert "40" in shown
    end

    test "keeps the pages either side of the one being read" do
      shown = labels([page: 20, pages: 40], "nav [data-role='page']")

      assert "19" in shown
      assert "20" in shown
      assert "21" in shown
    end

    test "marks the gap it left, rather than running the numbers together" do
      assert [page: 20, pages: 40] |> query("nav [data-role='gap']") |> Enum.count() == 2
    end

    test "leaves no gap where the run is unbroken" do
      assert [page: 1, pages: 5] |> query("nav [data-role='gap']") |> Enum.count() == 0
    end
  end

  describe "the range on the page" do
    test "says nothing about a range when it was given no total" do
      assert [] |> query("[data-role='summary']") |> Enum.count() == 0
    end

    test "states the range the page covers" do
      text = [total: 120, page_size: 24] |> query("[data-role='summary']") |> LazyHTML.text()

      assert text =~ "1"
      assert text =~ "24"
      assert text =~ "120"
    end

    test "counts the range from the page being read" do
      text =
        [page: 2, total: 120, page_size: 24] |> query("[data-role='summary']") |> LazyHTML.text()

      assert text =~ "25"
      assert text =~ "48"
    end

    test "stops the range at the total rather than at a full page" do
      text =
        [page: 5, pages: 5, total: 110, page_size: 24]
        |> query("[data-role='summary']")
        |> LazyHTML.text()

      assert text =~ "110"
      refute text =~ "120"
    end

    test "announces a change of range, since the rows below it change with no warning" do
      summary = [total: 120, page_size: 24] |> query("[data-role='summary']")

      assert LazyHTML.attribute(summary, "aria-live") == ["polite"]
    end

    test "still states the range where everything fits on one page" do
      assert [pages: 1, total: 3, page_size: 24]
             |> query("[data-role='summary']")
             |> Enum.count() == 1
    end

    test "offers no controls where everything fits on one page" do
      assert [pages: 1, total: 3, page_size: 24]
             |> query("[data-role='page'], [data-role='next'], [data-role='prev']")
             |> Enum.count() == 0
    end

    test "renders nothing at all when there is nothing to count and nowhere to go" do
      html = render_component(&Pager.pager/1, assigns(pages: 0, total: 0, page_size: 24))

      assert String.trim(html) == ""
    end
  end

  describe "previous and next" do
    test "links onward from the first page" do
      assert [page: 1, pages: 5] |> query("a[data-role='next']") |> Enum.count() == 1
    end

    test "offers no way back from the first page" do
      assert [page: 1, pages: 5] |> query("a[data-role='prev']") |> Enum.count() == 0
    end

    test "offers no way onward from the last page" do
      assert [page: 5, pages: 5] |> query("a[data-role='next']") |> Enum.count() == 0
    end

    test "links back from the last page" do
      hrefs = [page: 5, pages: 5] |> query("a[data-role='prev']") |> LazyHTML.attribute("href")

      assert hrefs == ["/?page=4"]
    end

    test "still draws an unavailable end as a disabled control, not a hole" do
      disabled = [page: 1, pages: 5] |> query("[data-role='prev']")

      assert LazyHTML.attribute(disabled, "aria-disabled") == ["true"]
    end
  end
end
