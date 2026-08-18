defmodule Mercato.Accounts.UserTest do
  use Mercato.DataCase, async: true

  alias AshAuthentication.Strategy.MagicLink
  alias Mercato.Accounts
  alias Mercato.Accounts.Setting

  import Mercato.TestGenerators

  defp field_error_messages(%Ash.Error.Invalid{errors: errors}, field) do
    errors
    |> Enum.filter(&(&1.field == field))
    |> Enum.map(& &1.message)
  end

  describe "default role" do
    test "register_with_password assigns the trader role" do
      user = generate(user())

      role_names =
        user
        |> Ash.load!(:user_roles, authorize?: false)
        |> Map.fetch!(:user_roles)
        |> Ash.load!(:role, authorize?: false)
        |> Enum.map(& &1.role.name)

      assert role_names == ["trader"]
    end

    test "sign_in_with_magic_link assigns the trader role to a new user" do
      strategy = AshAuthentication.Info.strategy!(Mercato.Accounts.User, :magic_link)
      {:ok, token} = MagicLink.request_token_for_identity(strategy, "roled@example.com")

      user = Accounts.sign_in_with_magic_link!(token, %{}, authorize?: false)

      role_names =
        user
        |> Ash.load!(:user_roles, authorize?: false)
        |> Map.fetch!(:user_roles)
        |> Ash.load!(:role, authorize?: false)
        |> Enum.map(& &1.role.name)

      assert role_names == ["trader"]
    end

    test "does not double-assign a role on a returning magic-link sign-in" do
      created = generate(user())

      created
      |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
      |> Ash.update!()

      strategy = AshAuthentication.Info.strategy!(Mercato.Accounts.User, :magic_link)
      {:ok, token} = MagicLink.request_token_for(strategy, created)

      signed_in = Accounts.sign_in_with_magic_link!(token, %{}, authorize?: false)

      role_count =
        signed_in
        |> Ash.load!(:user_roles, authorize?: false)
        |> Map.fetch!(:user_roles)
        |> length()

      assert role_count == 1
    end
  end

  describe "status" do
    test "defaults to :active on registration" do
      user = generate(user())

      assert user.status == :active
    end

    test "blocks password sign-in for a banned account" do
      created = generate(user(password: "password1234", password_confirmation: "password1234"))

      created
      |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:status, :banned)
      |> Ash.update!()

      result =
        Accounts.sign_in_with_password(to_string(created.email), "password1234", %{},
          authorize?: false
        )

      assert {:error, _} = result
    end

    test "blocks sign-in-with-token for a banned account" do
      created = generate(user(password: "password1234", password_confirmation: "password1234"))

      {:ok, %{__metadata__: %{token: sign_in_token}}} =
        Accounts.sign_in_with_password(to_string(created.email), "password1234", %{},
          authorize?: false,
          context: %{token_type: :sign_in}
        )

      created
      |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:status, :banned)
      |> Ash.update!()

      result = Accounts.sign_in_with_token(sign_in_token, %{}, authorize?: false)

      assert {:error, _} = result
    end
  end

  describe "sign_in_with_magic_link registration" do
    defp register_via_magic_link(email, params \\ %{}) do
      strategy = AshAuthentication.Info.strategy!(Mercato.Accounts.User, :magic_link)
      {:ok, token} = MagicLink.request_token_for_identity(strategy, email)

      Accounts.sign_in_with_magic_link!(token, params, authorize?: false)
    end

    test "registers a brand-new user with no name, deriving the handle from the email" do
      user = register_via_magic_link("newcomer@example.com")

      refute user.first_name
      assert user.handle == "newcomer"
    end

    test "pads a short email local part to the minimum handle length" do
      user = register_via_magic_link("jo@example.com")

      assert user.handle == "jo_1"
    end

    test "accepts first_name and last_name, using them for the handle" do
      user = register_via_magic_link("named@example.com", %{first_name: "Jane", last_name: "Doe"})

      assert user.first_name == "Jane"
      assert user.last_name == "Doe"
      assert user.handle == "jane_doe"
    end

    test "accepts first_name without last_name" do
      user = register_via_magic_link("solo@example.com", %{first_name: "Jane"})

      assert user.first_name == "Jane"
      refute user.last_name
      assert user.handle == "jane"
    end

    test "does not overwrite a returning user's existing name" do
      created = generate(user(first_name: "Jane", last_name: "Doe"))

      created
      |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
      |> Ash.update!()

      signed_in = register_via_magic_link(to_string(created.email), %{first_name: "Impostor"})

      assert signed_in.first_name == "Jane"
      assert signed_in.last_name == "Doe"
      assert signed_in.handle == created.handle
    end
  end

  describe "sign_in_with_magic_link" do
    test "does not regenerate the handle of a returning user" do
      created = generate(user(first_name: "Jane", last_name: "Doe"))

      created =
        created
        |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
        |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
        |> Ash.update!()

      strategy = AshAuthentication.Info.strategy!(Mercato.Accounts.User, :magic_link)
      {:ok, token} = MagicLink.request_token_for(strategy, created)

      signed_in = Accounts.sign_in_with_magic_link!(token, %{}, authorize?: false)

      assert signed_in.handle == created.handle
    end

    test "blocks sign-in for a banned account" do
      created = generate(user())

      created
      |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
      |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
      |> Ash.Changeset.force_change_attribute(:status, :banned)
      |> Ash.update!()

      strategy = AshAuthentication.Info.strategy!(Mercato.Accounts.User, :magic_link)
      {:ok, token} = MagicLink.request_token_for(strategy, created)

      result = Accounts.sign_in_with_magic_link(token, %{}, authorize?: false)

      assert {:error, _} = result
    end
  end

  describe "last_active_at" do
    test "is stamped on successful password sign-in" do
      created = generate(user(password: "password1234", password_confirmation: "password1234"))
      refute created.last_active_at

      signed_in =
        Accounts.sign_in_with_password!(to_string(created.email), "password1234", %{},
          authorize?: false
        )

      assert signed_in.last_active_at
    end
  end

  describe "handle generation" do
    test "slugifies first_name and last_name, joined by an underscore" do
      user = generate(user(first_name: "Jane", last_name: "Doe"))

      assert user.handle == "jane_doe"
    end

    test "falls back to just first_name when last_name is blank" do
      user = generate(user(first_name: "Jane", last_name: nil))

      assert user.handle == "jane"
    end

    test "drops a name part that slugifies to nothing instead of leaving a stray underscore" do
      user = generate(user(first_name: "Jane", last_name: "★★★"))

      assert user.handle == "jane"
    end

    test "suffixes on collision" do
      generate(user(first_name: "Jane", last_name: "Doe"))
      second = generate(user(first_name: "Jane", last_name: "Doe"))

      assert second.handle == "jane_doe_1"
    end

    test "pads a name shorter than the 3-character minimum" do
      user = generate(user(first_name: "Al", last_name: nil))

      assert user.handle == "al_1"
    end

    test "truncates a name longer than the 30-character maximum" do
      user = generate(user(first_name: String.duplicate("a", 40), last_name: nil))

      assert user.handle == String.duplicate("a", 30)
    end

    test "leaves no trailing underscore when truncation lands on a separator" do
      user = generate(user(first_name: String.duplicate("a", 30), last_name: "Doe"))

      assert user.handle == String.duplicate("a", 30)
      refute String.ends_with?(user.handle, "_")
    end

    test "keeps a truncated handle within the maximum once a collision suffix is added" do
      first = generate(user(first_name: String.duplicate("b", 40), last_name: nil))
      second = generate(user(first_name: String.duplicate("b", 40), last_name: nil))

      assert first.handle == String.duplicate("b", 30)
      assert second.handle == String.duplicate("b", 28) <> "_1"
      assert String.length(second.handle) <= 30
    end
  end

  describe "update_handle" do
    test "updates the handle and stamps handle_changed_at" do
      user = generate(user())

      assert {:ok, updated} = Accounts.update_handle(user, "new_handle", %{}, authorize?: false)
      assert updated.handle == "new_handle"
      assert updated.handle_changed_at
    end

    test "rejects a reserved handle" do
      user = generate(user())

      assert {:error, changeset} = Accounts.update_handle(user, "admin", %{}, authorize?: false)

      assert "is reserved" in field_error_messages(changeset, :handle)
    end

    test "rejects uppercase or invalid characters" do
      user = generate(user())

      assert {:error, error} =
               Accounts.update_handle(user, "Jane Doe!", %{}, authorize?: false)

      assert field_error_messages(error, :handle) != []
    end

    test "rejects a second change within the cooldown window" do
      user = generate(user())

      assert {:ok, first} = Accounts.update_handle(user, "first_handle", %{}, authorize?: false)

      assert {:error, changeset} =
               Accounts.update_handle(first, "second_handle", %{}, authorize?: false)

      assert "must wait before changing handle again" in field_error_messages(changeset, :handle)
    end

    test "allows a change within the cooldown window when the setting is lowered" do
      Setting
      |> Ash.Changeset.for_create(:create, %{handle_change_cooldown_days: 0})
      |> Ash.create!(authorize?: false)

      user = generate(user())

      assert {:ok, first} = Accounts.update_handle(user, "first_handle", %{}, authorize?: false)

      assert {:ok, second} =
               Accounts.update_handle(first, "second_handle", %{}, authorize?: false)

      assert second.handle == "second_handle"
    end
  end

  describe "update_avatar" do
    setup do
      tmp_dir =
        Path.join(System.tmp_dir!(), "mercato_avatar_test_#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp_dir)
      Application.put_env(:mercato, Mercato.Ports.Storage.Local, storage_path: tmp_dir)

      on_exit(fn ->
        Application.delete_env(:mercato, Mercato.Ports.Storage.Local)
        File.rm_rf!(tmp_dir)
      end)

      :ok
    end

    test "uploads the image via the storage port and sets avatar_url" do
      user = generate(user())
      refute user.avatar_url

      updated =
        user
        |> Ash.Changeset.for_update(
          :update_avatar,
          %{avatar: "fake image bytes", filename: "photo.jpg"},
          authorize?: false
        )
        |> Ash.update!()

      assert updated.avatar_url =~ "photo.jpg"

      storage = Application.fetch_env!(:mercato, :storage_adapter)
      key = String.trim_leading(updated.avatar_url, "/uploads/")
      assert {:ok, "fake image bytes"} == storage.get(key)
    end
  end
end
