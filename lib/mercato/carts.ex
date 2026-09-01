defmodule Mercato.Carts do
  @moduledoc """
  Domain for what a buyer has gathered but not yet bought.

  Its own area rather than part of `Mercato.Orders`: an order records what was
  bought and holds the terms it was bought on, while a cart holds only an
  intention, reads the listing's price as it currently stands, and binds
  nobody to anything.
  """

  use Ash.Domain, otp_app: :mercato

  resources do
    resource Mercato.Carts.CartItem do
      define :add_to_cart, action: :add, args: [:listing_id]
      define :list_cart, action: :list_mine
      define :set_cart_quantity, action: :set_quantity
      define :remove_from_cart, action: :remove
    end
  end

  @doc """
  The cart's lines gathered into one group per seller.

  Grouped here rather than by the data layer, which offers no aggregates at
  all, and grouped at all because each group is what becomes a single order.

  Each group carries what its lines come to, since a group is what a buyer
  weighs and what they will eventually pay for in one go.
  """
  def group_by_seller(lines) do
    lines
    |> Enum.group_by(& &1.seller_id)
    |> Enum.map(fn {_seller_id, [first | _] = grouped} ->
      %{
        seller: first.seller,
        lines: grouped,
        item_count: item_count(grouped),
        total: total(grouped)
      }
    end)
  end

  @doc """
  What every line in the cart comes to, across sellers.

  One figure over a cart that is bought in several goes, so it is a summary
  rather than a price: nobody is ever charged this.
  """
  def cart_total(lines), do: total(lines)

  @doc """
  What one line comes to — the listing's price as many times as it is wanted.

  Formatted here rather than in the web layer, which has no business knowing
  what currency a listing is priced in.
  """
  def line_total(line), do: total([line])

  @doc "How many things the lines add up to, counting a line of three as three."
  def item_count(lines), do: Enum.sum_by(lines, & &1.quantity)

  # Read off the listings rather than off the lines, which hold no price: what
  # a listing costs is the listing's to say until a purchase agrees it.
  #
  # An empty cart is denominated in the marketplace's own currency, there being
  # no listing to take one from.
  defp total(lines) do
    amount = Enum.sum_by(lines, &(&1.listing.price * &1.quantity))

    Mercato.Money.format(amount, currency(lines))
  end

  defp currency([%{listing: listing} | _rest]), do: listing.currency
  defp currency([]), do: Mercato.Listings.currency()
end
