defmodule Mercato.Listings.Listing.Status do
  @moduledoc """
  Where a listing sits in its lifecycle.

  `:draft` is seller-only and unpublished. `:active` is the only state a
  public browse or search returns. `:unavailable` is a reversible pause.
  `:sold` and `:deleted` are terminal.
  """
  use Ash.Type.Enum, values: [:draft, :active, :unavailable, :sold, :deleted]
end
