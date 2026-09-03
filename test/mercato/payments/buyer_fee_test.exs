defmodule Mercato.Payments.BuyerFeeTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Payments
  alias Mercato.Payments.BuyerFee

  defp flat(name, amount, opts \\ []) do
    Payments.add_buyer_fee!(
      %{name: name, kind: :flat, amount: amount},
      Keyword.put_new(opts, :authorize?, false)
    )
  end

  defp percentage(name, rate_bp, opts \\ []) do
    Payments.add_buyer_fee!(
      %{name: name, kind: :percentage, rate_bp: rate_bp},
      Keyword.put_new(opts, :authorize?, false)
    )
  end

  describe "what a row may be" do
    test "a flat amount on every purchase" do
      assert %BuyerFee{name: "Protection", kind: :flat, amount: 199} = flat("Protection", 199)
    end

    test "a percentage of the sale price" do
      assert %BuyerFee{kind: :percentage, rate_bp: 500} = percentage("Protection", 500)
    end

    test "refuses a flat row with no amount" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(%{name: "Protection", kind: :flat}, authorize?: false)
    end

    test "refuses a flat row carrying a rate, which would say two things at once" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(
                 %{name: "Protection", kind: :flat, amount: 199, rate_bp: 500},
                 authorize?: false
               )
    end

    test "refuses a percentage row with no rate" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(%{name: "Protection", kind: :percentage}, authorize?: false)
    end

    test "refuses a percentage row carrying an amount" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(
                 %{name: "Protection", kind: :percentage, rate_bp: 500, amount: 199},
                 authorize?: false
               )
    end

    test "refuses a rate above the whole sale" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(%{name: "Protection", kind: :percentage, rate_bp: 10_001},
                 authorize?: false
               )
    end

    test "refuses a row with no name, since a fee is read by the name it is given" do
      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(%{kind: :flat, amount: 199}, authorize?: false)
    end

    test "refuses a second row by the same name" do
      flat("Protection", 199)

      assert {:error, %Ash.Error.Invalid{}} =
               Payments.add_buyer_fee(%{name: "Protection", kind: :flat, amount: 50},
                 authorize?: false
               )
    end
  end

  describe "breakdown/1" do
    test "adds nothing for a marketplace that has configured no rows" do
      assert BuyerFee.breakdown(10_000) == %{lines: [], total: 0}
    end

    test "adds a flat row whatever the sale came to" do
      flat("Protection", 199)

      assert %{lines: [%{name: "Protection", amount: 199}], total: 199} =
               BuyerFee.breakdown(10_000)
    end

    test "adds a percentage of the sale price" do
      percentage("Protection", 500)

      assert %{lines: [%{name: "Protection", amount: 500}], total: 500} =
               BuyerFee.breakdown(10_000)
    end

    test "adds up every configured row, in the order they were added" do
      flat("Protection", 199)
      percentage("Handling", 500)

      assert %{
               lines: [%{name: "Protection", amount: 199}, %{name: "Handling", amount: 500}],
               total: 699
             } = BuyerFee.breakdown(10_000)
    end

    test "rounds a half minor unit up rather than losing it" do
      percentage("Protection", 250)

      assert %{total: 26} = BuyerFee.breakdown(1030)
    end
  end

  describe "editing and removing a row" do
    test "changes what the row adds" do
      protection = percentage("Protection", 500)

      assert %BuyerFee{rate_bp: 250} =
               Payments.edit_buyer_fee!(protection, %{rate_bp: 250}, authorize?: false)

      assert %{total: 250} = BuyerFee.breakdown(10_000)
    end

    test "drops a removed row from what is added" do
      protection = percentage("Protection", 500)

      assert :ok = Payments.remove_buyer_fee(protection, authorize?: false)
      assert %{lines: [], total: 0} = BuyerFee.breakdown(10_000)
    end
  end

  describe "who may change them" do
    test "an operator holding settings:update may add a row" do
      operator = admin_user() |> grant_permission("settings:update")

      assert %BuyerFee{} = flat("Protection", 199, actor: operator, authorize?: true)
    end

    test "an ordinary account may not" do
      buyer = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} =
               Payments.add_buyer_fee(%{name: "Protection", kind: :flat, amount: 199},
                 actor: buyer
               )
    end

    test "anyone may read them, since a visitor with no account is shown what they would pay" do
      flat("Protection", 199)

      assert {:ok, [%BuyerFee{}]} = Payments.list_buyer_fees()
    end
  end
end
