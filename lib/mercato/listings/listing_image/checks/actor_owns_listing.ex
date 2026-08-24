defmodule Mercato.Listings.ListingImage.Checks.ActorOwnsListing do
  @moduledoc """
  Policy check: is the actor the seller of the listing this image is being added
  to?

  A check rather than an expression because on a create there is no row yet to
  join from — only the listing id the caller supplied.
  """

  use Ash.Policy.SimpleCheck

  require Ash.Query

  alias Mercato.Listings.Listing

  @impl true
  def describe(_opts), do: "actor owns the listing the image belongs to"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: changeset}, _opts) when not is_nil(changeset) do
    changeset
    |> Ash.Changeset.get_attribute(:listing_id)
    |> owns?(actor)
  end

  def match?(_actor, _context, _opts), do: false

  defp owns?(nil, _actor), do: false

  defp owns?(listing_id, actor) do
    Listing
    |> Ash.Query.filter(id == ^listing_id and seller_id == ^actor.id)
    |> Ash.Query.limit(1)
    |> Ash.read!(authorize?: false)
    |> Enum.any?()
  end
end
