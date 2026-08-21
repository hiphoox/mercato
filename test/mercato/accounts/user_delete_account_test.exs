defmodule Mercato.Accounts.UserDeleteAccountTest do
  use Mercato.DataCase, async: true

  alias AshAuthentication.Info
  alias AshAuthentication.Strategy.MagicLink
  alias Mercato.Accounts
  alias Mercato.Accounts.{Token, User, UserRole}

  import Mercato.TestGenerators

  require Ash.Query

  @tmp_dir_prefix "mercato-delete-account-test"

  defp with_local_storage(_context) do
    tmp_dir =
      Path.join(System.tmp_dir!(), "#{@tmp_dir_prefix}-#{System.unique_integer([:positive])}")

    Application.put_env(:mercato, Mercato.Ports.Storage.Local, storage_path: tmp_dir)

    on_exit(fn ->
      Application.delete_env(:mercato, Mercato.Ports.Storage.Local)
      File.rm_rf!(tmp_dir)
    end)

    :ok
  end

  # Bypasses the archival filter the way the admin listing does, so a test can
  # assert on the row that is still there rather than on its absence.
  defp reload_archived(user) do
    User
    |> Ash.Query.for_read(:list_accounts, %{}, authorize?: false)
    |> Ash.Query.filter(id == ^user.id)
    |> Ash.read_one!(authorize?: false, page: false)
  end

  describe "archival" do
    test "stamps archived_at instead of removing the row" do
      user = generate(user())

      assert :ok == Accounts.delete_account(user, authorize?: false)

      archived = reload_archived(user)
      assert archived.archived_at
    end

    test "sets the account status to deleted" do
      user = generate(user())

      :ok = Accounts.delete_account(user, authorize?: false)

      assert reload_archived(user).status == :deleted
    end

    test "hides the account from ordinary reads" do
      user = generate(user())

      :ok = Accounts.delete_account(user, authorize?: false)

      refute Enum.any?(Ash.read!(User, authorize?: false), &(&1.id == user.id))
    end

    # get_by_subject is what resolves a live session back to a user, so this is
    # what actually signs a deleted account out everywhere it is still open.
    test "stops resolving the account from its session subject" do
      user = generate(user())
      subject = AshAuthentication.user_to_subject(user)

      :ok = Accounts.delete_account(user, authorize?: false)

      assert {:error, _} =
               User
               |> Ash.Query.for_read(:get_by_subject, %{subject: subject}, authorize?: false)
               |> Ash.read_one(authorize?: false, not_found_error?: true)
    end

    test "keeps the account in the admin listing" do
      admin = admin_user()
      user = generate(user())

      :ok = Accounts.delete_account(user, authorize?: false)

      page = Accounts.list_accounts!(%{}, actor: admin)
      assert Enum.any?(page.results, &(&1.id == user.id))
    end
  end

  describe "anonymization" do
    test "erases every personal field" do
      user = generate(user(last_name: "Doe"))
      assert user.first_name

      :ok = Accounts.delete_account(user, authorize?: false)

      archived = reload_archived(user)
      refute archived.first_name
      refute archived.last_name
      refute archived.handle
      refute archived.avatar_url
      refute archived.hashed_password
      refute archived.confirmed_at
      refute to_string(archived.email) == to_string(user.email)
    end

    test "frees the original email for a fresh registration" do
      user = generate(user())
      email = to_string(user.email)

      :ok = Accounts.delete_account(user, authorize?: false)

      reregistered =
        Accounts.register_with_password!(
          email,
          "Jane",
          "password1234",
          "password1234",
          authorize?: false
        )

      refute reregistered.id == user.id
      assert to_string(reregistered.email) == email
    end

    test "removes the account's role membership" do
      user = generate(user())
      assert Enum.any?(Ash.read!(UserRole, authorize?: false), &(&1.user_id == user.id))

      :ok = Accounts.delete_account(user, authorize?: false)

      refute Enum.any?(Ash.read!(UserRole, authorize?: false), &(&1.user_id == user.id))
    end

    test "revokes every stored token for the account" do
      user =
        Accounts.register_with_password!(
          "token-holder-#{System.unique_integer([:positive])}@example.com",
          "Jane",
          "password1234",
          "password1234",
          authorize?: false
        )

      subject = AshAuthentication.user_to_subject(user)
      assert Enum.any?(Ash.read!(Token, authorize?: false), &(&1.subject == subject))

      :ok = Accounts.delete_account(user, authorize?: false)

      refute Enum.any?(
               Ash.read!(Token, authorize?: false),
               &(&1.subject == subject and &1.purpose != "revocation")
             )
    end
  end

  # The unique indexes on email and handle are not scoped to live rows — that
  # would need a `base_filter`, which the admin listing rules out. Anonymization
  # is what keeps them satisfiable instead, so these pin that down.
  describe "identities across archived rows" do
    test "several deleted accounts coexist despite the unique handle index" do
      first = generate(user())
      second = generate(user())
      assert first.handle && second.handle

      assert :ok == Accounts.delete_account(first, authorize?: false)
      assert :ok == Accounts.delete_account(second, authorize?: false)

      refute reload_archived(first).handle
      refute reload_archived(second).handle
    end

    test "the same email can be registered and deleted repeatedly" do
      email = "recycle-#{System.unique_integer([:positive])}@example.com"

      ids =
        for _ <- 1..3 do
          user =
            Accounts.register_with_password!(email, "Jane", "password1234", "password1234",
              authorize?: false
            )

          assert :ok == Accounts.delete_account(user, authorize?: false)
          user.id
        end

      assert ids == Enum.uniq(ids)
    end

    # sign_in_with_magic_link upserts on unique_email. Were the original address
    # kept on the archived row, a magic link to it would resurrect that row
    # rather than register a new account.
    test "a magic link to a freed email registers a new account, not the archived one" do
      user = generate(user())
      email = to_string(user.email)

      :ok = Accounts.delete_account(user, authorize?: false)

      {:ok, token} =
        MagicLink.request_token_for_identity(Info.strategy!(User, :magic_link), email)

      signed_in =
        User
        |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token}, authorize?: false)
        |> Ash.create!(authorize?: false)

      refute signed_in.id == user.id
      refute signed_in.archived_at
      assert signed_in.status == :active
    end
  end

  describe "avatar blob" do
    setup :with_local_storage

    test "deletes the stored image from the storage port" do
      user = generate(user())
      updated = Accounts.update_avatar!(user, "fake image bytes", "photo.jpg", authorize?: false)

      storage = Application.fetch_env!(:mercato, :storage_adapter)
      assert {:ok, "fake image bytes"} == storage.get(updated.avatar_key)

      :ok = Accounts.delete_account(updated, authorize?: false)

      assert {:error, :enoent} == storage.get(updated.avatar_key)
    end
  end

  describe "sign-in" do
    test "refuses a password sign-in for a deleted account" do
      email = "signin-#{System.unique_integer([:positive])}@example.com"

      user =
        Accounts.register_with_password!(email, "Jane", "password1234", "password1234",
          authorize?: false
        )

      :ok = Accounts.delete_account(user, authorize?: false)

      assert {:error, _} =
               Accounts.sign_in_with_password(email, "password1234", authorize?: false)
    end
  end

  describe "authorization" do
    test "a user may delete their own account" do
      user = generate(user())

      assert Ash.can?({user, :delete_account}, user)
    end

    test "an admin holding user:delete may delete another account" do
      admin = generate(user()) |> grant_permission("user:delete")
      user = generate(user())

      assert Ash.can?({user, :delete_account}, admin)
    end

    test "an ordinary user may not delete someone else's account" do
      user = generate(user())
      other = generate(user())

      refute Ash.can?({other, :delete_account}, user)
    end
  end
end
