defmodule Mercato.Accounts.User.Validations.AccountActive do
  @moduledoc """
  Rejects sign-in when an account already exists for the changeset's email
  and its status is not `:active` (banned/deleted).
  """

  use Ash.Resource.Validation

  alias Mercato.Accounts.User

  @impl true
  def validate(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :email) do
      nil ->
        :ok

      email ->
        case Ash.get(User, [email: email], authorize?: false, not_found_error?: false) do
          {:ok, %User{status: status}} when status != :active ->
            {:error, field: :email, message: "account is not active"}

          _ ->
            :ok
        end
    end
  end
end
