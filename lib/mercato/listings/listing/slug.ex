defmodule Mercato.Listings.Listing.Slug do
  @moduledoc """
  The two directions of a listing's public URL: building one, and reading the
  listing back out of one.

  A slug is the title in readable form followed by the listing's public id, and
  only that trailing id identifies anything. The title part is decoration for
  whoever sees the link, so a seller may retitle freely and every link already
  shared keeps resolving.
  """

  alias Mercato.Listings.Listing

  # Long enough for the title to be recognisable in a pasted link, short enough
  # that the whole URL still survives a chat window.
  @title_length 60

  @doc "The canonical URL segment for `listing`."
  def slug(%Listing{title: title, public_id: public_id}) do
    case titleize(title) do
      "" -> public_id
      readable -> readable <> "-" <> public_id
    end
  end

  # The id is a uuid, so it carries separators of its own: the whole shape has to
  # be matched at the end rather than the last separator split on.
  @public_id ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  @doc """
  The public id inside a URL segment, whatever title preceded it.

  Matched from the end rather than parsed, because the title part may contain any
  number of separators and may no longer match the listing's current title.
  """
  def public_id(segment) when is_binary(segment) do
    case Regex.run(@public_id, segment) do
      [public_id] -> public_id
      nil -> segment
    end
  end

  # Keeps only what reads unambiguously in a URL: everything else becomes a
  # separator, and runs of separators collapse to one.
  defp titleize(title) do
    title
    |> String.downcase()
    |> deaccent()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> truncate()
  end

  # Splits an accented letter into the plain letter plus its accent, then drops
  # the accent, so "Sillon" survives where dropping the whole character would
  # have left a gap. A script with no plain-letter equivalent still falls away.
  defp deaccent(title) do
    title
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
  end

  # Cut at a separator rather than mid-word, so a shortened title still reads as
  # words and never leaves a dangling separator before the public id.
  defp truncate(readable) when byte_size(readable) <= @title_length, do: readable

  defp truncate(readable) do
    readable
    |> binary_part(0, @title_length)
    |> String.replace(~r/-[^-]*\z/, "")
  end
end
