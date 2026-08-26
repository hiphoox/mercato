defmodule Mercato.Repo.Migrations.AddListingPublicId do
  @moduledoc """
  Gives every listing the short identifier its public URL is built from.

  Hand-extended past what `mix ash.codegen` generated: SQLite cannot add a
  NOT NULL column to a populated table without a default, so the column arrives
  with a placeholder, existing rows are given real ids, and only then is
  uniqueness enforced. The placeholder is never reached again — every listing
  created through the resource is minted one before it is inserted.
  """

  use Ecto.Migration

  def up do
    alter table(:listings) do
      add :public_id, :text, null: false, default: ""
    end

    # Eight hex characters, matching the length and alphabet the resource mints:
    # `randomblob` is the only per-row random SQLite offers in an UPDATE.
    execute "UPDATE listings SET public_id = lower(hex(randomblob(4))) WHERE public_id = ''"

    # After the backfill, or the placeholder every existing row shares would
    # collide with itself.
    create unique_index(:listings, [:public_id], name: "listings_unique_public_id_index")
  end

  def down do
    drop_if_exists unique_index(:listings, [:public_id], name: "listings_unique_public_id_index")

    alter table(:listings) do
      remove :public_id
    end
  end
end
