defmodule MercatoWeb.PageControllerTest do
  use MercatoWeb.ConnCase

  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers

  test "GET / when signed out shows sign-in/sign-up links", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Mercato"
    assert html =~ ~s(href="/sign-in")
    assert html =~ ~s(href="/register")
  end

  test "GET / when signed in shows the user's name and a sign-out link", %{conn: conn} do
    user = generate(user(first_name: "Jordan"))

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(user)
      |> get(~p"/")

    html = html_response(conn, 200)

    assert html =~ "Jordan"
    assert html =~ ~s(href="/sign-out")
  end
end
