defmodule Mercato.Listings.ListingImage.ContentType do
  @moduledoc """
  Identifies an uploaded file from the bytes it starts with.

  Every image format carries a fixed signature in its opening bytes. Reading it
  is what makes the check server-side: a filename or a caller-supplied content
  type is a claim, and a hostile caller controls both.
  """

  @doc """
  The type of `data`, or `:error` when its opening bytes match no known format.
  """
  @spec detect(binary()) :: {:ok, String.t()} | :error
  def detect(<<0xFF, 0xD8, 0xFF, _rest::binary>>), do: {:ok, "image/jpeg"}
  def detect(<<0x89, "PNG\r\n", 0x1A, 0x0A, _rest::binary>>), do: {:ok, "image/png"}
  def detect(<<"GIF87a", _rest::binary>>), do: {:ok, "image/gif"}
  def detect(<<"GIF89a", _rest::binary>>), do: {:ok, "image/gif"}
  # The size field between the two markers is part of the RIFF container.
  def detect(<<"RIFF", _size::binary-size(4), "WEBP", _rest::binary>>), do: {:ok, "image/webp"}
  def detect(_data), do: :error
end
