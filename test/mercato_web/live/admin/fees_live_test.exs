defmodule MercatoWeb.Admin.FeesLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers
  alias Mercato.Payments
  alias Mercato.Payments.SellerDeduction

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  defp operator, do: admin_user() |> grant_permission("settings:update")

  defp open(conn), do: live(log_in(conn, operator()), ~p"/admin/fees")

  defp deduction(attrs), do: Payments.add_seller_deduction!(attrs, authorize?: false)

  defp fee(attrs), do: Payments.add_buyer_fee!(attrs, authorize?: false)

  # The panel is one markup tree either way; open is what its own class says,
  # not what anything inside it happens to be styled with.
  defp open?(view, sheet), do: has_element?(view, "##{sheet}.flex")

  describe "access" do
    test "redirects a signed-out visitor to sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/admin/fees")
    end

    test "redirects a signed-in user without admin:access away", %{conn: conn} do
      trader = generate(user())

      assert {:error, {:redirect, %{to: "/"}}} = live(log_in(conn, trader), ~p"/admin/fees")
    end

    test "lets an operator in", %{conn: conn} do
      {:ok, _view, html} = open(conn)

      assert html =~ "Fees and deductions"
    end
  end

  describe "what is configured" do
    test "says a marketplace taking nothing takes nothing", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      assert has_element?(view, "#seller-deductions-empty")
      assert has_element?(view, "#buyer-fees-empty")
    end

    test "lists a flat deduction and what it takes", %{conn: conn} do
      row = deduction(%{name: "Listing fee", kind: :flat, amount: 199})

      {:ok, view, _html} = open(conn)

      refute has_element?(view, "#seller-deductions-empty")
      assert view |> element("#seller-deduction-#{row.id}") |> render() =~ "Listing fee"
      assert view |> element("#seller-deduction-#{row.id}") |> render() =~ "$1.99"
    end

    test "lists a percentage deduction and what it is a percentage of", %{conn: conn} do
      commission = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})
      vat = deduction(%{name: "VAT", kind: :percentage, rate_bp: 2100, of_id: commission.id})

      {:ok, view, _html} = open(conn)

      assert view |> element("#seller-deduction-#{commission.id}") |> render() =~ "10%"
      assert view |> element("#seller-deduction-#{commission.id}") |> render() =~ "Sale price"
      assert view |> element("#seller-deduction-#{vat.id}") |> render() =~ "Commission"
    end

    test "lists a buyer fee", %{conn: conn} do
      row = fee(%{name: "Protection", kind: :percentage, rate_bp: 500})

      {:ok, view, _html} = open(conn)

      assert view |> element("#buyer-fee-#{row.id}") |> render() =~ "Protection"
      assert view |> element("#buyer-fee-#{row.id}") |> render() =~ "5%"
    end
  end

  describe "adding a row" do
    test "adds a flat deduction typed in major units", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      assert view
             |> form("#seller-deduction-form",
               seller_deduction: %{"name" => "Listing fee", "kind" => "flat", "amount" => "1.99"}
             )
             |> render_submit() =~ "Listing fee"

      assert [%{name: "Listing fee", kind: :flat, amount: 199}] =
               Payments.list_seller_deductions!(authorize?: false)
    end

    test "adds a percentage deduction typed as a percentage", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      # Picking the kind is what reveals the field it takes: an operator is
      # asked for an amount or a percentage, never both.
      view
      |> form("#seller-deduction-form", seller_deduction: %{"kind" => "percentage"})
      |> render_change()

      view
      |> form("#seller-deduction-form",
        seller_deduction: %{"name" => "Commission", "kind" => "percentage", "rate_bp" => "10"}
      )
      |> render_submit()

      assert [%{kind: :percentage, rate_bp: 1000, of_id: nil}] =
               Payments.list_seller_deductions!(authorize?: false)
    end

    test "adds a deduction that is a percentage of another one", %{conn: conn} do
      commission = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})

      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      view
      |> form("#seller-deduction-form", seller_deduction: %{"kind" => "percentage"})
      |> render_change()

      view
      |> form("#seller-deduction-form",
        seller_deduction: %{
          "name" => "VAT",
          "kind" => "percentage",
          "rate_bp" => "21",
          "of_id" => commission.id
        }
      )
      |> render_submit()

      assert %{total: 1210} = SellerDeduction.breakdown(10_000)
    end

    test "adds a buyer fee", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-buyer-fee") |> render_click()

      view
      |> form("#buyer-fee-form",
        buyer_fee: %{"name" => "Protection", "kind" => "flat", "amount" => "0.99"}
      )
      |> render_submit()

      assert [%{name: "Protection", amount: 99}] = Payments.list_buyer_fees!(authorize?: false)
    end

    test "says what was wrong with an amount it could not read", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      html =
        view
        |> form("#seller-deduction-form",
          seller_deduction: %{"name" => "Listing fee", "kind" => "flat", "amount" => "a lot"}
        )
        |> render_submit()

      assert html =~ "must be an amount"
      assert Payments.list_seller_deductions!(authorize?: false) == []
    end
  end

  describe "the form panel" do
    test "stays shut until an operator asks to add something", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      refute open?(view, "seller-deduction-sheet")
    end

    test "opens on the add control", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      assert open?(view, "seller-deduction-sheet")
      refute open?(view, "buyer-fee-sheet")
    end

    test "closes once the row is saved", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      view
      |> form("#seller-deduction-form",
        seller_deduction: %{"name" => "Listing fee", "kind" => "flat", "amount" => "1.99"}
      )
      |> render_submit()

      refute open?(view, "seller-deduction-sheet")
    end

    test "stays open when the save is refused, so the errors are read where they were typed",
         %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()

      view
      |> form("#seller-deduction-form",
        seller_deduction: %{"name" => "Listing fee", "kind" => "flat", "amount" => "a lot"}
      )
      |> render_submit()

      assert open?(view, "seller-deduction-sheet")
    end

    test "closing it tells the server, so it does not spring back open", %{conn: conn} do
      {:ok, view, _html} = open(conn)

      view |> element("#add-seller-deduction") |> render_click()
      view |> element("#seller-deduction-sheet-close") |> render_click()

      refute open?(view, "seller-deduction-sheet")
    end
  end

  describe "editing a row" do
    test "loads the row into the form and saves what is changed", %{conn: conn} do
      row = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})

      {:ok, view, _html} = open(conn)

      html = view |> element("#edit-seller-deduction-#{row.id}") |> render_click()

      assert html =~ "Commission"
      assert html =~ ~s(value="10")
      assert open?(view, "seller-deduction-sheet")

      view
      |> form("#seller-deduction-form",
        seller_deduction: %{"name" => "Commission", "kind" => "percentage", "rate_bp" => "7.5"}
      )
      |> render_submit()

      assert [%{rate_bp: 750}] = Payments.list_seller_deductions!(authorize?: false)
    end

    test "goes back to adding when the edit is closed", %{conn: conn} do
      row = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})

      {:ok, view, _html} = open(conn)

      view |> element("#edit-seller-deduction-#{row.id}") |> render_click()
      view |> element("#seller-deduction-sheet-close") |> render_click()
      view |> element("#add-seller-deduction") |> render_click()

      refute view |> element("#seller-deduction-form") |> render() =~ "Commission"
    end

    test "offers the same row actions on the cards a narrow screen reads", %{conn: conn} do
      row = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})

      {:ok, view, _html} = open(conn)

      assert has_element?(view, "#edit-card-seller-deduction-#{row.id}")
      assert has_element?(view, "#remove-card-seller-deduction-#{row.id}")
    end
  end

  describe "removing a row" do
    test "drops it", %{conn: conn} do
      row = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})

      {:ok, view, _html} = open(conn)

      view |> element("#remove-seller-deduction-#{row.id}") |> render_click()

      assert Payments.list_seller_deductions!(authorize?: false) == []
      assert has_element?(view, "#seller-deductions-empty")
    end

    test "says why it will not drop one another row is a percentage of", %{conn: conn} do
      commission = deduction(%{name: "Commission", kind: :percentage, rate_bp: 1000})
      deduction(%{name: "VAT", kind: :percentage, rate_bp: 2100, of_id: commission.id})

      {:ok, view, _html} = open(conn)

      html = view |> element("#remove-seller-deduction-#{commission.id}") |> render_click()

      assert html =~ "another deduction is a percentage of it"
      assert length(Payments.list_seller_deductions!(authorize?: false)) == 2
    end

    test "drops a buyer fee", %{conn: conn} do
      row = fee(%{name: "Protection", kind: :flat, amount: 99})

      {:ok, view, _html} = open(conn)

      view |> element("#remove-buyer-fee-#{row.id}") |> render_click()

      assert Payments.list_buyer_fees!(authorize?: false) == []
    end
  end
end
