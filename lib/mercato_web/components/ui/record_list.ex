defmodule MercatoWeb.UI.RecordList do
  @moduledoc """
  A collection of records read as a table on a wide screen and as cards on a
  narrow one.

  One markup tree switched in CSS, so a resize costs no re-render: from `md` up
  the records are a table inside a bordered card, and below it each record is a
  card of its own carrying every column's label beside its value.

  The columns are declared once and drive both renderings, so a column added to
  the table appears on the card without a second edit. The column marked as the
  row's header heads the card, which is why it needs no label there.

  What to say when the collection holds nothing is the caller's: a collection
  that has never held anything and a filter matching nothing are different
  news, and only the caller knows which this is.

      <.record_list id="deductions" rows={@rows} row_id={&"deduction-\#{&1.id}"}>
        <:col :let={row} label="Name" row_header>{row.name}</:col>
        <:col :let={row} label="Takes">{row.takes}</:col>
        <:actions :let={%{row: row, prefix: prefix}}>
          <.menu id={"actions-\#{prefix}\#{row.id}"}>…</.menu>
        </:actions>
        <:empty>Nothing is deducted.</:empty>
      </.record_list>
  """
  use MercatoWeb, :html

  @doc """
  Renders the records, or the empty slot when there are none.

  `row_id` names each record, and a card takes that name with `-card` on the
  end, since both renderings are in the DOM at any width and an id may only
  belong to one of them.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, required: true, doc: "a function of the record returning its id"

  attr :caption, :string,
    default: nil,
    doc: "describes the collection to a screen reader; not shown visually"

  attr :row_class, :any,
    default: nil,
    doc: "a class for every record, or a function of the record returning one"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :col, required: true do
    attr :label, :string
    attr :class, :any, doc: "applied to this column's table cells only, not to the card"

    attr :cell_class, :any,
      doc: "applied to this column's table body cells; a class or a function"

    attr :row_header, :boolean,
      doc: "renders this column as the record's header, and heads its card"
  end

  slot :actions,
    doc:
      "what can be done to a record, given `%{row: record, prefix: prefix}` to name itself with"

  slot :empty, doc: "what the collection says when it holds nothing"
  slot :footer, doc: "what sits under the records — paging, a total"

  def record_list(assigns) do
    ~H"""
    <div :if={@rows == []}>{render_slot(@empty)}</div>

    <%!-- From md up the container is the bordered card the table sits in; below
          that it is transparent and each record card carries its own border. --%>
    <div
      :if={@rows != []}
      class={[
        "md:border md:border-ink-100 md:dark:border-ink-700 md:rounded-lg",
        "md:bg-white md:dark:bg-ink-900",
        @class
      ]}
      {@rest}
    >
      <div class="hidden md:block max-h-[min(58vh,520px)] overflow-y-auto rounded-t-lg">
        <.table id={@id} rows={@rows} caption={@caption} row_id={@row_id} row_class={@row_class}>
          <:col
            :let={row}
            :for={col <- @col}
            label={col[:label]}
            class={col[:class]}
            cell_class={col[:cell_class]}
            row_header={!!col[:row_header]}
          >
            {render_slot(col, row)}
          </:col>
          <:action :let={row} :if={@actions != []}>
            {render_slot(@actions, %{row: row, prefix: ""})}
          </:action>
        </.table>
      </div>

      <div class="md:hidden flex flex-col gap-3">
        <div
          :for={row <- @rows}
          id={"#{@row_id.(row)}-card"}
          data-role="record-card"
          class={[
            "flex flex-col gap-3.5 p-4 rounded-lg border border-ink-100 dark:border-ink-700",
            "bg-white dark:bg-ink-900",
            from_row(@row_class, row)
          ]}
        >
          <div class="flex items-start justify-between gap-2">
            <div class="min-w-0">
              {render_slot(heading(@col), row)}
            </div>
            <div :if={@actions != []}>
              {render_slot(@actions, %{row: row, prefix: "card-"})}
            </div>
          </div>

          <dl class="flex flex-col gap-2 text-body-sm text-ink-700 dark:text-ink-100">
            <div :for={col <- labelled(@col)} class="flex gap-2.5">
              <dt class="min-w-[88px] text-ink-500">{col[:label]}</dt>
              <dd class="min-w-0 break-words">{render_slot(col, row)}</dd>
            </div>
          </dl>
        </div>
      </div>

      <div :if={@footer != []}>{render_slot(@footer)}</div>
    </div>
    """
  end

  # The column heading each card, which is the one marked as the row's header,
  # falling back to the first where a caller marked none.
  defp heading(cols), do: Enum.find(cols, hd(cols), & &1[:row_header])

  defp labelled(cols), do: Enum.reject(cols, &(&1 == heading(cols)))

  defp from_row(class, row) when is_function(class, 1), do: class.(row)
  defp from_row(class, _row), do: class
end
