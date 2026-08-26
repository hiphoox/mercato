defmodule Mercato.Listings.Listing.PublicId do
  @moduledoc """
  Mints the short identifier a listing is known by in public.

  Separate from the primary key so the URL a seller shares stays short,
  readable, and free to outlive whatever the database uses internally.
  """

  # Crockford's base32 without i, l, o and u: nothing a reader can mistake for
  # another character when a link is copied off a screen or read aloud.
  @alphabet ~c"0123456789abcdefghjkmnpqrstvwxyz"
  @length 8

  @doc """
  A new public id: #{@length} characters drawn at random from the alphabet.

  Random rather than sequential, so a listing's URL says nothing about how many
  the marketplace holds or in what order they arrived.
  """
  def generate do
    for _ <- 1..@length, into: "", do: <<Enum.random(@alphabet)>>
  end
end
