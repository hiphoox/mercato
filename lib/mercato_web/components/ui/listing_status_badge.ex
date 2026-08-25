defmodule MercatoWeb.UI.ListingStatusBadge do
  @moduledoc """
  The badge naming the lifecycle state a listing is in.

  One place deciding how each state reads and which badge kind carries it, so
  a listing labelled "Live" on one page is never "Active" on the next.

      <.listing_status_badge status={@listing.status} />
  """
  use MercatoWeb, :html

  # Keyed on the states in `Mercato.Listings.Listing.Status`. `deleted` is here
  # for completeness — only moderation ever sees one — and reads as danger
  # because it is the state that stops a listing.
  @states %{
    draft: {"neutral", "Draft"},
    active: {"verified", "Live"},
    unavailable: {"warning", "Paused"},
    sold: {"info", "Sold"},
    deleted: {"danger", "Removed"}
  }

  @doc """
  Renders the badge for `status`.

  Words are the trader's rather than the schema's: a seller thinks of a listing
  as live or paused, not as `active` or `unavailable`.
  """
  attr :status, :atom, required: true, values: Map.keys(@states)
  attr :class, :any, default: nil
  attr :rest, :global

  def listing_status_badge(assigns) do
    {kind, label} = Map.fetch!(@states, assigns.status)

    assigns = assign(assigns, kind: kind, label: label)

    ~H"""
    <.badge kind={@kind} class={@class} {@rest}>{@label}</.badge>
    """
  end

  @doc "How `status` reads to a trader, without the badge around it."
  def label(status), do: @states |> Map.fetch!(status) |> elem(1)
end
