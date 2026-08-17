defmodule Mercato.Ports.Storage.Local do
  @moduledoc """
  Default `Mercato.Ports.Storage` adapter — files live on disk under
  `priv/static/uploads`, served back over HTTP by Phoenix's static plug.
  Requires no external service, per Mercato's infra-less default.
  """

  @behaviour Mercato.Ports.Storage

  @impl true
  def put(key, data, _opts \\ []) do
    with {:ok, path} <- resolve(key) do
      path |> Path.dirname() |> File.mkdir_p!()

      case File.write(path, data) do
        :ok -> {:ok, key}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def get(key) do
    with {:ok, path} <- resolve(key) do
      File.read(path)
    end
  end

  @impl true
  def delete(key) do
    with {:ok, path} <- resolve(key) do
      case File.rm(path) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @impl true
  def url(key, _opts \\ []) do
    "/uploads/" <> key
  end

  defp resolve(key) do
    base = Path.expand(storage_path())
    path = Path.expand(Path.join(base, key))

    if path == base or String.starts_with?(path, base <> "/") do
      {:ok, path}
    else
      {:error, :invalid_key}
    end
  end

  defp storage_path do
    :mercato
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:storage_path, Application.app_dir(:mercato, "priv/static/uploads"))
  end
end
