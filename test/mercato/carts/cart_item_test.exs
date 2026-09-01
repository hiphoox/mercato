defmodule Mercato.Carts.CartItemTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

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

    test "refuses a visitor acting as nobody", ctx do
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

  defp cart_lines(actor), do: Carts.list_cart!(actor: actor)
end
