defmodule MercatoWeb.UI.QuantityStepper do
  @moduledoc """
  How many of one thing somebody wants, as a control they can move.

  A component rather than a pair of buttons written into the cart: how many of
  a listing a buyer wants is asked on the listing's own page as well, and both
  places have to agree on the floor of one and on the ceiling the seller sets.

  It computes nothing about the cart. The quantity each button would move to
  rides along as `phx-value-quantity`, so the caller handles one event with a
  number in it rather than two events it has to do arithmetic for.

      <.quantity_stepper
        id={"qty-\#{line.id}"}
        value={line.quantity}
        max={line.listing.quantity}
        label={line.listing.title}
        phx-click="set_quantity"
        phx-value-id={line.id}
      />
  """
  use MercatoWeb, :html

  @doc """
  Renders the stepper.

  Pointer-first at 28px buttons: it never stands alone on a screen, only beside
  the other controls of the row it belongs to.
  """
  attr :id, :string, required: true
  attr :value, :integer, required: true
  attr :max, :integer, required: true, doc: "the ceiling — what the seller has"
  attr :label, :string, required: true, doc: "what is being counted; names both buttons"
  attr :class, :any, default: nil
  attr :rest, :global, doc: "the event both buttons carry, and the values that go with it"

  def quantity_stepper(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "inline-flex items-center gap-0.5 h-9 px-1 flex-none",
        "rounded-full border border-ink-300 dark:border-ink-700",
        "bg-bg dark:bg-ink-900",
        @class
      ]}
    >
      <.step
        id={"#{@id}-decrease"}
        icon="hero-minus"
        quantity={@value - 1}
        disabled={@value <= 1}
        label={gettext("Decrease the quantity of %{label}", label: @label)}
        {@rest}
      />

      <span
        id={"#{@id}-value"}
        aria-live="polite"
        class="min-w-7 text-center text-body-sm font-bold tabular-nums text-ink-900 dark:text-white"
      >
        {@value}
      </span>

      <.step
        id={"#{@id}-increase"}
        icon="hero-plus"
        quantity={@value + 1}
        disabled={@value >= @max}
        label={gettext("Increase the quantity of %{label}", label: @label)}
        {@rest}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :icon, :string, required: true
  attr :quantity, :integer, required: true
  attr :disabled, :boolean, required: true
  attr :label, :string, required: true
  attr :rest, :global

  defp step(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      disabled={@disabled}
      aria-label={@label}
      phx-value-quantity={@quantity}
      class={[
        "flex items-center justify-center size-7 flex-none rounded-full cursor-pointer",
        "text-ink-700 dark:text-ink-100 transition-colors",
        "hover:bg-ink-100 hover:text-ink-900 dark:hover:bg-ink-700 dark:hover:text-white",
        "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
        "disabled:bg-transparent disabled:text-ink-300 disabled:cursor-not-allowed",
        "disabled:hover:bg-transparent disabled:hover:text-ink-300"
      ]}
      {@rest}
    >
      <.icon name={@icon} aria-hidden="true" class="size-4" />
    </button>
    """
  end
end
