defmodule Mercato.Payments.SellerDeduction.Validations.NotDependedOn do
  @moduledoc """
  Refuses dropping a deduction another one is a percentage of.

  Removing it would leave the rows that name it taking a percentage of nothing,
  which is not what an operator dropping a commission means to do to the tax
  stacked on it. Saying so is better than either silently re-basing those rows
  on the sale price or silently dropping them too — both change what a seller
  is paid without anybody deciding to.
  """
  use Ash.Resource.Validation

  alias Ash.Error.Changes.InvalidAttribute
  alias Mercato.Payments

  @impl true
  def validate(changeset, _opts, _context) do
    id = changeset.data.id

    if Enum.any?(Payments.list_seller_deductions!(authorize?: false), &(&1.of_id == id)) do
      {:error,
       InvalidAttribute.exception(
         field: :name,
         message: "is what another deduction is a percentage of"
       )}
    else
      :ok
    end
  end
end
