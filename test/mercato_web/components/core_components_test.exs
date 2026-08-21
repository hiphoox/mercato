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
