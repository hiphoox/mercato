defmodule MercatoWeb.UI.ListingStatusBadge do
  @moduledoc """
  The badge naming the lifecycle state a listing is in.

  One place deciding how each state reads, which badge kind carries it, and
  which icon marks it, so a listing labelled "Active" on one page is never
  "Live" on the next, and the seller's form and the listing's own page agree.

      <.listing_status_badge status={@listing.status} />
  """
  use MercatoWeb, :html

  # Keyed on the states in `Mercato.Listings.Listing.Status`. `deleted` is here
  # for completeness — only moderation ever sees one — and reads as danger
  # because it is the state that stops a listing.
  #
  # Each state carries an icon as well as a colour, so the state is never told
  # by colour alone. How it reads is not held here: a label built at compile
  # time is invisible to translation extraction, so it is a clause below.
  @states %{
    draft: {"neutral", "hero-pencil-square"},
    active: {"verified", "hero-check-badge"},
    unavailable: {"warning", "hero-pause-circle"},
    sold: {"info", "hero-check-circle"},
    deleted: {"danger", "hero-archive-box-x-mark"}
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
    {kind, icon} = Map.fetch!(@states, assigns.status)

    assigns = assign(assigns, kind: kind, icon: icon, label: label(assigns.status))

    ~H"""
    <.badge kind={@kind} class={["gap-1.5", @class]} {@rest}>
      <.icon name={@icon} aria-hidden="true" class="size-3.5" />{@label}
    </.badge>
    """
  end

  @doc "How `status` reads to a trader, without the badge around it."
  # A clause each rather than a lookup table: extraction reads the source, and
  # a label built at compile time is invisible to it.
  def label(:draft), do: gettext("Draft")
  def label(:active), do: gettext("Active")
  def label(:unavailable), do: gettext("Paused")
  def label(:sold), do: gettext("Sold")
  def label(:deleted), do: gettext("Removed")

  @doc "The icon marking `status`, without the badge around it."
  def status_icon(status), do: @states |> Map.fetch!(status) |> elem(1)
end
