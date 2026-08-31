defmodule MercatoWeb.UI.ListingCardTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.ListingCard

  @base %{id: "listing-1", title: "Eames-style lounge chair", price: "$420.00"}

  defp document(overrides) do
    render_component(&ListingCard.listing_card/1, Map.merge(@base, overrides))
    |> LazyHTML.from_fragment()
  end

  defp query(overrides, selector) do
    overrides |> document() |> LazyHTML.query(selector)
  end

  defp slot(name, content) do
    [%{__slot__: name, inner_block: fn _, _ -> content end}]
  end

  describe "anatomy" do
    test "is an article carrying the id it was given" do
      article = query(%{}, "article")

      assert LazyHTML.attribute(article, "id") == ["listing-1"]
    end

    test "shows the title" do
      assert %{} |> query("[data-role=title]") |> LazyHTML.text() =~ "Eames-style lounge chair"
    end

    test "shows the price" do
      assert %{} |> query("[data-role=price]") |> LazyHTML.text() =~ "$420.00"
    end
  end

  describe "photo" do
    test "renders the cover image when the listing has one" do
      image = query(%{image_src: "/uploads/cover.png", image_alt: "The chair"}, "img")

      assert LazyHTML.attribute(image, "src") == ["/uploads/cover.png"]
      assert LazyHTML.attribute(image, "alt") == ["The chair"]
    end

    test "falls back to a placeholder rather than a broken image" do
      assert %{} |> query("img") |> Enum.count() == 0
      assert %{} |> query("[data-role=placeholder]") |> Enum.count() == 1
    end

    test "the placeholder is decorative, so screen readers skip it" do
      placeholder = query(%{}, "[data-role=placeholder]")

      assert LazyHTML.attribute(placeholder, "aria-hidden") == ["true"]
    end
  end

  describe "navigation" do
    test "links the title to the listing when given a target" do
      link = query(%{navigate: "/listings/1"}, "[data-role=title] a")

      assert LazyHTML.attribute(link, "href") == ["/listings/1"]
    end

    test "leaves the title as plain text when there is nowhere to go" do
      assert %{} |> query("[data-role=title] a") |> Enum.count() == 0
    end

    test "links the photo to the listing too, since that is what a browser clicks" do
      link =
        query(%{navigate: "/listings/1", image_src: "/uploads/cover.png"}, "[data-role=photo] a")

      assert LazyHTML.attribute(link, "href") == ["/listings/1"]
    end

    test "links the placeholder as well, so a listing without a photo still opens" do
      link = query(%{navigate: "/listings/1"}, "[data-role=photo] a")

      assert LazyHTML.attribute(link, "href") == ["/listings/1"]
    end

    test "leaves the photo unlinked when there is nowhere to go" do
      assert %{} |> query("[data-role=photo] a") |> Enum.count() == 0
    end
  end

  describe "slots" do
    test "renders badges above the title" do
      assert %{badges: slot(:badges, "Active")}
             |> query("[data-role=badges]")
             |> LazyHTML.text() =~ "Active"
    end

    test "renders the meta line" do
      assert %{meta: slot(:meta, "412 views")}
             |> query("[data-role=meta]")
             |> LazyHTML.text() =~ "412 views"
    end

    test "renders the actions footer" do
      assert %{actions: slot(:actions, "Edit")}
             |> query("[data-role=actions]")
             |> LazyHTML.text() =~ "Edit"
    end

    test "leaves out a container for every slot left unused" do
      document = document(%{})

      for role <- ~w(badges meta actions) do
        assert LazyHTML.query(document, "[data-role=#{role}]") |> Enum.count() == 0
      end
    end
  end

  describe "dimmed" do
    test "dims a listing that is no longer on offer" do
      assert %{dimmed: true} |> query("article") |> LazyHTML.attribute("class") |> hd() =~
               "opacity-"
    end

    test "leaves an ordinary listing at full strength" do
      refute %{} |> query("article") |> LazyHTML.attribute("class") |> hd() =~ "opacity-"
    end
  end

  describe "corner" do
    test "renders nothing in the corner unless given something" do
      assert %{} |> query("[data-role=corner]") |> Enum.empty?()
    end

    test "pins what it is given to the card's top-right" do
      corner = query(%{corner: slot(:corner, "Add")}, "[data-role=corner]")

      assert LazyHTML.text(corner) =~ "Add"
      assert corner |> LazyHTML.attribute("class") |> hd() =~ "absolute"
    end

    test "keeps the row's text clear of the corner below md, where they share a line" do
      classes = %{corner: slot(:corner, "Add")} |> query("[data-role=title]") |> Enum.count()

      assert classes == 1

      assert %{corner: slot(:corner, "Add")} |> document() |> LazyHTML.to_html() =~
               "pr-11 md:pr-0"
    end
  end
end
