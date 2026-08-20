defmodule Mercato.Accounts.UserListAccountsTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Ash.Resource.Info, as: ResourceInfo
  alias Mercato.Accounts
  alias Mercato.Accounts.User

  defp set_status(user, status) do
    user
    |> Ash.Changeset.for_update(:change_status, %{status: status}, authorize?: false)
    |> Ash.update!()
  end

  defp handles(page), do: Enum.map(page.results, & &1.handle)

  describe "authorization" do
    test "an actor holding admin:access can list accounts" do
      admin = admin_user()

      assert Accounts.can_list_accounts?(admin)
    end

    test "an actor without admin:access cannot list accounts" do
      trader = generate(user())

      refute Accounts.can_list_accounts?(trader)
    end

    test "an anonymous caller cannot list accounts" do
      refute Accounts.can_list_accounts?(nil)
    end

    test "listing as a non-admin is refused" do
      trader = generate(user())

      assert {:error, %Ash.Error.Forbidden{}} = Accounts.list_accounts(actor: trader)
    end
  end

  describe "listing" do
    test "returns every account, including the admin's own" do
      admin = admin_user()
      other = generate(user())

      {:ok, page} = Accounts.list_accounts(actor: admin, page: [count: true])

      assert page.count == 2
      assert admin.id in Enum.map(page.results, & &1.id)
      assert other.id in Enum.map(page.results, & &1.id)
    end

    test "exposes the account's email to the admin" do
      admin = admin_user()
      other = generate(user(email: "listed@example.com"))

      {:ok, page} = Accounts.list_accounts(actor: admin)

      listed = Enum.find(page.results, &(&1.id == other.id))
      assert to_string(listed.email) == "listed@example.com"
    end
  end

  describe "status filter" do
    setup do
      admin = admin_user()
      active = generate(user(first_name: "Active"))
      banned = generate(user(first_name: "Banned")) |> set_status(:banned)
      deleted = generate(user(first_name: "Deleted")) |> set_status(:deleted)

      %{admin: admin, active: active, banned: banned, deleted: deleted}
    end

    test "returns only accounts with the given status", ctx do
      {:ok, page} = Accounts.list_accounts(%{status: :banned}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.banned.id]
    end

    test "returns every status when no filter is given", ctx do
      {:ok, page} = Accounts.list_accounts(actor: ctx.admin, page: [count: true])

      assert page.count == 4
    end

    test "filters deleted accounts", ctx do
      {:ok, page} = Accounts.list_accounts(%{status: :deleted}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.deleted.id]
    end
  end

  describe "search" do
    setup do
      admin = admin_user()

      marta =
        generate(
          user(
            first_name: "Marta",
            last_name: "Ribeiro",
            email: "marta.ribeiro@example.com"
          )
        )

      tiago =
        generate(
          user(first_name: "Tiago", last_name: "Ferreira", email: "tiago.f@elsewhere.test")
        )

      %{admin: admin, marta: marta, tiago: tiago}
    end

    test "matches on first name, case-insensitively", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: "marta"}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.marta.id]
    end

    test "matches on last name", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: "Ferreira"}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.tiago.id]
    end

    test "matches on a partial email", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: "elsewhere.test"}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.tiago.id]
    end

    test "matches on handle", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: ctx.marta.handle}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.marta.id]
    end

    test "an empty query does not filter anything out", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: ""}, actor: ctx.admin, page: [count: true])

      assert page.count == 3
    end

    test "a query matching nothing returns no results", ctx do
      {:ok, page} = Accounts.list_accounts(%{query: "nobody-here"}, actor: ctx.admin)

      assert page.results == []
    end

    test "combines with the status filter", ctx do
      set_status(ctx.marta, :banned)

      {:ok, page} = Accounts.list_accounts(%{query: "a", status: :banned}, actor: ctx.admin)

      assert Enum.map(page.results, & &1.id) == [ctx.marta.id]
    end
  end

  describe "pagination" do
    test "limits and offsets the result set, reporting the full count" do
      admin = admin_user()
      for i <- 1..5, do: generate(user(first_name: "Person#{i}"))

      {:ok, first} =
        Accounts.list_accounts(actor: admin, page: [limit: 2, offset: 0, count: true])

      {:ok, second} =
        Accounts.list_accounts(actor: admin, page: [limit: 2, offset: 2, count: true])

      assert length(first.results) == 2
      assert length(second.results) == 2
      assert first.count == 6
      assert second.count == 6
      assert handles(first) != handles(second)
    end

    test "orders most recently active first, so paging is stable" do
      admin = admin_user()
      stale = generate(user(first_name: "Stale"))
      recent = generate(user(first_name: "Recent"))

      stamp(stale, ~U[2020-01-01 00:00:00.000000Z])
      stamp(recent, ~U[2026-01-01 00:00:00.000000Z])

      {:ok, page} = Accounts.list_accounts(actor: admin, page: [limit: 2])

      assert Enum.map(page.results, & &1.id) == [recent.id, stale.id]
    end
  end

  defp stamp(user, at) do
    user
    |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
    |> Ash.Changeset.force_change_attribute(:last_active_at, at)
    |> Ash.update!()
  end

  describe "public interface" do
    test "is defined on the domain" do
      assert function_exported?(Accounts, :list_accounts, 2)
      assert ResourceInfo.action(User, :list_accounts)
    end
  end
end
