defmodule Mercato.Orders.OrderPolicyTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Orders

  setup do
    seller = generate(user())
    buyer = generate(user())
    listing = offered_listing(seller)

    order = Orders.place_order!(listing.id, %{}, actor: buyer)

    %{seller: seller, buyer: buyer, order: order}
  end

  describe "who may read an order" do
    test "the buyer who placed it", %{buyer: buyer, order: order} do
      assert Orders.get_order!(order.id, actor: buyer).id == order.id
    end

    test "the seller who is fulfilling it", %{seller: seller, order: order} do
      assert Orders.get_order!(order.id, actor: seller).id == order.id
    end

    test "an admin, whoever the parties are", %{order: order} do
      admin = admin_user()

      assert Orders.get_order!(order.id, actor: admin).id == order.id
    end

    test "nobody else, and not as a refusal", %{order: order} do
      stranger = generate(user())

      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Orders.get_order(order.id, actor: stranger)
    end

    test "not a signed-out visitor", %{order: order} do
      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Query.NotFound{}]}} =
               Orders.get_order(order.id)
    end

    test "an order is absent from a stranger's list rather than an error" do
      stranger = generate(user())

      assert Orders.list_orders!(actor: stranger) == []
    end

    test "an order is present in each party's list", %{buyer: buyer, seller: seller, order: order} do
      assert Enum.map(Orders.list_orders!(actor: buyer), & &1.id) == [order.id]
      assert Enum.map(Orders.list_orders!(actor: seller), & &1.id) == [order.id]
    end
  end
end
