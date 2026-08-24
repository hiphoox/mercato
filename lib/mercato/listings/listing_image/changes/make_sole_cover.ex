defmodule Mercato.Listings.ListingImage.Changes.MakeSoleCover do
  @moduledoc """
  Promotes this image to cover, standing down whichever of its listing's images
  was covering before.
  """

  use Ash.Resource.Change

  alias Mercato.Listings

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      opts = Ash.Context.to_opts(context)
      image = changeset.data

      # Demoted first: the database allows only one covering row per listing, so
      # promoting before the incumbent steps down is refused.
      image.listing_id
      |> Listings.list_listing_images!(opts)
      |> Enum.filter(&(&1.is_cover and &1.id != image.id))
      |> Enum.each(&demote(&1, opts))

      Ash.Changeset.force_change_attribute(changeset, :is_cover, true)
    end)
  end

  defp demote(image, opts) do
    image
    |> Ash.Changeset.for_update(:demote_cover, %{}, opts)
    |> Ash.update!()
  end
end
