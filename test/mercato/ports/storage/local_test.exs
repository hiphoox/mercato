defmodule Mercato.Ports.Storage.LocalTest do
  use ExUnit.Case, async: true

  alias Mercato.Ports.Storage.Local

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "mercato_storage_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    Application.put_env(:mercato, Local, storage_path: tmp_dir)

    on_exit(fn ->
      Application.delete_env(:mercato, Local)
      File.rm_rf!(tmp_dir)
    end)

    :ok
  end

  test "put/3 writes the file and returns the key" do
    assert {:ok, "listings/1/photo.jpg"} = Local.put("listings/1/photo.jpg", "binary-data")
  end

  test "get/1 reads back what was written" do
    {:ok, _key} = Local.put("a.txt", "hello")
    assert {:ok, "hello"} = Local.get("a.txt")
  end

  test "get/1 returns an error for a missing key" do
    assert {:error, :enoent} = Local.get("missing.txt")
  end

  test "delete/1 removes the file and is idempotent" do
    {:ok, _key} = Local.put("a.txt", "hello")

    assert :ok = Local.delete("a.txt")
    assert {:error, :enoent} = Local.get("a.txt")
    assert :ok = Local.delete("a.txt")
  end

  test "url/2 returns the path served by the static plug" do
    assert Local.url("listings/1/photo.jpg") == "/uploads/listings/1/photo.jpg"
  end

  test "rejects a key that attempts path traversal" do
    assert {:error, :invalid_key} = Local.put("../escape.txt", "data")
    assert {:error, :invalid_key} = Local.get("../../etc/passwd")
    assert {:error, :invalid_key} = Local.delete("../escape.txt")
  end
end
