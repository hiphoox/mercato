defmodule Mercato.Accounts.User.Validations.AccountCanSignIn do
  @moduledoc """
  Rejects sign-in when an account already exists for the changeset's email and
  its status is not one that may hold a session (see
  `Mercato.Accounts.User.Status.can_sign_in/0`).

  This guards the upsert-shaped magic-link sign-in, where a filter on the read
  can't do the job: the action would otherwise create a second account rather
  than refuse the banned one it failed to find.
  """

  use Ash.Resource.Validation

  alias Mercato.Accounts.User
  alias Mercato.Accounts.User.Status

  @impl true
  def validate(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :email) do
      nil -> :ok
      email -> validate_existing(email)
    end
  end

  # No account for the email means this is a registration, not a blocked
  # sign-in, so there is nothing to refuse.
  defp validate_existing(email) do
    case Ash.get(User, [email: email], authorize?: false, not_found_error?: false) do
      {:ok, %User{status: status}} -> validate_status(status)
      _ -> :ok
    end
  end

  defp validate_status(status) do
    if status in Status.can_sign_in(),
      do: :ok,
      else: {:error, field: :email, message: "account is not active"}
  end
end
