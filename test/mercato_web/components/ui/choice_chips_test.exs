defmodule MercatoWeb.UI.ChoiceChipsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.ChoiceChips

  @options [{"New", "new"}, {"Like new", "like_new"}, {"Good", "good"}]

  defp query(assigns, selector) do
    assigns =
      assigns
      |> Map.put_new(:name, "listing[condition]")
      |> Map.put_new(:label, "Condition")
      |> Map.put_new(:options, @options)

    render_component(&ChoiceChips.choice_chips/1, assigns)
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  describe "structure" do
    test "renders one radio per option, all sharing the field's name" do
      radios = query(%{}, "input[type=radio]")

      assert LazyHTML.attribute(radios, "value") == ["new", "like_new", "good"]
      assert LazyHTML.attribute(radios, "name") == List.duplicate("listing[condition]", 3)
    end

    test "labels the group visibly, not by placeholder" do
      assert %{} |> query("legend") |> LazyHTML.text() =~ "Condition"
    end

    test "groups the chips in a fieldset the legend names" do
      assert %{} |> query("fieldset") |> Enum.count() == 1
    end

    test "renders nothing at all when the marketplace configures no options" do
      assert render_component(&ChoiceChips.choice_chips/1, %{
               name: "listing[condition]",
               label: "Condition",
               options: []
             }) =~ ~r/\A\s*\z/
    end
  end

  describe "selection" do
    test "checks the option matching the current value" do
      checked = query(%{value: "like_new"}, "input[checked]")

      assert LazyHTML.attribute(checked, "value") == ["like_new"]
    end

    test "checks nothing when the value is blank" do
      assert %{value: nil} |> query("input[checked]") |> Enum.count() == 0
    end

    test "fills whichever chip is checked, in CSS rather than on re-render" do
      chips = query(%{value: "good"}, "label span")
      classes = LazyHTML.attribute(chips, "class")

      assert Enum.all?(classes, &(&1 =~ "peer-checked:bg-ink-900"))
    end

    test "keeps the radio itself reachable by keyboard rather than hiding it" do
      radios = query(%{}, "input[type=radio]")

      assert Enum.all?(LazyHTML.attribute(radios, "class"), &(&1 =~ "sr-only"))
      refute "hidden" in LazyHTML.attribute(radios, "class")
    end
  end

  describe "clearing" do
    test "offers a way back to no choice when the field is optional" do
      radios = query(%{value: "good", clear_label: "No preference"}, "input[type=radio]")

      assert "" in LazyHTML.attribute(radios, "value")
    end

    test "offers no such option when the field is required" do
      radios = query(%{value: "good"}, "input[type=radio]")

      refute "" in LazyHTML.attribute(radios, "value")
    end
  end

  describe "errors" do
    test "carries a message as well as a border" do
      html = query(%{errors: ["is not a condition this marketplace uses"]}, "p")

      assert LazyHTML.text(html) =~ "is not a condition this marketplace uses"
    end
  end
end
