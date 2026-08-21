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

  test "GET / links an admin to the admin area", %{conn: conn} do
    admin = admin_user(first_name: "Rita")

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(admin)
      |> get(~p"/")

    assert html_response(conn, 200) =~ ~s(href="/admin/users")
  end

  # Scoped to the menu panel: the sidebar has its own "Admin" section heading, so
  # an unscoped match would pass even if the badge never rendered.
  test "GET / badges an admin in the user menu", %{conn: conn} do
    admin = admin_user(first_name: "Rita")

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(admin)
      |> get(~p"/")

    assert conn |> html_response(200) |> menu_text() =~ "Admin"
  end

  test "GET / does not badge a non-admin in the user menu", %{conn: conn} do
    user = generate(user(first_name: "Jordan"))

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(user)
      |> get(~p"/")

    refute conn |> html_response(200) |> menu_text() =~ "Admin"
  end

  test "GET / shows an admin indicator in the header", %{conn: conn} do
    admin = admin_user(first_name: "Rita")

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(admin)
      |> get(~p"/")

    assert conn |> html_response(200) |> query("#admin-indicator") |> LazyHTML.text() =~ "Admin"
  end

  test "GET / shows no admin indicator for a non-admin", %{conn: conn} do
    user = generate(user(first_name: "Jordan"))

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(user)
      |> get(~p"/")

    assert conn |> html_response(200) |> query("#admin-indicator") |> Enum.empty?()
  end

  defp query(html, selector) do
    html |> LazyHTML.from_document() |> LazyHTML.query(selector)
  end

  defp menu_text(html) do
    html |> query("#user-menu-panel") |> LazyHTML.text()
  end

  test "GET / does not link a non-admin to the admin area", %{conn: conn} do
    user = generate(user(first_name: "Jordan"))

    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> Helpers.store_in_session(user)
      |> get(~p"/")

    refute html_response(conn, 200) =~ ~s(href="/admin/users")
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
