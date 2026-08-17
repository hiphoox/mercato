defmodule Mercato.Ports.Storage do
  @moduledoc """
  Contract for storing and retrieving file blobs by an opaque key.

  Implementations must be interchangeable: same return shapes, same semantics,
  regardless of where the bytes actually live (local disk, S3-compatible
  object storage, etc).
  """

  @callback put(key :: String.t(), data :: iodata(), opts :: keyword()) ::
              {:ok, String.t()} | {:error, term()}
  @callback get(key :: String.t()) :: {:ok, binary()} | {:error, term()}
  @callback delete(key :: String.t()) :: :ok | {:error, term()}
  @callback url(key :: String.t(), opts :: keyword()) :: String.t()
end
