defmodule MercatoWeb.Live.Auth.ResetFormTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @reset_wrapper "#user-password-request-password-reset-token-wrapper"

  describe "the reset-password page" do
    test "defaults to the reset-password tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reset")

      assert has_element?(view, "button", "Reset password")
      assert has_element?(view, "button", "Magic link")
      assert has_element?(view, "#reset-email")
    end

    test "switching to the magic-link tab shows different copy and button text", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reset")

      html =
        view
        |> element("#{@reset_wrapper} button", "Magic link")
        |> render_click()

      assert html =~ "id=\"reset-magic-email\""
      assert html =~ "Send magic link"
    end

    test "requesting a password reset shows a confirmation flash", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/reset")

      view
      |> form("#reset-user-password-request-password-reset-token", %{
        "user" => %{"email" => "reset-request@example.com"}
      })
      |> render_submit()

      assert render(view) =~ "password reset instructions"
    end
  end
end
