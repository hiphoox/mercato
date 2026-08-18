defmodule MercatoWeb.Live.Auth.SignInFormTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  describe "the sign-in page" do
    test "shows email and password fields, and no OAuth provider buttons", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      assert has_element?(view, "#sign-in-email")
      assert has_element?(view, "#sign-in-password")
      refute has_element?(view, "a", "Google")
      refute has_element?(view, "a", "Facebook")
      refute has_element?(view, "a", "Apple")
    end

    test "defaults to the password tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      assert has_element?(view, "button", "Password")
      assert has_element?(view, "button", "Magic link")
      assert has_element?(view, "#sign-in-password")
    end

    @sign_in_wrapper "#user-password-sign-in-with-password-wrapper"

    test "switching to the magic-link tab shows an email-only form and hides the password field",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      html =
        view
        |> element("#{@sign_in_wrapper} button", "Magic link")
        |> render_click()

      assert html =~ "id=\"magic-email\""
      refute html =~ "id=\"sign-in-password\""
    end

    test "requesting a magic link shows a confirmation flash without redirecting", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/sign-in")

      view
      |> element("#{@sign_in_wrapper} button", "Magic link")
      |> render_click()

      view
      |> form("#sign-in-user-magic_link-request-magic-link", %{
        "user" => %{"email" => "magic-sign-in@example.com"}
      })
      |> render_submit()

      assert render(view) =~ "sign-in link"
    end

    test "signing in with correct credentials succeeds", %{conn: conn} do
      user =
        generate(
          user(password: "correct-horse-battery", password_confirmation: "correct-horse-battery")
        )

      {:ok, view, _html} = live(conn, ~p"/sign-in")

      form =
        form(view, "#sign-in-user-password-sign-in-with-password", %{
          "user" => %{"email" => to_string(user.email), "password" => "correct-horse-battery"}
        })

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end
  end
end
