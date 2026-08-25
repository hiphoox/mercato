defmodule MercatoWeb.UI.EmptyStateTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.EmptyState

  defp query(assigns, selector) do
    assigns = Map.put_new(assigns, :headline, "Nothing here yet")

    render_component(&EmptyState.empty_state/1, assigns)
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  describe "structure" do
    test "announces the headline as a heading, not as loose text" do
      assert %{} = heading = query(%{headline: "Your first listing"}, "h2")

      assert LazyHTML.text(heading) =~ "Your first listing"
    end

    test "renders the description when given one" do
      html = query(%{description: "Photos, a price, a short description."}, "p")

      assert LazyHTML.text(html) =~ "Photos, a price, a short description."
    end

    test "omits the description paragraph when given none" do
      assert %{} |> query("p") |> Enum.count() == 0
    end
  end

  describe "icon" do
    test "renders the icon it is given, hidden from screen readers" do
      icon = query(%{icon: "hero-inbox"}, "span.hero-inbox")

      assert LazyHTML.attribute(icon, "aria-hidden") == ["true"]
    end

    test "renders no icon when given none" do
      assert %{} |> query("[aria-hidden=true]") |> Enum.count() == 0
    end
  end

  describe "actions" do
    test "renders the actions slot" do
      actions = [%{__slot__: :actions, inner_block: fn _, _ -> "List something" end}]

      assert %{actions: actions} |> query("[data-role=empty-state-actions]") |> LazyHTML.text() =~
               "List something"
    end

    test "renders no actions container when the slot is unused" do
      assert %{} |> query("[data-role=empty-state-actions]") |> Enum.count() == 0
    end
  end
end
