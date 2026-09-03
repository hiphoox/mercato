defmodule Mercato.Payments.SellerDeductionTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Payments
  alias Mercato.Payments.SellerDeduction

  defp error_for(%Ash.Error.Invalid{errors: errors}, field) do
    Enum.find(errors, &(&1.field == field))
  end

  defp flat(name, amount, opts \\ []) do
    Payments.add_seller_deduction!(
      %{name: name, kind: :flat, amount: amount},
      Keyword.put_new(opts, :authorize?, false)
    )
  end

  defp percentage(name, rate_bp, opts \\ []) do
    {of, opts} = Keyword.pop(opts, :of)

    Payments.add_seller_deduction!(
      %{name: name, kind: :percentage, rate_bp: rate_bp, of_id: of && of.id},
      Keyword.put_new(opts, :authorize?, false)
    )
  end

  describe "what a row may be" do
    test "a flat amount off every sale" do
      assert %SellerDeduction{name: "Listing fee", kind: :flat, amount: 99} =
               flat("Listing fee", 99)
    end

    test "a percentage of the sale price" do
      assert %SellerDeduction{kind: :percentage, rate_bp: 1000, of_id: nil} =
               percentage("Commission", 1000)
    end

    test "a percentage of another row's amount" do
      commission = percentage("Commission", 1000)

      assert %SellerDeduction{of_id: of_id} = percentage("VAT", 2100, of: commission)
      assert of_id == commission.id
    end

    test "refuses a flat row with no amount" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(%{name: "Listing fee", kind: :flat},
                 authorize?: false
               )
    end

    test "refuses a flat row carrying a rate, which would say two things at once" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(
                 %{name: "Listing fee", kind: :flat, amount: 99, rate_bp: 1000},
                 authorize?: false
               )
    end

    test "refuses a percentage row with no rate" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(%{name: "Commission", kind: :percentage},
                 authorize?: false
               )
    end

    test "refuses a percentage row carrying an amount" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(
                 %{name: "Commission", kind: :percentage, rate_bp: 1000, amount: 99},
                 authorize?: false
               )
    end

    test "refuses a flat row that names something to be a percentage of" do
      commission = percentage("Commission", 1000)

      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(
                 %{name: "Listing fee", kind: :flat, amount: 99, of_id: commission.id},
                 authorize?: false
               )
    end

    test "refuses a rate above the whole sale" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(
                 %{name: "Commission", kind: :percentage, rate_bp: 10_001},
                 authorize?: false
               )
    end

    test "refuses a row with no name, since a deduction is read by the name it is given" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(%{kind: :flat, amount: 99}, authorize?: false)
    end

    test "refuses a second row by the same name" do
      flat("Listing fee", 99)

      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_seller_deduction(%{name: "Listing fee", kind: :flat, amount: 50},
                 authorize?: false
               )
    end
  end

  describe "breakdown/1" do
    test "deducts nothing from a marketplace that has configured no rows" do
      assert SellerDeduction.breakdown(10_000) == %{lines: [], total: 0}
    end

    test "takes a flat row whatever the sale came to" do
      flat("Listing fee", 99)

      assert %{lines: [%{name: "Listing fee", amount: 99}], total: 99} =
               SellerDeduction.breakdown(10_000)

      assert %{total: 99} = SellerDeduction.breakdown(500)
    end

    test "takes a percentage row off the sale price" do
      percentage("Commission", 1000)

      assert %{lines: [%{name: "Commission", amount: 1000}], total: 1000} =
               SellerDeduction.breakdown(10_000)
    end

    test "stacks a jurisdiction's tax on the commission it is charged on" do
      commission = percentage("Commission", 1000)
      percentage("VAT", 2100, of: commission)

      assert %{
               lines: [
                 %{name: "Commission", amount: 1000},
                 %{name: "VAT", amount: 210}
               ],
               total: 1210
             } = SellerDeduction.breakdown(10_000)
    end

    test "reads a row that is a percentage of one added after it" do
      vat = percentage("VAT", 2100)
      percentage("Surcharge", 5000, of: vat)

      assert %{total: 3150} = SellerDeduction.breakdown(10_000)
    end

    test "rounds a half minor unit up rather than losing it" do
      percentage("Commission", 250)

      assert %{total: 26} = SellerDeduction.breakdown(1030)
    end

    test "lists the rows in the order they were added" do
      flat("Listing fee", 99)
      percentage("Commission", 1000)

      assert %{lines: [%{name: "Listing fee"}, %{name: "Commission"}]} =
               SellerDeduction.breakdown(10_000)
    end
  end

  describe "editing a row" do
    test "changes what the row takes" do
      commission = percentage("Commission", 1000)

      assert %SellerDeduction{rate_bp: 500} =
               Payments.edit_seller_deduction!(commission, %{rate_bp: 500}, authorize?: false)

      assert %{total: 500} = SellerDeduction.breakdown(10_000)
    end

    test "changes what a row is a percentage of" do
      commission = percentage("Commission", 1000)
      vat = percentage("VAT", 2100, of: commission)

      Payments.edit_seller_deduction!(vat, %{of_id: nil}, authorize?: false)

      assert %{total: 3100} = SellerDeduction.breakdown(10_000)
    end

    test "refuses a row that would end up a percentage of itself" do
      commission = percentage("Commission", 1000)

      assert {:error, invalid} =
               Payments.edit_seller_deduction(commission, %{of_id: commission.id},
                 authorize?: false
               )

      assert error_for(invalid, :of_id).message =~ "percentage of itself"
    end

    test "refuses a chain of rows that would close on itself" do
      commission = percentage("Commission", 1000)
      vat = percentage("VAT", 2100, of: commission)

      assert {:error, invalid} =
               Payments.edit_seller_deduction(commission, %{of_id: vat.id}, authorize?: false)

      assert error_for(invalid, :of_id).message =~ "percentage of itself"
    end
  end

  describe "removing a row" do
    test "drops it from what is deducted" do
      commission = percentage("Commission", 1000)

      assert :ok = Payments.remove_seller_deduction(commission, authorize?: false)
      assert %{lines: [], total: 0} = SellerDeduction.breakdown(10_000)
    end

    test "refuses while another row is a percentage of it" do
      commission = percentage("Commission", 1000)
      percentage("VAT", 2100, of: commission)

      assert {:error, invalid} = Payments.remove_seller_deduction(commission, authorize?: false)
      assert error_for(invalid, :name).message =~ "another deduction is a percentage of"
    end
  end

  describe "who may change them" do
    test "an operator holding settings:update may add a row" do
      operator = admin_user() |> grant_permission("settings:update")

      assert %SellerDeduction{} = flat("Listing fee", 99, actor: operator, authorize?: true)
    end

    test "an ordinary account may not" do
      seller = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} =
               Payments.add_seller_deduction(%{name: "Listing fee", kind: :flat, amount: 99},
                 actor: seller
               )
    end

    test "anyone may read them, since a seller sees what a sale costs them before they have one" do
      flat("Listing fee", 99)

      assert {:ok, [%SellerDeduction{}]} = Payments.list_seller_deductions()
    end
  end
end
