defmodule MercatoWeb.ProfileLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  describe "access" do
    test "redirects a signed-out visitor to sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/profile")
    end

    test "renders all four sections for a signed-in user", %{conn: conn} do
      user = generate(user(first_name: "Jane", last_name: "Doe"))
      conn = log_in(conn, user)

      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, "#name-form")
      assert has_element?(view, "#handle-form")
      assert has_element?(view, "#avatar-form")
      assert has_element?(view, "#security-form")
    end

    test "shows a direct-logout sign-out link at the end of the page", %{conn: conn} do
      user = generate(user(first_name: "Jane", last_name: "Doe"))
      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")

      assert has_element?(
               view,
               "a#sign-out-link[href='/sign-out'][data-method='delete']",
               "Sign out"
             )
    end
  end

  describe "app layout" do
    setup %{conn: conn} do
      user = generate(user(first_name: "Jane", last_name: "Doe"))
      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")
      %{view: view, user: user}
    end

    test "renders the sidebar", %{view: view} do
      assert has_element?(view, "#app-sidebar")
    end

    test "marks the profile entry as the current page", %{view: view} do
      assert has_element?(view, "#app-sidebar a[href='/profile'][aria-current='page']")
    end

    test "does not mark the home entry as current", %{view: view} do
      refute has_element?(view, "#app-sidebar a[href='/'][aria-current='page']")
    end

    test "renders the sidebar toggle", %{view: view} do
      assert has_element?(view, "#sidebar-toggle")
    end

    test "renders the search field", %{view: view} do
      assert has_element?(view, "#app-search")
    end

    test "renders the cart", %{view: view} do
      assert has_element?(view, "#app-cart")
    end

    test "renders the user menu with the signed-in user's initials", %{view: view} do
      assert has_element?(view, "#user-menu-trigger [role='img'][aria-label='Jane Doe']")
    end

    test "offers sign out inside the user menu", %{view: view} do
      assert has_element?(view, "#user-menu-panel a[href='/sign-out']")
    end

    test "renders a breadcrumb ending at the current page", %{view: view} do
      assert has_element?(view, "nav[aria-label='Breadcrumb'] [aria-current='page']")
    end

    test "links the breadcrumb's home crumb", %{view: view} do
      assert has_element?(view, "nav[aria-label='Breadcrumb'] a[href='/']")
    end
  end

  describe "name section" do
    setup %{conn: conn} do
      user = generate(user(first_name: "Jane", last_name: "Doe"))
      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")
      %{view: view, user: user}
    end

    test "updates first and last name", %{view: view} do
      view
      |> form("#name-form", %{"name" => %{"first_name" => "Janet", "last_name" => "Smith"}})
      |> render_submit()

      assert render(view) =~ "Name updated"
      assert has_element?(view, "#name-form input[name='name[first_name]'][value='Janet']")
    end

    test "rejects a blank first name", %{view: view} do
      html =
        view
        |> form("#name-form", %{"name" => %{"first_name" => "", "last_name" => "Smith"}})
        |> render_submit()

      assert html =~ "must be present"
    end
  end

  describe "handle section" do
    setup %{conn: conn} do
      user = generate(user(first_name: "Jane", last_name: "Doe"))
      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")
      %{view: view, user: user}
    end

    test "updates the handle", %{view: view} do
      view
      |> form("#handle-form", %{"handle" => %{"handle" => "newhandle"}})
      |> render_submit()

      assert render(view) =~ "Handle updated"
    end

    test "rejects a reserved handle", %{view: view} do
      html =
        view
        |> form("#handle-form", %{"handle" => %{"handle" => "admin"}})
        |> render_submit()

      assert html =~ "is reserved"
    end
  end

  describe "avatar section" do
    setup %{conn: conn} do
      tmp_dir =
        Path.join(
          System.tmp_dir!(),
          "mercato_avatar_live_test_#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(tmp_dir)
      Application.put_env(:mercato, Mercato.Ports.Storage.Local, storage_path: tmp_dir)

      on_exit(fn ->
        Application.delete_env(:mercato, Mercato.Ports.Storage.Local)
        File.rm_rf!(tmp_dir)
      end)

      user = generate(user(first_name: "Jane", last_name: "Doe"))
      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")
      %{view: view, user: user}
    end

    test "uploading an image saves the avatar automatically", %{view: view} do
      avatar =
        file_input(view, "#avatar-form", :avatar, [
          %{
            name: "photo.jpg",
            content: "fake image bytes",
            type: "image/jpeg"
          }
        ])

      render_upload(avatar, "photo.jpg")

      assert render(view) =~ "Avatar updated"
    end
  end

  describe "security section" do
    setup %{conn: conn} do
      user =
        generate(user(password: "password1234", password_confirmation: "password1234"))

      {:ok, view, _html} = live(log_in(conn, user), ~p"/profile")
      %{view: view, user: user}
    end

    test "changes the password with correct current password", %{view: view} do
      view
      |> form("#security-form", %{
        "security" => %{
          "current_password" => "password1234",
          "password" => "newpassword1",
          "password_confirmation" => "newpassword1"
        }
      })
      |> render_submit()

      assert render(view) =~ "Password updated"
    end

    test "rejects an incorrect current password", %{view: view} do
      html =
        view
        |> form("#security-form", %{
          "security" => %{
            "current_password" => "wrongpassword",
            "password" => "newpassword1",
            "password_confirmation" => "newpassword1"
          }
        })
        |> render_submit()

      assert html =~ "incorrect"
    end
  end
end
