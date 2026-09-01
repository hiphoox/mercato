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
  """
  def group_by_seller(lines) do
    lines
    |> Enum.group_by(& &1.seller_id)
    |> Enum.map(fn {_seller_id, [first | _] = grouped} ->
      %{seller: first.seller, lines: grouped}
    end)
  end
end
