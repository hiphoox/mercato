defmodule Mercato.Carts do
  @moduledoc """
  Domain for what a buyer has gathered but not yet bought.

  Its own area rather than part of `Mercato.Orders`: an order records what was
  bought and holds the terms it was bought on, while a cart holds only an
  intention, reads the listing's price as it currently stands, and binds
  nobody to anything.
  """

  use Ash.Domain, otp_app: :mercato

  alias Mercato.Accounts.Scope
  alias Mercato.Accounts.Setting

  resources do
    resource Mercato.Carts.CartItem do
      define :add_to_cart, action: :add, args: [:listing_id]
      define :list_cart, action: :list_mine
      define :list_seller_cart, action: :list_for_seller, args: [:seller_id]
      define :list_lapsed_seller_cart, action: :lapsed_for_seller, args: [:seller_id, :cutoff]
      define :set_cart_quantity, action: :set_quantity
      define :remove_from_cart, action: :remove
    end
  end

  @doc """
  How long a line the buyer has not touched stays in their cart, in seconds.

  A cart binds nobody, so a line nobody has revisited in this long says
  nothing about what its owner still means to buy, and is dropped rather than
  kept forever. Operator-set, since how long an intention keeps depends on
  what is being sold.

  Seconds rather than the days an operator sets it in, so a window short
  enough to watch pass is expressible.
  """
  def retention_seconds, do: Setting.get(:cart_retention_seconds)

  @doc """
  The moment a line must have been touched since to still be in a cart.

  Touched rather than added: raising a line's quantity or adding its listing
  again says the buyer still means to buy it, and renews it. Opening the cart
  does not — a line the buyer keeps scrolling past is exactly the one the
  window is for.
  """
  def retention_cutoff, do: DateTime.add(DateTime.utc_now(), -retention_seconds(), :second)

  @doc """
  A fresh token for a visitor with no account, minted per browser.

  Random rather than derived from anything about the visitor: it is the only
  thing standing between one guest cart and another, so it is a secret and
  nothing else.
  """
  def new_guest_token, do: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

  @doc """
  Takes over the lines gathered against `guest_token` for `user`.

  What a visitor gathered is theirs once they have an account to gather it
  into, so signing in claims it rather than asking them to gather it again.
  Each line is added the ordinary way, so a listing already in the account's
  cart is summed with the one gathered as a visitor rather than duplicated,
  and one that stopped being buyable in between is simply dropped — a sign-in
  is not the place to fail over a listing somebody else bought first.
  """
  def claim_cart(user, guest_token) do
    visitor = Scope.for_user(nil, guest_token)

    for line <- list_cart!(scope: visitor) do
      add_to_cart(line.listing_id, %{quantity: line.quantity}, actor: user)
      remove_from_cart!(line, scope: visitor)
    end

    :ok
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
        total: total(grouped),
        buyable?: Enum.all?(grouped, &line_buyable?/1)
      }
    end)
  end

  @doc """
  Whether a line can still be bought.

  A listing leaves the marketplace while it sits in carts — somebody else buys
  it, the seller pauses or runs out of it, moderation takes it down. The line
  stays where the buyer put it and says so, rather than vanishing without a word.

  A listing moderation took down is hidden from the buyer, so it is unbuyable
  and nameless both.
  """
  def line_buyable?(%{listing: nil}), do: false
  def line_buyable?(%{listing: listing}), do: listing.buyable?

  @doc """
  One seller's group of the cart, or nil where the buyer has gathered nothing
  from them.

  What a checkout is for: a group is bought in one go and becomes one order, so
  a checkout is addressed by the seller whose group it is rather than by the
  cart. Nil covers a seller the buyer has nothing from and a seller that is not
  one at all alike — neither is a group anyone could pay for, and a checkout
  has nowhere to go in either case.

  Built through `group_by_seller/1` so the figures a buyer weighed in the cart
  are the same ones they are asked to pay.
  """
  def seller_group(seller_id, opts) do
    seller_id
    |> list_seller_cart!(opts)
    |> group_by_seller()
    |> List.first()
  end

  @doc """
  One seller's group as a checkout finds it, or why there is none to pay for.

  A checkout that cannot go ahead has to say which thing happened, and the two
  read nothing alike to the buyer: `:lapsed` is their own cart clearing itself
  after they left it alone, and `:gone` is what they gathered no longer being
  there to buy.

  What lapsed is read before the group is, since reading a cart is also what
  clears it: afterwards there is nothing left to tell the two apart by.
  """
  def checkout_group(seller_id, opts) do
    lapsed = list_lapsed_seller_cart!(seller_id, retention_cutoff(), opts)

    case {seller_group(seller_id, opts), lapsed} do
      {nil, [_lapsed | _rest]} -> {:error, :lapsed}
      {nil, []} -> {:error, :gone}
      {group, _lapsed} -> {:ok, group}
    end
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

  @doc """
  How many things the lines add up to, counting a line of three as three.

  Only what can still be bought.
  """
  def item_count(lines) do
    lines
    |> Enum.filter(&line_buyable?/1)
    |> Enum.sum_by(& &1.quantity)
  end

  # Read off the listings rather than off the lines, which hold no price: what
  # a listing costs is the listing's to say until a purchase agrees it.
  #
  # An empty cart is denominated in the marketplace's own currency, there being
  # no listing to take one from.
  defp total(lines) do
    buyable = Enum.filter(lines, &line_buyable?/1)
    amount = Enum.sum_by(buyable, &(&1.listing.price * &1.quantity))

    Mercato.Money.format(amount, currency(buyable))
  end

  defp currency([%{listing: listing} | _rest]), do: listing.currency
  defp currency([]), do: Mercato.Listings.currency()
end
