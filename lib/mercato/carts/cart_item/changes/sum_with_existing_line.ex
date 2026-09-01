defmodule Mercato.Carts.CartItem.Changes.SumWithExistingLine do
  @moduledoc """
  Folds what the buyer is adding into the line they already have.

  Read and summed here rather than incremented by the database, which cannot
  range-check the result of an expression it computes: the data layer offers
  none of the SQL-side error reporting an atomic update of a constrained
  attribute would need.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      adding = Ash.Changeset.get_attribute(changeset, :quantity)
      listing_id = Ash.Changeset.get_argument(changeset, :listing_id)

      case existing_line(listing_id, context) do
        {:ok, %{quantity: held}} ->
          Ash.Changeset.force_change_attribute(changeset, :quantity, held + adding)

        _ ->
          changeset
      end
    end)
  end

  defp existing_line(listing_id, context) do
    Mercato.Carts.CartItem
    |> Ash.Query.for_read(:line_for_listing, %{listing_id: listing_id}, actor: context.actor)
    |> Ash.read_one()
  end
end
