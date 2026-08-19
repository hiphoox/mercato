defmodule MercatoWeb.UI.AvatarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.Avatar

  defp document(assigns) do
    LazyHTML.from_fragment(render_component(&Avatar.avatar/1, assigns))
  end

  defp text(assigns) do
    assigns |> document() |> LazyHTML.text() |> String.trim()
  end

  describe "with an image" do
    test "renders an img pointing at src" do
      images =
        [src: "/uploads/jane.png", name: "Jane Doe"]
        |> document()
        |> LazyHTML.query("img")

      assert LazyHTML.attribute(images, "src") == ["/uploads/jane.png"]
    end

    test "uses the name as alt text so the image is not announced as decorative" do
      images =
        [src: "/uploads/jane.png", name: "Jane Doe"]
        |> document()
        |> LazyHTML.query("img")

      assert LazyHTML.attribute(images, "alt") == ["Jane Doe"]
    end

    test "does not render initials alongside the image" do
      assert text(src: "/uploads/jane.png", name: "Jane Doe") == ""
    end
  end

  describe "initials fallback" do
    test "uses the first letter of the first and last name" do
      assert text(name: "Jane Doe") == "JD"
    end

    test "uses a single initial when only one name is given" do
      assert text(name: "Jane") == "J"
    end

    test "ignores extra middle names" do
      assert text(name: "Jane Amelia Doe") == "JD"
    end

    test "uppercases a lowercased name" do
      assert text(name: "jane doe") == "JD"
    end

    test "falls back to a neutral placeholder when there is no name" do
      assert text(name: nil) == "?"
    end

    test "treats a blank name as no name" do
      assert text(name: "   ") == "?"
    end

    test "renders no img element" do
      images = [name: "Jane Doe"] |> document() |> LazyHTML.query("img")

      assert Enum.empty?(images)
    end

    test "marks the initials as an image with the name as its label" do
      root = [name: "Jane Doe"] |> document() |> LazyHTML.query("[role=img]")

      assert LazyHTML.attribute(root, "aria-label") == ["Jane Doe"]
    end
  end

  describe "sizing" do
    test "applies the given size to the rendered element" do
      root = [name: "Jane Doe", size: 38] |> document() |> LazyHTML.query("[role=img]")
      style = LazyHTML.attribute(root, "style") |> hd()

      assert style =~ "width:38px"
      assert style =~ "height:38px"
    end

    test "scales the initials with the avatar so they never overflow" do
      small = [name: "Jane Doe", size: 24] |> document() |> LazyHTML.query("[role=img]")
      large = [name: "Jane Doe", size: 96] |> document() |> LazyHTML.query("[role=img]")

      assert LazyHTML.attribute(small, "style") |> hd() =~ "font-size:"
      refute LazyHTML.attribute(small, "style") == LazyHTML.attribute(large, "style")
    end

    test "sizes the image variant too" do
      root =
        [name: "Jane Doe", src: "/uploads/jane.png", size: 38]
        |> document()
        |> LazyHTML.query("img")

      style = LazyHTML.attribute(root, "style") |> hd()

      assert style =~ "width:38px"
      assert style =~ "height:38px"
    end
  end

  describe "customisation" do
    test "merges a caller-supplied class" do
      root = [name: "Jane Doe", class: "ring-2"] |> document() |> LazyHTML.query("[role=img]")

      assert LazyHTML.attribute(root, "class") |> hd() =~ "ring-2"
    end

    test "keeps the rounded-full base class when a custom class is given" do
      root = [name: "Jane Doe", class: "ring-2"] |> document() |> LazyHTML.query("[role=img]")

      assert LazyHTML.attribute(root, "class") |> hd() =~ "rounded-full"
    end
  end
end
