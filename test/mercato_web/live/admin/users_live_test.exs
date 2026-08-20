defmodule MercatoWeb.Admin.UsersLiveTest do
  use MercatoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Mercato.TestGenerators

  alias AshAuthentication.Plug.Helpers

  defp log_in(conn, user) do
    conn
    |> Plug.Test.init_test_session(%{})
    |> Helpers.store_in_session(user)
  end

  defp set_status(user, status) do
    user
    |> Ash.Changeset.for_update(:change_status, %{status: status}, authorize?: false)
    |> Ash.update!()
  end

  describe "access" do
    test "redirects a signed-out visitor to sign-in", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/admin/users")
    end

    test "redirects a signed-in user without admin:access away", %{conn: conn} do
      trader = generate(user())

      assert {:error, {:redirect, %{to: "/"}}} = live(log_in(conn, trader), ~p"/admin/users")
    end

    test "lets an admin in", %{conn: conn} do
      admin = admin_user()

      {:ok, _view, html} = live(log_in(conn, admin), ~p"/admin/users")

      assert html =~ "Users"
      assert html =~ "Review and manage every account on the platform."
    end
  end

  describe "listing real users" do
    setup %{conn: conn} do
      admin = admin_user(first_name: "Rita", last_name: "Salgado")

      marta =
        generate(
          user(first_name: "Marta", last_name: "Ribeiro", email: "marta.ribeiro@example.com")
        )

      banned = generate(user(first_name: "Bruno", last_name: "Salgueiro"))
      set_status(banned, :banned)

      {:ok, view, html} = live(log_in(conn, admin), ~p"/admin/users")

      %{view: view, html: html, admin: admin, marta: marta, banned: banned}
    end

    test "renders one row per real account", ctx do
      assert has_element?(ctx.view, "#user-#{ctx.marta.id}")
      assert has_element?(ctx.view, "#user-#{ctx.banned.id}")
      assert has_element?(ctx.view, "#user-#{ctx.admin.id}")
    end

    test "shows each account's name, handle and email", ctx do
      row = element(ctx.view, "#user-#{ctx.marta.id}") |> render()

      assert row =~ "Marta Ribeiro"
      assert row =~ "@#{ctx.marta.handle}"
      assert row =~ "marta.ribeiro@example.com"
    end

    test "shows the account status as a badge", ctx do
      assert element(ctx.view, "#user-#{ctx.banned.id}") |> render() =~ "Banned"
      assert element(ctx.view, "#user-#{ctx.marta.id}") |> render() =~ "Active"
    end

    test "falls back when an account has no name", ctx do
      nameless = generate(user(first_name: "Temp"))

      # Both names, not just the first: the generator fills last_name with
      # random data, so clearing only first_name leaves a name behind.
      nameless
      |> Ash.Changeset.for_update(:change_status, %{status: :active}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:first_name, nil)
      |> Ash.Changeset.force_change_attribute(:last_name, nil)
      |> Ash.update!()

      {:ok, view, _html} = live(log_in(ctx.conn, ctx.admin), ~p"/admin/users")

      assert element(view, "#user-#{nameless.id}") |> render() =~ "Name not provided"
    end

    test "anonymises a deleted account", ctx do
      deleted = generate(user(first_name: "Gone", last_name: "Away"))
      set_status(deleted, :deleted)

      {:ok, view, _html} = live(log_in(ctx.conn, ctx.admin), ~p"/admin/users")

      row = element(view, "#user-#{deleted.id}") |> render()

      assert row =~ "Deleted user"
      refute row =~ "Gone Away"
    end

    test "reports how many accounts are showing", ctx do
      assert render(ctx.view) =~ "3 of 3"
    end
  end

  describe "search" do
    setup %{conn: conn} do
      admin = admin_user(first_name: "Rita")
      marta = generate(user(first_name: "Marta", last_name: "Ribeiro"))
      tiago = generate(user(first_name: "Tiago", last_name: "Ferreira"))

      {:ok, view, _html} = live(log_in(conn, admin), ~p"/admin/users")

      %{view: view, marta: marta, tiago: tiago}
    end

    test "narrows the list to matching accounts", ctx do
      ctx.view |> form("#user-filters", %{"query" => "ribeiro"}) |> render_change()

      assert has_element?(ctx.view, "#user-#{ctx.marta.id}")
      refute has_element?(ctx.view, "#user-#{ctx.tiago.id}")
    end

    test "matches a handle containing an underscore", ctx do
      ctx.view |> form("#user-filters", %{"query" => ctx.marta.handle}) |> render_change()

      assert ctx.marta.handle =~ "_"
      assert has_element?(ctx.view, "#user-#{ctx.marta.id}")
      refute has_element?(ctx.view, "#user-#{ctx.tiago.id}")
    end

    test "shows a no-matches state and a way back", ctx do
      html = ctx.view |> form("#user-filters", %{"query" => "zzzznobody"}) |> render_change()

      assert html =~ "No accounts match"
      assert has_element?(ctx.view, "#clear-filters")
    end

    test "clearing the filters restores the full list", ctx do
      ctx.view |> form("#user-filters", %{"query" => "zzzznobody"}) |> render_change()
      ctx.view |> element("#clear-filters") |> render_click()

      assert has_element?(ctx.view, "#user-#{ctx.marta.id}")
      assert has_element?(ctx.view, "#user-#{ctx.tiago.id}")
    end
  end

  describe "status filter" do
    setup %{conn: conn} do
      admin = admin_user()
      active = generate(user(first_name: "Active"))
      banned = generate(user(first_name: "Banned")) |> set_status(:banned)

      {:ok, view, _html} = live(log_in(conn, admin), ~p"/admin/users")

      %{view: view, active: active, banned: banned}
    end

    test "shows a chip per status with a count", ctx do
      html = render(ctx.view)

      assert html =~ "All (3)"
      assert html =~ "Active (2)"
      assert html =~ "Banned (1)"
      assert html =~ "Deleted (0)"
    end

    test "filtering by a status keeps only that status", ctx do
      ctx.view |> element("#status-chip-banned") |> render_click()

      assert has_element?(ctx.view, "#user-#{ctx.banned.id}")
      refute has_element?(ctx.view, "#user-#{ctx.active.id}")
    end

    test "the applied filter is shown as a removable chip", ctx do
      ctx.view |> element("#status-chip-banned") |> render_click()

      assert render(ctx.view) =~ "Status: Banned"

      ctx.view |> element("#remove-status-filter") |> render_click()

      assert has_element?(ctx.view, "#user-#{ctx.active.id}")
    end
  end

  describe "pagination" do
    setup %{conn: conn} do
      admin = admin_user()
      for i <- 1..25, do: generate(user(first_name: "Person#{i}"))

      {:ok, view, _html} = live(log_in(conn, admin), ~p"/admin/users")

      %{view: view}
    end

    test "shows the first page and the range it covers", ctx do
      assert render(ctx.view) =~ "Showing 1"
      assert render(ctx.view) =~ "26"
    end

    test "the previous control is disabled on the first page", ctx do
      assert has_element?(ctx.view, "#prev-page[disabled]")
    end

    test "moving to the next page shows different accounts", ctx do
      first_page_ids = row_ids(ctx.view)

      ctx.view |> element("#next-page") |> render_click()

      second_page_ids = row_ids(ctx.view)

      refute second_page_ids == []
      assert MapSet.disjoint?(MapSet.new(first_page_ids), MapSet.new(second_page_ids))
      refute has_element?(ctx.view, "#prev-page[disabled]")
    end
  end

  defp row_ids(view) do
    view
    |> render()
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("tbody [id^='user-']")
    |> LazyHTML.attribute("id")
  end
end
