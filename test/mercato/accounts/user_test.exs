defmodule Mercato.Accounts.UserTest do
  use Mercato.DataCase, async: true

  alias Mercato.Accounts.Setting

  import Mercato.TestGenerators

  defp field_error_messages(%Ash.Error.Invalid{errors: errors}, field) do
    errors
    |> Enum.filter(&(&1.field == field))
    |> Enum.map(& &1.message)
  end

  describe "status" do
    test "defaults to :active on registration" do
      user = generate(user())

      assert user.status == :active
    end
  end

  describe "last_active_at" do
    test "is stamped on successful password sign-in" do
      created = generate(user(password: "password1234", password_confirmation: "password1234"))
      refute created.last_active_at

      signed_in =
        Mercato.Accounts.User
        |> Ash.Query.for_read(:sign_in_with_password, %{
          email: created.email,
          password: "password1234"
        })
        |> Ash.read_one!(authorize?: false)

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
  end

  describe "update_handle" do
    test "updates the handle and stamps handle_changed_at" do
      user = generate(user())

      updated =
        user
        |> Ash.Changeset.for_update(:update_handle, %{handle: "new_handle"}, authorize?: false)
        |> Ash.update!()

      assert updated.handle == "new_handle"
      assert updated.handle_changed_at
    end

    test "rejects a reserved handle" do
      user = generate(user())

      assert {:error, changeset} =
               user
               |> Ash.Changeset.for_update(:update_handle, %{handle: "admin"}, authorize?: false)
               |> Ash.update()

      assert "is reserved" in field_error_messages(changeset, :handle)
    end

    test "rejects uppercase or invalid characters" do
      user = generate(user())

      assert {:error, error} =
               user
               |> Ash.Changeset.for_update(:update_handle, %{handle: "Jane Doe!"},
                 authorize?: false
               )
               |> Ash.update()

      assert field_error_messages(error, :handle) != []
    end

    test "rejects a second change within the cooldown window" do
      user = generate(user())

      first =
        user
        |> Ash.Changeset.for_update(:update_handle, %{handle: "first_handle"}, authorize?: false)
        |> Ash.update!()

      assert {:error, changeset} =
               first
               |> Ash.Changeset.for_update(:update_handle, %{handle: "second_handle"},
                 authorize?: false
               )
               |> Ash.update()

      assert "must wait before changing handle again" in field_error_messages(changeset, :handle)
    end

    test "allows a change within the cooldown window when the setting is lowered" do
      Setting
      |> Ash.Changeset.for_create(:create, %{handle_change_cooldown_days: 0})
      |> Ash.create!(authorize?: false)

      user = generate(user())

      first =
        user
        |> Ash.Changeset.for_update(:update_handle, %{handle: "first_handle"}, authorize?: false)
        |> Ash.update!()

      assert {:ok, second} =
               first
               |> Ash.Changeset.for_update(:update_handle, %{handle: "second_handle"},
                 authorize?: false
               )
               |> Ash.update()

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
