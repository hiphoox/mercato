defmodule Mercato.Repo.Migrations.CartsGoWithADeletedListing do
  @moduledoc """
  Deletes a listing's cart lines along with the listing.

  Written by hand: SQLite cannot alter a foreign key, so adding the cascade
  means rebuilding the table around it and carrying the rows across.
  """

  use Ecto.Migration

  def up, do: rebuild(on_delete: :delete_all)

  def down, do: rebuild(on_delete: :nothing)

  defp rebuild(listing_opts) do
    create table(:cart_items_rebuild, primary_key: false) do
      add :seller_id,
          references(:users, column: :id, name: "cart_items_seller_id_fkey", type: :uuid),
          null: false

      add :listing_id,
          references(
            :listings,
            [column: :id, name: "cart_items_listing_id_fkey", type: :uuid] ++ listing_opts
          ),
          null: false

      add :user_id, references(:users, column: :id, name: "cart_items_user_id_fkey", type: :uuid)

      add :guest_token, :text
      add :updated_at, :utc_datetime_usec, null: false
      add :inserted_at, :utc_datetime_usec, null: false
      add :quantity, :bigint, null: false
      add :id, :uuid, null: false, primary_key: true
    end

    execute """
    INSERT INTO cart_items_rebuild
      (id, user_id, guest_token, listing_id, seller_id, quantity, inserted_at, updated_at)
    SELECT id, user_id, guest_token, listing_id, seller_id, quantity, inserted_at, updated_at
    FROM cart_items
    """

    drop table(:cart_items)
    rename table(:cart_items_rebuild), to: table(:cart_items)

    create unique_index(:cart_items, [:user_id, :listing_id],
             name: "cart_items_unique_user_listing_index"
           )

    create unique_index(:cart_items, [:guest_token, :listing_id],
             name: "cart_items_unique_guest_listing_index"
           )
  end
end
