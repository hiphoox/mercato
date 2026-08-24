defmodule Mercato.Listings.ListingImage.Changes.PromoteNextCover do
  @moduledoc """
  Hands the cover slot to the image at the front of what remains, so deleting a
  listing's cover never leaves it with images and none of them covering.
  """

  use Ash.Resource.Change

  alias Mercato.Listings

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.after_action(changeset, fn _changeset, image ->
      # Asked of the gallery rather than of the destroyed record: a caller
      # holding a struct fetched before the image was promoted would say it was
      # not the cover, and the listing would be left without one.
      image.listing_id
      |> Listings.list_listing_images!(Ash.Context.to_opts(context))
      |> promote_front(Ash.Context.to_opts(context))

      {:ok, image}
    end)
  end

  defp promote_front([], _opts), do: :ok

  defp promote_front([front | _] = images, opts) do
    if Enum.any?(images, & &1.is_cover) do
      :ok
    else
      Listings.set_listing_image_cover!(front, opts)
    end
  end
end
