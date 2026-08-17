defmodule Mercato.Accounts.User.Changes.GenerateHandle do
  @moduledoc """
  Silently fills in `handle` on create when none is provided.

  Falls back to `first_name_last_name` (slugified), then the email's local
  part, then the literal "user" — suffixed `_1`, `_2`, ... on collision.
  """

  use Ash.Resource.Change

  alias Mercato.Accounts.User
  alias Mercato.Accounts.User.ReservedHandles

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :handle) do
      handle when is_binary(handle) and handle != "" ->
        changeset

      _blank ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :handle,
          unique_handle(base_handle(changeset))
        )
    end
  end

  defp base_handle(changeset) do
    first_name = Ash.Changeset.get_attribute(changeset, :first_name)
    last_name = Ash.Changeset.get_attribute(changeset, :last_name)

    case [first_name, last_name]
         |> Enum.reject(&(&1 in [nil, ""]))
         |> Enum.map(&slugify/1)
         |> Enum.reject(&(&1 == "")) do
      [] -> base_handle_from_email(changeset)
      parts -> Enum.join(parts, "_")
    end
  end

  defp base_handle_from_email(changeset) do
    case Ash.Changeset.get_attribute(changeset, :email) do
      nil ->
        "user"

      email ->
        case email |> to_string() |> String.split("@") |> List.first() |> slugify() do
          "" -> "user"
          local_part -> local_part
        end
    end
  end

  defp slugify(string) do
    string
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "_")
    |> String.trim("_")
  end

  defp unique_handle(base) do
    if handle_taken?(base), do: unique_handle(base, 1), else: base
  end

  defp unique_handle(base, suffix) do
    candidate = "#{base}_#{suffix}"
    if handle_taken?(candidate), do: unique_handle(base, suffix + 1), else: candidate
  end

  defp handle_taken?(handle) do
    ReservedHandles.reserved?(handle) or
      !is_nil(Ash.get!(User, [handle: handle], authorize?: false, not_found_error?: false))
  end
end
