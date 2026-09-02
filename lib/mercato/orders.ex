defmodule Mercato.Orders do
  @moduledoc """
  Domain for the purchase a buyer makes on a listing and the record it leaves.
  """

  use Ash.Domain, otp_app: :mercato

  resources do
    resource Mercato.Orders.Order do
      define :place_order, action: :place, args: [:listing_id]
      define :list_orders, action: :read
      define :get_order, action: :get, get_by: [:id]
      define :get_order_by_public_id, action: :get_by_public_id, get_by: [:public_id]
    end
  end
end
