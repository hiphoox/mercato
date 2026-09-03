defmodule Mercato.Payments.SellerDeduction.Validations.BasisNotCircular do
  @moduledoc """
  Refuses a deduction that would end up a percentage of itself.

  A row may be a percentage of another, and that one of a third, so what a row
  takes is only knowable by following the chain it names. A chain that closes
  on itself has no answer at all, so it is refused where it would be written
  rather than discovered where it is read.
  """
  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidAttribute
  alias Mercato.Payments

  @impl true
  def validate(changeset, _opts, _context) do
    of_id = Ash.Changeset.get_attribute(changeset, :of_id)

    if of_id && closes?(of_id, changeset.data.id) do
      {:error,
       InvalidAttribute.exception(
         field: :of_id,
         message: "would make a deduction a percentage of itself"
       )}
    else
      :ok
    end
  end

  # Read in one go and walked in memory: a chain is a handful of rows, and
  # querying each link in turn would ask the same table the same question over
  # and over.
  defp closes?(of_id, id) do
    by_id = Map.new(Payments.list_seller_deductions!(authorize?: false), &{&1.id, &1})

    reaches?(of_id, id, by_id)
  end

  defp reaches?(nil, _id, _by_id), do: false
  defp reaches?(id, id, _by_id), do: true

  defp reaches?(of_id, id, by_id) do
    case Map.fetch(by_id, of_id) do
      {:ok, row} -> reaches?(row.of_id, id, by_id)
      :error -> false
    end
  end
end
