defmodule Mercato.Orders.OrderTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Orders

  setup do
    seller = generate(user())
    buyer = generate(user())

    %{seller: seller, buyer: buyer, listing: offered_listing(seller, price: 2500)}
  end

  describe "placing an order" do
    test "records who bought what from whom", ctx do
      order = place!(ctx)

      assert order.buyer_id == ctx.buyer.id
      assert order.seller_id == ctx.seller.id
      assert order.listing_id == ctx.listing.id
    end

    test "starts as placed", ctx do
      assert place!(ctx).status == :placed
    end

    test "buys one unit unless the buyer says otherwise", ctx do
      assert place!(ctx).quantity == 1
      assert place!(ctx, quantity: 3).quantity == 3
    end

    test "records when it was created and last changed", ctx do
      order = place!(ctx)

      assert %DateTime{} = order.inserted_at
      assert %DateTime{} = order.updated_at
    end

    test "refuses a quantity of none", ctx do
      assert {:error, %Ash.Error.Invalid{}} = place(ctx, quantity: 0)
    end

    test "refuses a listing the buyer cannot see", ctx do
      draft = generate(listing(actor: ctx.seller))

      assert {:error, %Ash.Error.Invalid{}} =
               Orders.place_order(draft.id, %{}, actor: ctx.buyer)
    end

    test "refuses a placement with nobody acting", ctx do
      # The buyer is the actor, so there is nothing to relate the order to.
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Changes.InvalidRelationship{}]}} =
               Orders.place_order(ctx.listing.id, %{})
    end
  end

  describe "the price agreed at purchase" do
    test "is copied off the listing rather than read back from it", ctx do
      order = place!(ctx)

      assert order.unit_price == 2500

      Mercato.Listings.update_listing!(ctx.listing, %{price: 9900}, actor: ctx.seller)

      assert Orders.get_order!(order.id, actor: ctx.buyer).unit_price == 2500
    end

    test "is stamped with the currency in force", ctx do
      assert place!(ctx).currency == Mercato.Listings.currency()
    end

    test "is not something the buyer supplies", ctx do
      assert {:error, %Ash.Error.Invalid{}} = place(ctx, unit_price: 1)
    end

    test "totals the units bought", ctx do
      order = place!(ctx, quantity: 4)

      assert Ash.load!(order, :total_price, actor: ctx.buyer).total_price == 10_000
    end
  end

  describe "one order, one seller" do
    test "takes the seller from the listing", ctx do
      assert place!(ctx).seller_id == ctx.seller.id
    end

    test "is not something the buyer supplies", ctx do
      assert {:error, %Ash.Error.Invalid{}} = place(ctx, seller_id: generate(user()).id)
    end
  end

  describe "the public reference" do
    test "is a uuid, so nothing has to guard against two orders sharing one", ctx do
      public_id = place!(ctx).public_id

      assert {:ok, ^public_id} = Ash.Type.cast_input(Ash.Type.UUID, public_id, [])
    end

    test "names the order in its own right", ctx do
      order = place!(ctx)

      assert Orders.get_order_by_public_id!(order.public_id, actor: ctx.buyer).id == order.id
    end

    test "is not something the buyer supplies", ctx do
      assert {:error, %Ash.Error.Invalid{}} = place(ctx, public_id: Ash.UUID.generate())
    end
  end

  defp place(ctx, params) do
    Orders.place_order(ctx.listing.id, Map.new(params), actor: ctx.buyer)
  end

  defp place!(ctx, params \\ []) do
    Orders.place_order!(ctx.listing.id, Map.new(params), actor: ctx.buyer)
  end
end
