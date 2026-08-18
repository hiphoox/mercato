defmodule Mercato.Accounts.User.Validations.HandleNotReserved do
  @moduledoc false

  use Ash.Resource.Validation

  alias Mercato.Accounts.User.ReservedHandles

  @impl true
  def validate(changeset, _opts, _context) do
    handle = Ash.Changeset.get_attribute(changeset, :handle)

    if is_binary(handle) and ReservedHandles.reserved?(handle) do
      {:error, field: :handle, message: "is reserved"}
    else
      :ok
    end
  end
end
