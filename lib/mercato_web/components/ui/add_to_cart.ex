defmodule MercatoWeb.UI.AddToCart do
  @moduledoc """
  The control that puts a listing in the buyer's cart, as a card offers it.

  A component of its own rather than a button written into each grid: browse
  and a seller's storefront offer the same action on the same object, and the
  cart it will write to does not exist yet — when it does, this is the one
  place that learns about it.

  Round and iconic because it sits over the photo rather than in the card's
  flow, where a worded button would cover the thing being sold. The name it
  drops is carried by its accessible name instead, the way the header's own
  cart control carries its.

  Drawn ahead of the cart it will write to, so it renders as the live control
  it is going to be rather than as a disabled one — what it does on a click is
  this component's to add, and nothing else has to change when it does.

      <.add_to_cart id={"add-to-cart-\#{listing.id}"} />
  """
  use MercatoWeb, :html

  @doc "Renders the action as a control pinned to a card's corner."
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def add_to_cart(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      aria-label={gettext("Add to cart")}
      class={
        [
          # 44, the minimum touch target, since it is the only control on a card.
          "flex items-center justify-center size-11 rounded-full cursor-pointer",
          "bg-bg dark:bg-ink-900 text-ink-900 dark:text-white shadow-md",
          "transition-[filter] hover:brightness-95",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
          # The disabled palette is a token pair rather than a faded fill.
          "disabled:bg-ink-100 disabled:text-ink-300 disabled:shadow-none",
          "disabled:cursor-not-allowed disabled:hover:brightness-100",
          @class
        ]
      }
      {@rest}
    >
      <.icon name="hero-plus" aria-hidden="true" class="size-5" />
    </button>
    """
  end
end
