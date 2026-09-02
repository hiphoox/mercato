defmodule Mercato.Carts.CartItemTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts.Scope
  alias Mercato.Carts

  setup do
    %{buyer: generate(user()), seller: generate(user())}
  end

  describe "adding a listing" do
    test "puts it in the cart of whoever is acting", ctx do
      listing = offered_listing(ctx.seller)

      assert {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      assert line.user_id == ctx.buyer.id
      assert line.listing_id == listing.id
      assert line.quantity == 1
    end

    test "records the seller, so a cart reads without reaching through the listing", ctx do
      listing = offered_listing(ctx.seller)

      assert {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      assert line.seller_id == ctx.seller.id
    end

    test "takes a quantity when one is given", ctx do
      listing = offered_listing(ctx.seller)

      assert {:ok, line} = Carts.add_to_cart(listing.id, %{quantity: 3}, actor: ctx.buyer)
      assert line.quantity == 3
    end

    test "raises the quantity of the line already there rather than adding a second", ctx do
      listing = offered_listing(ctx.seller)

      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 2}, actor: ctx.buyer)
      {:ok, line} = Carts.add_to_cart(listing.id, %{quantity: 3}, actor: ctx.buyer)

      assert line.quantity == 5
      assert [_only_one] = Carts.list_cart!(actor: ctx.buyer)
    end

    test "refuses a quantity of none", ctx do
      listing = offered_listing(ctx.seller)

      assert {:error, %Ash.Error.Invalid{}} =
               Carts.add_to_cart(listing.id, %{quantity: 0}, actor: ctx.buyer)
    end

    test "refuses a listing the buyer cannot see", ctx do
      draft = generate(listing(actor: ctx.seller))

      assert {:error, %Ash.Error.Invalid{}} = Carts.add_to_cart(draft.id, %{}, actor: ctx.buyer)
    end

    test "refuses the seller their own listing, nobody buying from themselves", ctx do
      listing = offered_listing(ctx.seller)

      assert {:error, %Ash.Error.Invalid{}} =
               Carts.add_to_cart(listing.id, %{}, actor: ctx.seller)

      assert Carts.list_cart!(actor: ctx.seller) == []
    end

    test "refuses a visitor carrying nothing to be told apart by", ctx do
      listing = offered_listing(ctx.seller)

      assert {:error, %Ash.Error.Invalid{}} = Carts.add_to_cart(listing.id, %{}, actor: nil)
    end
  end

  describe "reading the cart" do
    test "holds listings from several sellers at once", ctx do
      other_seller = generate(user())
      one = offered_listing(ctx.seller)
      two = offered_listing(other_seller)

      {:ok, _} = Carts.add_to_cart(one.id, %{}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(two.id, %{}, actor: ctx.buyer)

      assert ctx.buyer |> cart_lines() |> Enum.map(& &1.listing_id) |> Enum.sort() ==
               Enum.sort([one.id, two.id])
    end

    test "groups them by seller, each group naming the seller it is for", ctx do
      other_seller = generate(user())
      one = offered_listing(ctx.seller)
      two = offered_listing(ctx.seller)
      three = offered_listing(other_seller)

      for l <- [one, two, three], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      groups = ctx.buyer |> cart_lines() |> Carts.group_by_seller()

      assert length(groups) == 2
      assert Enum.all?(groups, &match?(%Mercato.Accounts.User{}, &1.seller))

      mine = Enum.find(groups, &(&1.seller.id == ctx.seller.id))
      assert length(mine.lines) == 2
    end

    test "loads what a cart line renders", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert [line] = cart_lines(ctx.buyer)
      assert line.listing.title == listing.title
      assert is_binary(line.listing.display_price)
      assert [%{url: url}] = line.listing.images
      assert is_binary(url)
    end

    test "is empty for someone whose cart nothing was added to", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert cart_lines(generate(user())) == []
    end

    test "counts a group by how many of each line the buyer wants", ctx do
      one = offered_listing(ctx.seller, quantity: 5)
      two = offered_listing(ctx.seller, quantity: 5)

      {:ok, _} = Carts.add_to_cart(one.id, %{quantity: 2}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(two.id, %{quantity: 3}, actor: ctx.buyer)

      assert [group] = ctx.buyer |> cart_lines() |> Carts.group_by_seller()
      assert group.item_count == 5
    end

    test "totals a group at what its seller is asking now", ctx do
      one = offered_listing(ctx.seller, price: 1500, quantity: 5)
      two = offered_listing(ctx.seller, price: 4000)

      {:ok, _} = Carts.add_to_cart(one.id, %{quantity: 2}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(two.id, %{}, actor: ctx.buyer)

      assert [group] = ctx.buyer |> cart_lines() |> Carts.group_by_seller()
      assert group.total == "$70.00"
    end

    test "totals one line at its listing's price, as many times as it is wanted", ctx do
      listing = offered_listing(ctx.seller, price: 1500, quantity: 5)
      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 3}, actor: ctx.buyer)

      assert [line] = cart_lines(ctx.buyer)
      assert Carts.line_total(line) == "$45.00"
    end

    test "totals the whole cart across every seller in it", ctx do
      mine = offered_listing(ctx.seller, price: 1500)
      theirs = offered_listing(generate(user()), price: 4000)

      {:ok, _} = Carts.add_to_cart(mine.id, %{}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(theirs.id, %{}, actor: ctx.buyer)

      assert ctx.buyer |> cart_lines() |> Carts.cart_total() == "$55.00"
    end

    test "totals an empty cart at nothing rather than at nowhere", ctx do
      assert cart_lines(ctx.buyer) == []
      assert Carts.cart_total([]) == "$0.00"
    end
  end

  describe "one seller's group of the cart" do
    test "reads the group a checkout is for, and nobody else's lines", ctx do
      other_seller = generate(user())
      one = offered_listing(ctx.seller, price: 1500)
      two = offered_listing(ctx.seller, price: 4000)
      three = offered_listing(other_seller, price: 9900)

      for l <- [one, two, three], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      assert %{} = group = Carts.seller_group(ctx.seller.id, actor: ctx.buyer)
      assert group.seller.id == ctx.seller.id
      assert group.item_count == 2
      assert group.total == "$55.00"
      assert Enum.map(group.lines, & &1.listing_id) |> Enum.sort() == Enum.sort([one.id, two.id])
    end

    test "is absent for a seller the buyer has gathered nothing from", ctx do
      assert Carts.seller_group(generate(user()).id, actor: ctx.buyer) == nil
    end

    test "is absent for a seller that is not one at all", ctx do
      assert Carts.seller_group(Ash.UUID.generate(), actor: ctx.buyer) == nil
    end

    test "is the visitor's own, gathered against their token", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor)

      assert %{} = group = Carts.seller_group(ctx.seller.id, scope: visitor)
      assert [line] = group.lines
      assert line.listing.title == listing.title
    end

    test "is nobody else's to read", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert Carts.seller_group(ctx.seller.id, actor: generate(user())) == nil
      assert Carts.seller_group(ctx.seller.id, scope: visitor()) == nil
    end
  end

  describe "changing what is in the cart" do
    test "sets a line's quantity", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert {:ok, changed} = Carts.set_cart_quantity(line, %{quantity: 4}, actor: ctx.buyer)
      assert changed.quantity == 4
    end

    test "refuses a quantity of none", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert {:error, %Ash.Error.Invalid{}} =
               Carts.set_cart_quantity(line, %{quantity: 0}, actor: ctx.buyer)
    end

    test "removes a line", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert :ok = Carts.remove_from_cart(line, actor: ctx.buyer)
      assert cart_lines(ctx.buyer) == []
    end

    test "is nobody else's to change", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      stranger = generate(user())

      assert {:error, _} = Carts.set_cart_quantity(line, %{quantity: 9}, actor: stranger)
      assert {:error, _} = Carts.remove_from_cart(line, actor: stranger)
    end
  end

  describe "a visitor's cart" do
    test "gathers a listing against the token the visitor carries", ctx do
      listing = offered_listing(ctx.seller)

      assert {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: visitor())
      assert line.user_id == nil
      assert line.listing_id == listing.id
    end

    test "raises the quantity of the line already there rather than adding a second", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()

      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 2}, scope: visitor)
      {:ok, line} = Carts.add_to_cart(listing.id, %{quantity: 3}, scope: visitor)

      assert line.quantity == 5
      assert [_only_one] = Carts.list_cart!(scope: visitor)
    end

    test "reads back to the visitor who gathered it", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor)

      assert [line] = Carts.list_cart!(scope: visitor)
      assert line.listing.title == listing.title
    end

    test "is another visitor's cart no more than it is anyone else's", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor())

      assert Carts.list_cart!(scope: visitor()) == []
      assert Carts.list_cart!(actor: ctx.buyer) == []
    end

    test "is not read by a signed-in buyer carrying no token", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor())

      assert cart_lines(ctx.buyer) == []
    end

    test "is nobody else's to change", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: visitor())

      assert {:error, _} = Carts.set_cart_quantity(line, %{quantity: 9}, scope: visitor())
      assert {:error, _} = Carts.remove_from_cart(line, actor: ctx.buyer)
    end

    test "is the visitor's own to change and to empty", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: visitor)

      assert {:ok, changed} = Carts.set_cart_quantity(line, %{quantity: 4}, scope: visitor)
      assert changed.quantity == 4
      assert :ok = Carts.remove_from_cart(changed, scope: visitor)
      assert Carts.list_cart!(scope: visitor) == []
    end

    test "belongs to the account rather than the token once there is an account", ctx do
      listing = offered_listing(ctx.seller)
      scope = %{visitor() | user: ctx.buyer}

      assert {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: scope)
      assert line.user_id == ctx.buyer.id
      assert cart_lines(ctx.buyer) != []
    end
  end

  describe "signing in" do
    test "carries what the visitor had gathered into their account's cart", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 2}, scope: visitor)

      assert :ok = Carts.claim_cart(ctx.buyer, visitor.guest_token)

      assert [line] = cart_lines(ctx.buyer)
      assert line.listing_id == listing.id
      assert line.quantity == 2
    end

    test "sums a line the account already had with the one gathered as a visitor", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 2}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(listing.id, %{quantity: 3}, scope: visitor)

      assert :ok = Carts.claim_cart(ctx.buyer, visitor.guest_token)

      assert [line] = cart_lines(ctx.buyer)
      assert line.quantity == 5
    end

    test "leaves nothing behind against the token", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor)

      assert :ok = Carts.claim_cart(ctx.buyer, visitor.guest_token)
      assert Carts.list_cart!(scope: visitor) == []
    end

    test "drops a listing that stopped being buyable rather than failing", ctx do
      gone = offered_listing(ctx.seller)
      still_there = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(gone.id, %{}, scope: visitor)
      {:ok, _} = Carts.add_to_cart(still_there.id, %{}, scope: visitor)

      Mercato.Listings.pause_listing!(gone, actor: ctx.seller)

      assert :ok = Carts.claim_cart(ctx.buyer, visitor.guest_token)

      assert [line] = cart_lines(ctx.buyer)
      assert line.listing_id == still_there.id
    end

    test "is untroubled by a visitor who gathered nothing", ctx do
      assert :ok = Carts.claim_cart(ctx.buyer, Carts.new_guest_token())
      assert cart_lines(ctx.buyer) == []
    end
  end

  describe "a listing the buyer turns out to be the seller of" do
    test "is dropped when they sign in, a sign-in failing over nothing", ctx do
      mine = offered_listing(ctx.seller)
      theirs = offered_listing(generate(user()))
      visitor = Scope.for_user(nil, "guest-token-of-the-seller")

      {:ok, _} = Carts.add_to_cart(mine.id, %{}, scope: visitor)
      {:ok, _} = Carts.add_to_cart(theirs.id, %{}, scope: visitor)

      :ok = Carts.claim_cart(ctx.seller, "guest-token-of-the-seller")

      assert [line] = Carts.list_cart!(actor: ctx.seller)
      assert line.listing_id == theirs.id
    end
  end

  describe "a listing that stops being buyable" do
    test "keeps the line, so the buyer learns what happened to it", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      Mercato.Listings.pause_listing!(listing, actor: ctx.seller)

      assert [line] = cart_lines(ctx.buyer)
      assert line.listing.title == listing.title
      refute Carts.line_buyable?(line)
    end

    test "reads as unbuyable once it has sold to somebody else", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      Mercato.Listings.mark_listing_sold!(listing)

      assert [line] = cart_lines(ctx.buyer)
      refute Carts.line_buyable?(line)
    end

    test "reads as unbuyable once the seller has run out", ctx do
      listing = offered_listing(ctx.seller, quantity: 1)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      Mercato.Listings.update_listing!(listing, %{quantity: 0}, actor: ctx.seller)

      assert [line] = cart_lines(ctx.buyer)
      refute Carts.line_buyable?(line)
    end

    test "counts for nothing in what its group comes to", ctx do
      gone = offered_listing(ctx.seller, price: 4000)
      still_there = offered_listing(ctx.seller, price: 1500)

      for l <- [gone, still_there], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      Mercato.Listings.pause_listing!(gone, actor: ctx.seller)

      assert [group] = ctx.buyer |> cart_lines() |> Carts.group_by_seller()
      assert group.total == "$15.00"
      assert group.item_count == 1
      assert length(group.lines) == 2
      assert ctx.buyer |> cart_lines() |> Carts.cart_total() == "$15.00"
    end

    test "stops its group being checked out until the buyer clears it", ctx do
      gone = offered_listing(ctx.seller)
      still_there = offered_listing(ctx.seller)

      for l <- [gone, still_there], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      Mercato.Listings.pause_listing!(gone, actor: ctx.seller)

      assert %{buyable?: false} = Carts.seller_group(ctx.seller.id, actor: ctx.buyer)
    end

    test "leaves a group of buyable lines checkable out", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)

      assert %{buyable?: true} = Carts.seller_group(ctx.seller.id, actor: ctx.buyer)
    end

    test "is still the visitor's own to see and to remove", ctx do
      listing = offered_listing(ctx.seller)
      visitor = visitor()
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, scope: visitor)

      Mercato.Listings.pause_listing!(listing, actor: ctx.seller)

      assert [line] = Carts.list_cart!(scope: visitor)
      assert line.listing.title == listing.title
      assert :ok = Carts.remove_from_cart(line, scope: visitor)
    end

    test "is nobody else's to see through a cart they do not hold", ctx do
      listing = offered_listing(ctx.seller)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      Mercato.Listings.pause_listing!(listing, actor: ctx.seller)

      stranger = generate(user())

      assert {:error, _} =
               Mercato.Listings.get_listing_for_cart_line(listing.id, actor: stranger)
    end
  end

  describe "a listing the seller deletes" do
    test "goes from the carts holding it rather than refusing to be deleted", ctx do
      listing = offered_listing(ctx.seller)
      other_buyer = generate(user())
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
      {:ok, _} = Carts.add_to_cart(listing.id, %{}, actor: other_buyer)

      assert :ok = Mercato.Listings.delete_listing(listing, actor: ctx.seller)

      assert cart_lines(ctx.buyer) == []
      assert cart_lines(other_buyer) == []
    end

    test "leaves the rest of the cart alone", ctx do
      gone = offered_listing(ctx.seller)
      kept = offered_listing(ctx.seller)

      for l <- [gone, kept], do: {:ok, _} = Carts.add_to_cart(l.id, %{}, actor: ctx.buyer)

      assert :ok = Mercato.Listings.delete_listing(gone, actor: ctx.seller)

      assert [line] = cart_lines(ctx.buyer)
      assert line.listing_id == kept.id
    end
  end

  defp cart_lines(actor), do: Carts.list_cart!(actor: actor)

  defp visitor, do: Scope.for_user(nil, Carts.new_guest_token())
end
