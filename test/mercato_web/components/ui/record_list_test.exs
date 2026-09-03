defmodule MercatoWeb.UI.RecordListTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MercatoWeb.UI.RecordList

  @rows [
    %{id: "1", name: "Commission", takes: "10%"},
    %{id: "2", name: "VAT", takes: "21%"}
  ]

  defp col(label, render, extra \\ %{}) do
    Map.merge(%{__slot__: :col, label: label, inner_block: fn _, row -> render.(row) end}, extra)
  end

  defp slot(name, render) do
    [%{__slot__: name, inner_block: fn _, value -> render.(value) end}]
  end

  defp assigns(overrides) do
    Map.merge(
      %{
        id: "deductions",
        rows: @rows,
        caption: "What is deducted",
        row_id: &"deduction-#{&1.id}",
        col: [
          col("Name", & &1.name, %{row_header: true}),
          col("Takes", & &1.takes)
        ],
        empty: slot(:empty, fn _ -> "Nothing is deducted." end)
      },
      overrides
    )
  end

  defp document(overrides) do
    render_component(&RecordList.record_list/1, assigns(overrides))
    |> LazyHTML.from_fragment()
  end

  defp query(overrides, selector) do
    overrides |> document() |> LazyHTML.query(selector)
  end

  describe "a listing that holds nothing" do
    test "shows what the caller says about the emptiness" do
      assert %{rows: []} |> document() |> LazyHTML.text() =~ "Nothing is deducted."
    end

    test "renders no table at all, rather than an empty one" do
      assert %{rows: []} |> query("table") |> Enum.count() == 0
    end

    test "renders no footer, since there is nothing to page through" do
      overrides = %{rows: [], footer: slot(:footer, fn _ -> "Page 1 of 3" end)}

      refute overrides |> document() |> LazyHTML.text() =~ "Page 1 of 3"
    end
  end

  describe "the table" do
    test "carries the id and caption it was given" do
      assert %{} |> query("tbody") |> LazyHTML.attribute("id") == ["deductions"]
      assert %{} |> query("caption") |> LazyHTML.text() =~ "What is deducted"
    end

    test "renders a row per record, identified as the caller names it" do
      rows = query(%{}, "tbody tr")

      assert LazyHTML.attribute(rows, "id") == ["deduction-1", "deduction-2"]
    end

    test "renders the column a caller marked as the row's header as one" do
      header = query(%{}, "tbody tr:first-child th[scope=row]")

      assert LazyHTML.text(header) =~ "Commission"
    end

    test "labels every column in the head" do
      assert %{} |> query("thead th") |> LazyHTML.text() =~ "Takes"
    end
  end

  describe "the cards below the table's breakpoint" do
    test "renders one card per record" do
      cards = query(%{}, "[data-role=record-card]")

      assert LazyHTML.attribute(cards, "id") == ["deduction-1-card", "deduction-2-card"]
    end

    test "shows each column's label beside its value" do
      card = query(%{}, "#deduction-1-card")

      assert LazyHTML.text(card) =~ "Takes"
      assert LazyHTML.text(card) =~ "10%"
    end

    test "leaves the row's header column unlabelled, since it heads the card" do
      labels = query(%{}, "#deduction-1-card dt") |> LazyHTML.text()

      assert labels =~ "Takes"
      refute labels =~ "Name"
    end
  end

  describe "row actions" do
    test "are rendered once in the table and once in the cards, told which is which" do
      overrides = %{
        actions: slot(:actions, fn %{row: row, prefix: prefix} -> "action-#{prefix}#{row.id}" end)
      }

      text = overrides |> document() |> LazyHTML.text()

      assert text =~ "action-1"
      assert text =~ "action-card-1"
    end

    test "leave the actions column out entirely when a caller offers none" do
      assert %{} |> query("thead th") |> Enum.count() == 2
    end
  end

  describe "what a caller styles" do
    test "applies a row class to the row and to the card alike" do
      overrides = %{row_class: fn row -> row.id == "1" && "opacity-60" end}

      assert overrides |> query("#deduction-1") |> LazyHTML.attribute("class") |> to_string() =~
               "opacity-60"

      assert overrides |> query("#deduction-1-card") |> LazyHTML.attribute("class") |> to_string() =~
               "opacity-60"
    end
  end

  describe "the footer" do
    test "renders below the records when there are some" do
      overrides = %{footer: slot(:footer, fn _ -> "Page 1 of 3" end)}

      assert overrides |> document() |> LazyHTML.text() =~ "Page 1 of 3"
    end
  end
end
