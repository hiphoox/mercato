defmodule MercatoWeb.JsonApi.SuggestTest do
  use MercatoWeb.ConnCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Listings

  @accept "application/vnd.api+json"

  defp publish!(seller, listing) do
    generate(listing_image(listing: listing))

    Listings.publish_listing!(listing, actor: seller)
  end

  defp on_offer!(seller, opts) do
    publish!(seller, generate(listing(Keyword.put(opts, :actor, seller))))
  end

  defp request(conn, path, params) do
    conn |> put_req_header("accept", @accept) |> get(path, params)
  end

  defp data(conn, path, params),
    do: conn |> request(path, params) |> json_response(200) |> Map.fetch!("data")

  defp attributes(rows), do: Enum.map(rows, & &1["attributes"])

  setup do
    %{seller: generate(user(first_name: "Camila", last_name: "Ruiz"))}
  end

  describe "listing titles" do
    test "completes a term into matching titles", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Canon camera EOS")
      on_offer!(seller, title: "Two-person tent")

      assert attributes(data(conn, "/api/json/listings/suggest", %{"query" => "camera"})) ==
               [%{"title" => "Canon camera EOS"}]
    end

    test "narrows to a category", %{conn: conn, seller: seller} do
      furniture = generate(category(slug: "furniture"))
      on_offer!(seller, title: "Camera shelf", category_id: furniture.id)
      on_offer!(seller, title: "Camera tripod", category_id: generate(category()).id)

      rows =
        data(conn, "/api/json/listings/suggest", %{
          "query" => "camera",
          "category_slug" => "furniture"
        })

      assert attributes(rows) == [%{"title" => "Camera shelf"}]
    end

    test "renders the title and nothing else", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Canon camera EOS")

      assert [row] = data(conn, "/api/json/listings/suggest", %{"query" => "camera"})
      assert Map.keys(row["attributes"]) == ["title"]
      assert row["type"] == "listing"
    end

    test "leaves out a draft", %{conn: conn, seller: seller} do
      generate(listing(actor: seller, title: "Draft camera"))

      assert data(conn, "/api/json/listings/suggest", %{"query" => "camera"}) == []
    end
  end

  describe "categories" do
    test "completes a term into matching categories", %{conn: conn} do
      generate(category(name: "Cameras & Photo", slug: "cameras-photo"))
      generate(category(name: "Vehicles", slug: "vehicles"))

      assert attributes(data(conn, "/api/json/categories/suggest", %{"query" => "camera"})) ==
               [%{"name" => "Cameras & Photo", "slug" => "cameras-photo"}]
    end
  end

  describe "sellers" do
    test "completes a term into matching sellers", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Anything at all")

      assert attributes(data(conn, "/api/json/sellers/suggest", %{"query" => "camila"})) ==
               [%{"handle" => seller.handle, "first_name" => "Camila", "last_name" => "Ruiz"}]
    end

    test "leaves out a seller with nothing on offer", %{conn: conn} do
      generate(user(first_name: "Camila", last_name: "Ruiz"))

      assert data(conn, "/api/json/sellers/suggest", %{"query" => "camila"}) == []
    end

    # The field that must never reach an anonymous caller. `show_fields` is what
    # keeps it out; the default renders every public attribute, email included.
    test "never renders an email address", %{conn: conn, seller: seller} do
      on_offer!(seller, title: "Anything at all")

      response = request(conn, "/api/json/sellers/suggest", %{"query" => "camila"})

      refute response.resp_body =~ to_string(seller.email)
    end

    test "cannot be asked for an email through the fields parameter", %{
      conn: conn,
      seller: seller
    } do
      on_offer!(seller, title: "Anything at all")

      response =
        request(conn, "/api/json/sellers/suggest", %{
          "query" => "camila",
          "fields" => %{"seller" => "email"}
        })

      refute response.resp_body =~ to_string(seller.email)
    end

    test "never matches on an email address", %{conn: conn} do
      seller = generate(user(first_name: "Jo", last_name: "Vance", email: "findme@mercato.app"))
      on_offer!(seller, title: "Anything at all")

      assert data(conn, "/api/json/sellers/suggest", %{"query" => "findme"}) == []
    end
  end

  describe "who may ask" do
    test "answers a caller with no account, since browsing is public", %{
      conn: conn,
      seller: seller
    } do
      on_offer!(seller, title: "Canon camera EOS")

      assert [_] = data(conn, "/api/json/listings/suggest", %{"query" => "camera"})
    end
  end
end
