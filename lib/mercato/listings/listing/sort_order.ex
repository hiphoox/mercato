defmodule Mercato.Listings.Listing.SortOrder do
  @moduledoc """
  The orders the public browse grid can be read in.

  `:newest` is the default and the only one the front door can offer without
  a signal it does not have: recency is a fact about every listing, where
  relevance would need a ranking this marketplace has nothing to build one
  from. The two price orders are the buyer's own signal, stated by hand.

  Declared as a type rather than as a list in the action, so the values are one
  fact the resource validates against and the bar reads its options from.
  """
  use Ash.Type.Enum, values: [:newest, :price_asc, :price_desc]
end
