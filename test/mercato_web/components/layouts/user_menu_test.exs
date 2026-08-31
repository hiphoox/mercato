defmodule MercatoWeb.Layouts.UserMenuTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Mercato.Accounts.Scope
  alias MercatoWeb.Layouts.UserMenu

  # A real struct, not a look-alike map: `Mercato.Accounts.User` does not
  # implement Access, and a map would let indexed lookups pass here and crash
  # in the running app.
  @user %Mercato.Accounts.User{
    first_name: "Jane",
    last_name: "Doe",
    email: "jane@mercato.app",
    avatar_url: nil
  }

  defp document(assigns) do
    assigns = Keyword.put_new(assigns, :current_scope, %Scope{})

    LazyHTML.from_fragment(render_component(&UserMenu.user_menu/1, assigns))
  end

  defp query(assigns, selector) do
    assigns |> document() |> LazyHTML.query(selector)
  end

  describe "signed in" do
    test "shows the user's name" do
      assert [current_scope: %Scope{user: @user}] |> document() |> LazyHTML.text() =~ "Jane Doe"
    end

    test "shows the user's email so they can tell which account they are in" do
      assert [current_scope: %Scope{user: @user}] |> document() |> LazyHTML.text() =~
               "jane@mercato.app"
    end

    test "marks an admin with a badge" do
      assert [current_scope: %Scope{user: @user, admin?: true}] |> document() |> LazyHTML.text() =~
               "Admin"
    end

    test "does not mark a non-admin" do
      refute [current_scope: %Scope{user: @user}] |> document() |> LazyHTML.text() =~ "Admin"
    end

    test "does not mark a user when the caller says nothing about admin access" do
      refute [current_scope: %Scope{user: @user}] |> document() |> LazyHTML.text() =~ "Admin"
    end

    test "renders an avatar in the trigger" do
      assert [current_scope: %Scope{user: @user}]
             |> query("#user-menu-trigger [role=img]")
             |> LazyHTML.attribute("aria-label") == ["Jane Doe"]
    end

    test "links to the profile page" do
      hrefs =
        [current_scope: %Scope{user: @user}]
        |> query("[role=menu] a")
        |> LazyHTML.attribute("href")

      assert "/users/me/profile" in hrefs
    end

    test "offers a sign out link" do
      hrefs =
        [current_scope: %Scope{user: @user}]
        |> query("[role=menu] a")
        |> LazyHTML.attribute("href")

      assert "/sign-out" in hrefs
    end

    test "does not offer sign in" do
      hrefs =
        [current_scope: %Scope{user: @user}]
        |> query("[role=menu] a")
        |> LazyHTML.attribute("href")

      refute "/sign-in" in hrefs
    end

    test "styles sign out as destructive" do
      classes =
        [current_scope: %Scope{user: @user}]
        |> query("a[href='/sign-out']")
        |> LazyHTML.attribute("class")

      assert hd(classes) =~ "text-error-text"
    end

    test "marks each row as a menu item" do
      assert [current_scope: %Scope{user: @user}] |> query("[role=menuitem]") |> Enum.count() > 0
    end
  end

  describe "signed out" do
    test "offers sign in" do
      hrefs = [current_scope: %Scope{}] |> query("[role=menu] a") |> LazyHTML.attribute("href")

      assert "/sign-in" in hrefs
    end

    test "offers registration" do
      hrefs = [current_scope: %Scope{}] |> query("[role=menu] a") |> LazyHTML.attribute("href")

      assert "/register" in hrefs
    end

    test "does not offer sign out" do
      hrefs = [current_scope: %Scope{}] |> query("[role=menu] a") |> LazyHTML.attribute("href")

      refute "/sign-out" in hrefs
    end

    test "does not show an account identity block" do
      refute [current_scope: %Scope{}] |> document() |> LazyHTML.text() =~ "@"
    end

    test "still renders a trigger, so the menu is reachable" do
      assert [current_scope: %Scope{}] |> query("#user-menu-trigger") |> Enum.count() == 1
    end
  end

  describe "display name" do
    test "falls back to the handle when there is no name" do
      user = %Mercato.Accounts.User{
        first_name: nil,
        last_name: nil,
        email: "x@y.z",
        handle: "janedoe",
        avatar_url: nil
      }

      assert [current_scope: %Scope{user: user}] |> document() |> LazyHTML.text() =~ "janedoe"
    end

    test "uses the avatar image when the user has uploaded one" do
      user = %{@user | avatar_url: "/uploads/jane.png"}

      assert [current_scope: %Scope{user: user}]
             |> query("#user-menu-trigger img")
             |> LazyHTML.attribute("src") ==
               ["/uploads/jane.png"]
    end
  end
end
