defmodule MercatoWeb.UI.ListingGrid do
  @moduledoc """
  The shelf any set of listing cards sits on.

  One column below `md`, where a card is a row and a grid would squeeze it;
  as many columns as fit from `md` up, where a card is a tile. The count is
  the container's to decide rather than the page's, so two pages showing
  listings never disagree about how wide a card is.

      <.listing_grid>
        <.listing_card :for={listing <- @listings} ... />
      </.listing_grid>
  """
  use MercatoWeb, :html

  @doc "Renders a responsive grid of `MercatoWeb.UI.ListingCard.listing_card/1`."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def listing_grid(assigns) do
    ~H"""
    <%!-- `auto-fill` rather than `auto-fit`: a shelf holding one listing should
          leave the empty tracks empty, not stretch that card across the row. --%>
    <div
      class={[
        "grid grid-cols-1 gap-3 md:grid-cols-[repeat(auto-fill,minmax(15.5rem,1fr))] md:gap-5",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
