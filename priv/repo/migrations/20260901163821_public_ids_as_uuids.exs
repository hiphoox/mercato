defmodule Mercato.Repo.Migrations.PublicIdsAsUuids do
  @moduledoc """
  Re-mints every public id as a uuid.

  Hand-written over what `mix ash.codegen` generated: SQLite has no ALTER
  COLUMN, and it does not need one — a uuid column is TEXT here either way, so
  only the values change. The ids minted before this are eight characters and
  would not survive being read back as uuids, so each row is given a new one.
  Any link shared before this point stops resolving; there is no way to widen an
  identifier and keep the narrow one.
  """

  use Ecto.Migration

  # A v4 uuid assembled from SQLite's only per-row randomness, with the version
  # and variant nibbles pinned so what comes out is a uuid and not just 32 hex
  # characters wearing hyphens.
  @uuid """
  lower(
    substr(hex(randomblob(4)), 1, 8) || '-' ||
    substr(hex(randomblob(2)), 1, 4) || '-4' ||
    substr(hex(randomblob(2)), 2, 3) || '-' ||
    substr('89ab', abs(random()) % 4 + 1, 1) ||
    substr(hex(randomblob(2)), 2, 3) || '-' ||
    substr(hex(randomblob(6)), 1, 12)
  )
  """

  def up do
    execute "UPDATE listings SET public_id = #{@uuid}"
    execute "UPDATE orders SET public_id = #{@uuid}"
  end

  def down do
    execute "UPDATE listings SET public_id = lower(hex(randomblob(4)))"
    execute "UPDATE orders SET public_id = lower(hex(randomblob(4)))"
  end
end
