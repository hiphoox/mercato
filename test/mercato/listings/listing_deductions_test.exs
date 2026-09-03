defmodule Mercato.Listings.ListingDeductionsTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings
  alias Mercato.Payments
  alias Mercato.Payments.Deduction

  defp commission(rate_bp) do
    Payments.add_seller_deduction!(
      %{name: "Commission", kind: :percentage, rate_bp: rate_bp},
      authorize?: false
    )
  end

  describe "the deductions a listing takes" do
    test "copies what the marketplace deducts when the listing is created" do
      commission(1000)

      assert %{deductions: [%Deduction{name: "Commission", kind: :percentage, rate_bp: 1000}]} =
               generate(listing())
    end

    test "copies nothing where the marketplace deducts nothing" do
      assert %{deductions: []} = generate(listing())
    end

    test "reads back as it was written, over a listing fetched afresh" do
      commission = commission(1000)

      Payments.add_seller_deduction!(
        %{name: "VAT", kind: :percentage, rate_bp: 2100, of_id: commission.id},
        authorize?: false
      )

      seller = generate(user())
      listing = generate(listing(actor: seller))

      assert {:ok, %{deductions: deductions}} =
               Listings.get_my_listing(listing.id, actor: seller)

      assert [
               %Deduction{name: "Commission", of: nil},
               %Deduction{name: "VAT", of: "Commission"}
             ] = deductions
    end

    test "stands still when the marketplace changes what it deducts afterwards" do
      commission = commission(1000)
      listing = generate(listing())

      Payments.edit_seller_deduction!(commission, %{rate_bp: 2500}, authorize?: false)

      assert %{deductions: [%Deduction{rate_bp: 1000}]} = Ash.reload!(listing, authorize?: false)
    end

    test "stands still when the listing is edited" do
      commission(1000)
      seller = generate(user())
      listing = generate(listing(actor: seller))

      Payments.remove_seller_deduction!(hd(Payments.list_seller_deductions!(authorize?: false)),
        authorize?: false
      )

      assert {:ok, %{deductions: [%Deduction{name: "Commission"}]}} =
               Listings.update_listing(listing, %{price: 5000}, actor: seller)
    end

    test "is refused outright as something a seller supplies" do
      seller = generate(user())

      assert {:error, %Ash.Error.Invalid{errors: [%Ash.Error.Invalid.NoSuchInput{}]}} =
               Listings.create_listing(
                 %{
                   title: "A chair",
                   price: 1000,
                   category_id: generate(category()).id,
                   deductions: [%{name: "Nothing at all", kind: :flat, amount: 0}]
                 },
                 actor: seller
               )
    end
  end

  describe "what a listing leaves its seller" do
    test "is the price, less what the listing's own copy takes" do
      commission(1000)
      listing = generate(listing(price: 10_000))

      assert %{
               lines: [%{name: "Commission", amount: 1000}],
               total: 1000,
               net: 9000
             } = Deduction.breakdown(listing.deductions, listing.price)
    end

    test "follows the price the seller repriced to, not the one they listed at" do
      commission(1000)
      listing = generate(listing(price: 10_000))

      assert %{total: 500, net: 4500} = Deduction.breakdown(listing.deductions, 5000)
    end
  end
end
