defmodule Mercato.Carts.CartRetentionTest do
  @moduledoc """
  How long a line stays in a cart before it is dropped, and what dropping it
  looks like to the buyer whose cart it was.
  """

  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts.Scope
  alias Mercato.Carts

  # A window measured in seconds, so ageing a line past it is a matter of
  # seconds rather than of pretending a month went by.
  @window 60

  setup do
    put_setting(:cart_retention_seconds, @window)

    %{buyer: generate(user()), seller: generate(user())}
  end

  describe "reading a cart" do
    test "keeps a line touched inside the retention window", ctx do
      line = carted(ctx)
      age(line, @window - 10)

      assert [kept] = Carts.list_cart!(actor: ctx.buyer)
      assert kept.id == line.id
    end

    test "drops a line untouched for longer than the window", ctx do
      line = carted(ctx)
      age(line, @window + 10)

      assert Carts.list_cart!(actor: ctx.buyer) == []
    end

    test "takes the dropped line out of the cart for good", ctx do
      line = carted(ctx)
      age(line, @window + 10)

      Carts.list_cart!(actor: ctx.buyer)

      assert lines_left() == 0
    end

    test "follows the window the marketplace is set to", ctx do
      line = carted(ctx)
      age(line, @window - 10)

      put_setting(:cart_retention_seconds, 5)

      assert Carts.list_cart!(actor: ctx.buyer) == []
    end

    test "drops a visitor's line the same way", ctx do
      visitor = Scope.for_user(nil, Carts.new_guest_token())
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: visitor)
      age(line, @window + 10)

      assert Carts.list_cart!(scope: visitor) == []
    end

    test "clears lines nobody is coming back for, whosever they are", ctx do
      abandoned = Scope.for_user(nil, Carts.new_guest_token())
      listing = offered_listing(ctx.seller)
      {:ok, line} = Carts.add_to_cart(listing.id, %{}, scope: abandoned)
      age(line, @window + 10)

      Carts.list_cart!(actor: ctx.buyer)

      assert lines_left() == 0
    end

    test "drops an expired line from a seller's group too", ctx do
      line = carted(ctx)
      age(line, @window + 10)

      assert Carts.list_seller_cart!(ctx.seller.id, actor: ctx.buyer) == []
      assert Carts.seller_group(ctx.seller.id, actor: ctx.buyer) == nil
    end

    test "says a group emptied by lapsing lapsed, rather than that it went", ctx do
      line = carted(ctx)
      age(line, @window + 10)

      assert Carts.checkout_group(ctx.seller.id, actor: ctx.buyer) == {:error, :lapsed}
    end

    test "says a group the buyer never had is gone rather than lapsed", ctx do
      assert Carts.checkout_group(ctx.seller.id, actor: ctx.buyer) == {:error, :gone}
    end

    test "checks out the lines that have not lapsed", ctx do
      lapsed = carted(ctx)
      age(lapsed, @window + 10)
      kept = carted(ctx)

      assert {:ok, %{lines: [line]}} = Carts.checkout_group(ctx.seller.id, actor: ctx.buyer)
      assert line.id == kept.id
    end
  end

  describe "what renews a line" do
    test "changing how many the buyer wants", ctx do
      line = carted(ctx)
      age(line, @window + 10)

      {:ok, renewed} = Carts.set_cart_quantity(line, %{quantity: 2}, actor: ctx.buyer)

      assert [kept] = Carts.list_cart!(actor: ctx.buyer)
      assert kept.id == renewed.id
    end

    test "adding the same listing again", ctx do
      line = carted(ctx)
      age(line, @window - 10)

      {:ok, _} = Carts.add_to_cart(line.listing_id, %{}, actor: ctx.buyer)

      assert [kept] = Carts.list_cart!(actor: ctx.buyer)
      assert kept.id == line.id
      assert DateTime.after?(kept.updated_at, Carts.retention_cutoff())
    end

    test "a lapsed line is not resurrected by re-adding its listing", ctx do
      line = carted(ctx)
      {:ok, _} = Carts.set_cart_quantity(line, %{quantity: 4}, actor: ctx.buyer)
      age(line, @window + 10)

      {:ok, _} = Carts.add_to_cart(line.listing_id, %{}, actor: ctx.buyer)

      assert [fresh] = Carts.list_cart!(actor: ctx.buyer)
      assert fresh.quantity == 1
      assert fresh.id != line.id
    end
  end

  defp carted(ctx) do
    listing = offered_listing(ctx.seller)
    {:ok, line} = Carts.add_to_cart(listing.id, %{}, actor: ctx.buyer)
    line
  end

  defp age(line, seconds), do: age_cart_line(line, seconds)

  defp lines_left, do: Mercato.Repo.aggregate(Carts.CartItem, :count)
end
