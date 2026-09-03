defmodule MercatoWeb.UI.MoneyBreakdown do
  @moduledoc """
  What a figure is made of, as a named line each and the figure they come to.

  Shared because both sides of a sale are owed the same courtesy: a seller
  weighing a price reads what the marketplace deducts before they publish, and
  a buyer at checkout reads what is added before they pay. Neither is shown one
  opaque number, and neither should have to recognise a second layout to read
  the same thing.

  The lines are amounts in a currency's minor units, named by whoever
  configured them — shown as they were typed and never translated.

      <.money_breakdown
        id="checkout-summary"
        lines={[%{name: "Items", amount: 24_000}]}
        currency="USD"
        total_label="Total"
        total={24_000}
      />
  """
  use MercatoWeb, :html

  alias Mercato.Money

  @doc """
  Renders the lines and the total they come to.

  `sign` prefixes every line, for a breakdown of what is taken away rather than
  what is added up. `size` is how loud the total reads: `lg` where it is the
  figure the page is about, `sm` where it is a note beside something else.
  """
  attr :id, :string, required: true
  attr :lines, :list, required: true, doc: "`%{name: String.t(), amount: integer}` each"
  attr :currency, :string, required: true
  attr :total, :integer, required: true
  attr :total_label, :string, required: true
  attr :sign, :string, default: "", doc: ~S(prefixes each line — "−" for deductions)
  attr :size, :string, default: "sm", values: ~w(sm lg)
  attr :class, :any, default: nil
  attr :rest, :global

  slot :note, doc: "one caption line under the total"

  def money_breakdown(assigns) do
    ~H"""
    <div id={@id} class={["flex flex-col gap-1.5", @class]} {@rest}>
      <dl class="flex flex-col gap-1.5 m-0">
        <div :for={line <- @lines} class="flex items-baseline justify-between gap-3">
          <dt class="min-w-0 text-caption-lg text-ink-500 break-words">{line.name}</dt>
          <dd class="shrink-0 text-caption-lg tabular-nums text-ink-500">
            {@sign}{Money.format(line.amount, @currency)}
          </dd>
        </div>

        <%!-- Told apart from the lines above it by weight rather than by a
              rule, which on a narrow card would read as another section. --%>
        <div class="flex items-baseline justify-between gap-3">
          <dt class="text-body-sm font-bold text-ink-900 dark:text-white">{@total_label}</dt>
          <dd
            data-role="total"
            class={[
              "shrink-0 font-extrabold tabular-nums text-ink-900 dark:text-white",
              @size == "lg" && "text-title-md",
              @size == "sm" && "text-body-sm"
            ]}
          >
            {Money.format(@total, @currency)}
          </dd>
        </div>
      </dl>

      <p :if={@note != []} class="m-0 text-caption-md text-ink-500 text-pretty">
        {render_slot(@note)}
      </p>
    </div>
    """
  end
end
