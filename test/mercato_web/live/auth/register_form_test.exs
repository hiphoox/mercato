defmodule MercatoWeb.Live.Auth.RegisterFormTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "the registration page" do
    test "shows first name, last name, email, password, and confirmation fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      assert has_element?(view, "#register-first-name")
      assert has_element?(view, "#register-last-name")
      assert has_element?(view, "#register-email")
      assert has_element?(view, "#register-password")
      assert has_element?(view, "#register-password-confirmation")
    end

    test "does not show any OAuth provider buttons", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      refute has_element?(view, "a", "Google")
      refute has_element?(view, "a", "Facebook")
      refute has_element?(view, "a", "Apple")
    end

    test "registering with only a first name (no last name) succeeds", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      form =
        form(view, "#register-user-password-register-with-password", %{
          "user" => %{
            "first_name" => "Jane",
            "email" => "jane-#{System.unique_integer([:positive])}@example.com",
            "password" => "password1234",
            "password_confirmation" => "password1234"
          }
        })

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    @register_wrapper "#user-password-register-with-password-wrapper"

    test "switching to the magic-link tab shows an email-only form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      html =
        view
        |> element("#{@register_wrapper} button", "Magic link")
        |> render_click()

      assert html =~ "id=\"register-magic-email\""
      refute html =~ "id=\"register-first-name\""
    end

    test "leaving first name blank shows a validation error and does not submit", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/register")

      html =
        view
        |> form("#register-user-password-register-with-password", %{
          "user" => %{
            "first_name" => "",
            "email" => "no-first-name@example.com",
            "password" => "password1234",
            "password_confirmation" => "password1234"
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank" or html =~ "required"
    end
  end
end
