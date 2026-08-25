defmodule MercatoWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.CoreComponents

  defp render_badge(assigns) do
    render_component(&CoreComponents.badge/1, assigns)
  end

  defp render_chip(assigns) do
    render_component(&CoreComponents.filter_chip/1, assigns)
  end

  defp render_card(assigns) do
    render_component(&CoreComponents.card/1, assigns)
  end

  defp render_button(assigns) do
    render_component(&CoreComponents.button/1, Map.put_new(assigns, :inner_block, slot("Go")))
  end

  describe "button" do
    test "renders a button element when given no navigation target" do
      assert render_button(%{}) =~ "<button"
    end

    test "renders a link when given a navigation target" do
      assert render_button(%{navigate: "/"}) =~ "<a"
    end

    test "defaults to the full-height primary call to action" do
      html = render_button(%{})

      assert html =~ "bg-primary-500"
      assert html =~ "h-[52px]"
    end

    test "sizes a small action to the card-action height" do
      assert render_button(%{size: "sm"}) =~ "h-9"
    end

    test "sizes an extra-small action to the chip height" do
      assert render_button(%{size: "xs"}) =~ "h-8"
    end

    test "gives a destructive action the error palette" do
      assert render_button(%{variant: "danger"}) =~ "bg-error"
    end

    test "gives a neutral action the ink palette" do
      assert render_button(%{variant: "neutral"}) =~ "bg-ink-100"
    end

    test "gives a secondary action the secondary palette" do
      html = render_button(%{variant: "secondary"})

      assert html =~ "bg-secondary-500"
      assert html =~ "text-white"
    end

    test "darkens a secondary action for dark mode, as the primary one is" do
      assert render_button(%{variant: "secondary"}) =~ "dark:bg-secondary-600"
    end

    test "leaves the primary colour to the primary action" do
      refute render_button(%{variant: "secondary"}) =~ "bg-primary-500"
    end

    test "outlines a tertiary action rather than filling it" do
      html = render_button(%{variant: "tertiary"})

      assert html =~ "border-primary-500"
      refute html =~ "bg-primary-500"
    end

    test "gives a tertiary action text dark enough to read on white" do
      # primary-500 fails AA at this size on white; primary-700 is the token
      # the palette reserves for exactly that.
      assert render_button(%{variant: "tertiary"}) =~ "text-primary-700"
    end

    test "lifts a filled action off the page but not an outlined one" do
      assert render_button(%{}) =~ "shadow-sm"
      refute render_button(%{variant: "tertiary"}) =~ ~r/[\s"]shadow-sm/
    end

    test "hugs its content rather than the row it sits in" do
      refute render_button(%{}) =~ "w-full"
    end

    test "fills the row when asked to" do
      assert render_button(%{full_width: true}) =~ "w-full"
    end

    test "an explicit class replaces the defaults outright" do
      html = render_button(%{class: "my-class"})

      assert html =~ "my-class"
      refute html =~ "bg-primary-500"
    end
  end

  describe "badge" do
    test "renders its content" do
      assert render_badge(kind: "verified", inner_block: slot("Active")) =~ "Active"
    end

    test "uses the success palette for verified" do
      html = render_badge(kind: "verified", inner_block: slot("Active"))

      assert html =~ "bg-success-bg"
      assert html =~ "text-success-text"
    end

    test "uses the accent palette for featured" do
      html = render_badge(kind: "featured", inner_block: slot("Featured"))

      assert html =~ "bg-accent-100"
    end

    test "uses the warning palette for a state that limits a record" do
      html = render_badge(kind: "warning", inner_block: slot("Restricted"))

      assert html =~ "bg-warning-bg"
      assert html =~ "text-warning-text"
    end

    test "uses the error palette for a state that stops a record" do
      # Not the accent palette, which is reserved for featured records, and not
      # the vibrant sale red, which means a discount.
      html = render_badge(kind: "danger", inner_block: slot("Banned"))

      assert html =~ "bg-error-bg"
      assert html =~ "text-error-text"
    end

    test "uses the info palette for a state a record has come to rest in" do
      html = render_badge(%{kind: "info", inner_block: slot("Sold")})

      assert html =~ "bg-info-bg"
      assert html =~ "text-info-text"
    end

    test "uses the ink palette for neutral" do
      html = render_badge(kind: "neutral", inner_block: slot("Deleted"))

      assert html =~ "bg-ink-100"
      assert html =~ "text-ink-700"
    end
  end

  describe "filter_chip" do
    test "renders an unselected chip with a border and no fill" do
      html = render_chip(label: "Active (2)", selected: false)

      assert html =~ "Active (2)"
      assert html =~ "border-ink-900"
      # Anchored, so the dark-mode `dark:bg-ink-900` surface doesn't read as a fill.
      refute html =~ ~r/[\s"]bg-ink-900/
    end

    test "renders a selected chip as solid, and marks it pressed" do
      html = render_chip(label: "Active (2)", selected: true)

      assert html =~ ~r/[\s"]bg-ink-900/
      assert html =~ ~s(aria-pressed="true")
    end

    test "a removable chip carries a labelled remove control" do
      html = render_chip(label: "Status: Banned", removable: true)

      assert html =~ "Remove Status: Banned"
    end

    test "a plain chip has no remove control" do
      refute render_chip(label: "Active (2)", selected: false) =~ "Remove"
    end
  end

  describe "card" do
    test "pads tighter below md and wider from md up" do
      html = render_card(inner_block: slot("Body"))

      assert html =~ ~r/[\s"]p-5/
      assert html =~ "md:p-8"
    end

    test "keeps the caller's classes alongside the surface" do
      html = render_card(class: "flex flex-col gap-5", inner_block: slot("Body"))

      assert html =~ "flex flex-col gap-5"
      assert html =~ "rounded-lg"
    end
  end

  describe "table" do
    test "renders a header and a cell per column" do
      html = render_table(col: [col("Name", & &1.name), col("Status", & &1.status)])

      assert html =~ "Name"
      assert html =~ "Status"
      assert html =~ "Ada"
      assert html =~ "active"
    end

    test "labels the table for screen readers when given a caption" do
      html = render_table(caption: "User accounts", col: [col("Name", & &1.name)])

      assert html =~ ~s(<caption class="sr-only">User accounts</caption>)
    end

    test "omits the caption element when none is given" do
      refute render_table(col: [col("Name", & &1.name)]) =~ "<caption"
    end

    test "identifies the tbody and each row" do
      html =
        render_table(id: "accounts", row_id: &"account-#{&1.id}", col: [col("Name", & &1.name)])

      assert html =~ ~s(id="accounts")
      assert html =~ ~s(id="account-1")
    end

    test "applies a column class to both the header cell and the body cell" do
      html = render_table(col: [col("Email", & &1.name, class: "hidden xl:table-cell")])

      assert [_, _] = Regex.scan(~r/hidden xl:table-cell/, html)
    end

    test "applies a cell class to the body cell only" do
      html = render_table(col: [col("Name", & &1.name, cell_class: "whitespace-nowrap")])

      assert [_] = Regex.scan(~r/whitespace-nowrap/, html)
    end

    test "derives a cell class from the row when given a function" do
      html =
        render_table(
          rows: [
            %{id: 1, name: "Ada", status: "active"},
            %{id: 2, name: "Rita", status: "deleted"}
          ],
          col: [
            col("Status", & &1.status, cell_class: &if(&1.status == "deleted", do: "opacity-55"))
          ]
        )

      assert [_] = Regex.scan(~r/opacity-55/, html)
    end

    test "derives a row class from the row when given a function" do
      html =
        render_table(
          rows: [
            %{id: 1, name: "Ada", status: "active"},
            %{id: 2, name: "Rita", status: "deleted"}
          ],
          row_class: &if(&1.status == "deleted", do: "opacity-55"),
          col: [col("Name", & &1.name)]
        )

      assert [_] = Regex.scan(~r/opacity-55/, html)
    end

    test "renders a row_header column as a row-scoped header cell" do
      html =
        render_table(col: [col("Name", & &1.name, row_header: true), col("Status", & &1.status)])

      assert html =~ ~r/<th[^>]*scope="row"/
      assert html =~ "<td"
    end

    test "renders every column as a data cell when none is a row header" do
      html = render_table(col: [col("Name", & &1.name)])

      refute html =~ ~s(scope="row")
    end

    test "renders an actions column with a screen-reader label" do
      html =
        render_table(
          col: [col("Name", & &1.name)],
          action: [%{__slot__: :action, inner_block: fn _, _ -> "Ban" end}]
        )

      assert html =~ "Ban"
      assert html =~ "Actions"
    end

    test "has no actions column when the slot is unused" do
      refute render_table(col: [col("Name", & &1.name)]) =~ "Actions"
    end
  end

  defp render_table(assigns) do
    assigns =
      assigns
      |> Keyword.put_new(:id, "table")
      |> Keyword.put_new(:rows, [%{id: 1, name: "Ada", status: "active"}])

    render_component(&CoreComponents.table/1, assigns)
  end

  defp col(label, fun, opts \\ []) do
    opts
    |> Map.new()
    |> Map.merge(%{label: label, __slot__: :col, inner_block: fn _, row -> fun.(row) end})
  end

  defp slot(text), do: [%{inner_block: fn _, _ -> text end, __slot__: :inner_block}]
end
