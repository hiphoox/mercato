defmodule Mercato.Carts.CartItem.Changes.AttachToBuyer do
  @moduledoc """
  Says whose the line is: the account acting, or the visitor's guest token
  when there is no account.

  The account wins where there is one, so a visitor who signs in mid-visit
  gathers into their own cart from then on rather than into the token's.

  It also names the identity the upsert dedupes on, which the action cannot
  declare because it depends on which of the two owners the line ends up with.
  """
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, context) do
    case {context.actor, guest_token(context)} do
      {%{id: user_id}, _guest_token} ->
        changeset
        |> Ash.Changeset.force_change_attribute(:user_id, user_id)
        |> dedupe_on(:unique_user_listing)

      {nil, guest_token} when is_binary(guest_token) ->
        changeset
        |> Ash.Changeset.force_change_attribute(:guest_token, guest_token)
        |> dedupe_on(:unique_guest_listing)

      {nil, nil} ->
        Ash.Changeset.add_error(changeset,
          field: :user_id,
          message: "is needed to gather a cart, as is a visitor's token"
        )
    end
  end

  defp guest_token(context), do: get_in(context.source_context, [:shared, :guest_token])

  defp dedupe_on(changeset, identity),
    do: Ash.Changeset.set_context(changeset, %{private: %{upsert_identity: identity}})
end
