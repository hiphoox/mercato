defmodule Mercato.Listings.ListingTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings
  alias Mercato.Listings.Listing

  setup do
    %{seller: generate(user())}
  end

  describe "create_listing/2" do
    test "creates a listing owned by the acting seller", %{seller: seller} do
      assert {:ok, listing} =
               Listings.create_listing(
                 %{
                   title: "Vintage denim jacket",
                   description: "Barely worn.",
                   price: 4500,
                   category_id: default_category_id()
                 },
                 actor: seller,
                 authorize?: false
               )

      assert listing.title == "Vintage denim jacket"
      assert listing.description == "Barely worn."
      assert listing.seller_id == seller.id
    end

    test "starts as a draft that has never been published", %{seller: seller} do
      listing = create_listing!(seller)

      assert listing.status == :draft
      assert listing.published_at == nil
    end

    test "defaults quantity to a single unit", %{seller: seller} do
      assert create_listing!(seller).quantity == 1
    end

    test "stamps the created and updated timestamps", %{seller: seller} do
      listing = create_listing!(seller)

      assert %DateTime{} = listing.created_at
      assert %DateTime{} = listing.updated_at
    end

    test "refuses a listing with no acting seller" do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(
                 %{title: "Orphaned", price: 100, category_id: default_category_id()},
                 authorize?: false
               )
    end

    test "requires a title", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(%{price: 100, category_id: default_category_id()},
                 actor: seller,
                 authorize?: false
               )
    end

    test "requires a price", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(%{title: "Priceless", category_id: default_category_id()},
                 actor: seller,
                 authorize?: false
               )
    end
  end

  describe "price" do
    test "round-trips exactly as the minor-unit integer it was given", %{seller: seller} do
      listing = create_listing!(seller, price: 1999)

      assert listing.price === 1999
      assert Ash.get!(Listing, listing.id, authorize?: false).price === 1999
    end

    test "refuses a fractional major-unit amount", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(
                 %{title: "Denim", price: 19.99, category_id: default_category_id()},
                 actor: seller,
                 authorize?: false
               )
    end
  end

  describe "currency" do
    test "defaults to the currency configured for the instance", %{seller: seller} do
      assert create_listing!(seller).currency == Application.fetch_env!(:mercato, :currency)
    end

    test "refuses a seller-supplied currency on create", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(
                 %{
                   title: "Denim",
                   price: 1999,
                   currency: "GBP",
                   category_id: default_category_id()
                 },
                 actor: seller,
                 authorize?: false
               )
    end

    test "refuses a seller-supplied currency on update", %{seller: seller} do
      listing = create_listing!(seller)

      assert {:error, %Ash.Error.Invalid{}} =
               Listings.update_listing(listing, %{currency: "GBP"},
                 actor: seller,
                 authorize?: false
               )
    end
  end

  describe "condition" do
    test "is blank until the seller picks one", %{seller: seller} do
      assert create_listing!(seller).condition == nil
    end

    test "accepts a condition the marketplace has configured", %{seller: seller} do
      assert create_listing!(seller, condition: "like_new").condition == "like_new"
    end

    test "refuses a condition outside the configured list", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(
                 %{
                   title: "Denim",
                   price: 1999,
                   condition: "mint",
                   category_id: default_category_id()
                 },
                 actor: seller,
                 authorize?: false
               )
    end
  end

  describe "validation" do
    test "refuses a title too short to identify anything", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} = create_listing(seller, title: "ab")
    end

    test "accepts a title at the length limit", %{seller: seller} do
      title = String.duplicate("a", 140)

      assert create_listing!(seller, title: title).title == title
    end

    test "refuses a title past the length limit", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               create_listing(seller, title: String.duplicate("a", 141))
    end

    test "refuses a description past the length limit", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               create_listing(seller, description: String.duplicate("a", 5001))
    end

    test "refuses a free listing", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} = create_listing(seller, price: 0)
    end

    test "refuses a negative price", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} = create_listing(seller, price: -100)
    end

    test "accepts a quantity of none left", %{seller: seller} do
      assert create_listing!(seller, quantity: 0).quantity == 0
    end

    test "refuses a negative quantity", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} = create_listing(seller, quantity: -1)
    end
  end

  describe "category" do
    test "a listing belongs to the category it was filed under", %{seller: seller} do
      category = generate(category())

      listing =
        seller
        |> create_listing!(category_id: category.id)
        |> Ash.load!(:category, authorize?: false)

      assert listing.category.id == category.id
    end

    test "refuses a listing filed under no category", %{seller: seller} do
      assert {:error, %Ash.Error.Invalid{}} =
               Listings.create_listing(%{title: "Uncategorised", price: 1000},
                 actor: seller,
                 authorize?: false
               )
    end
  end

  describe "seller relationship" do
    test "a seller has many listings", %{seller: seller} do
      first = create_listing!(seller, title: "First")
      second = create_listing!(seller, title: "Second")

      seller = Ash.load!(seller, :listings, authorize?: false)

      assert Enum.map(seller.listings, & &1.id) |> Enum.sort() ==
               Enum.sort([first.id, second.id])
    end

    test "a listing belongs to its seller", %{seller: seller} do
      listing = seller |> create_listing!() |> Ash.load!(:seller, authorize?: false)

      assert listing.seller.id == seller.id
    end
  end

  defp create_listing(seller, attrs \\ []) do
    attrs =
      Enum.into(attrs, %{title: "A listing", price: 1000, category_id: default_category_id()})

    Listings.create_listing(attrs, actor: seller, authorize?: false)
  end

  defp create_listing!(seller, attrs \\ []) do
    {:ok, listing} = create_listing(seller, attrs)

    listing
  end

  # One category for the whole test, since only the category describe block
  # cares which one a listing is filed under.
  defp default_category_id do
    :listing_test_category
    |> Ash.Generator.once(fn -> generate(category()).id end)
    |> Enum.at(0)
  end
end
