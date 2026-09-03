defmodule Mercato.Payments do
  @moduledoc """
  Domain for the money in a sale: what the platform takes off a seller's
  earnings, and what it adds to what a buyer pays.

  Both are named rows an operator configures rather than rules in code, and the
  two are separate tables because they are separate decisions — a marketplace
  charging a commission and one charging a buyer's protection fee are not the
  same marketplace, and either may charge neither.
  """

  use Ash.Domain,
    otp_app: :mercato

  resources do
    resource Mercato.Payments.SellerDeduction do
      define :list_seller_deductions, action: :ordered
      define :add_seller_deduction, action: :add
      define :edit_seller_deduction, action: :edit
      define :remove_seller_deduction, action: :remove
    end

    resource Mercato.Payments.BuyerFee do
      define :list_buyer_fees, action: :ordered
      define :add_buyer_fee, action: :add
      define :edit_buyer_fee, action: :edit
      define :remove_buyer_fee, action: :remove
    end
  end
end
