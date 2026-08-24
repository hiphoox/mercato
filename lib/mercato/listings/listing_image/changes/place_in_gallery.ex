defmodule Mercato.Listings.ListingImage.Changes.PlaceInGallery do
  @moduledoc """
  Gives a new image its slot in the listing's gallery: appended behind the
  images already there, and covering if it is the first one.
  """

  use Ash.Resource.Change

  alias Mercato.Listings

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      siblings =
        changeset
        |> Ash.Changeset.get_attribute(:listing_id)
        |> Listings.list_listing_images!(Ash.Context.to_opts(context))

      Ash.Changeset.force_change_attributes(changeset, %{
        position: next_position(siblings),
        is_cover: siblings == []
      })
    end)
  end

  # Behind the last image rather than into the first gap: a gap is left by a
  # deleted image, and filling it would put the newcomer ahead of images the
  # seller already ordered.
  defp next_position([]), do: 0
  defp next_position(siblings), do: List.last(siblings).position + 1
end
