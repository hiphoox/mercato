defmodule Mercato.Orders.OrderStatusTest do
  use ExUnit.Case, async: true

  alias Mercato.Orders.Order.Status

  describe "states" do
    test "covers placement, fulfillment, completion and cancellation" do
      assert Status.values() == [:placed, :fulfilled, :completed, :cancelled]
    end

    test "an order that has finished goes nowhere" do
      assert Status.terminal() == [:completed, :cancelled]
    end
  end

  describe "permitted transitions" do
    test "a placed order is fulfilled or cancelled" do
      assert Status.can_transition?(:placed, :fulfilled)
      assert Status.can_transition?(:placed, :cancelled)
    end

    test "a fulfilled order completes" do
      assert Status.can_transition?(:fulfilled, :completed)
    end

    test "cancelling is off the table once the seller has fulfilled" do
      refute Status.can_transition?(:fulfilled, :cancelled)
    end

    test "a placed order cannot skip fulfillment" do
      refute Status.can_transition?(:placed, :completed)
    end

    test "a terminal order moves nowhere at all" do
      for from <- Status.terminal(), to <- Status.values() do
        refute Status.can_transition?(from, to)
      end
    end
  end
end
