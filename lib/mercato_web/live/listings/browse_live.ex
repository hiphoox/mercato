defmodule MercatoWeb.Listings.BrowseLive do
  @moduledoc """
  The marketplace as anyone arriving at it sees it: everything on offer,
  newest first, narrowed by a search term when there is one.

  This is the front door, so it is the one page that assumes nothing — no
  account, no history, no stated interest. What it can honestly order by is
  recency, which is why the grid leads with what was just listed rather than
  with a ranking it has no signal to build.

  Everyone gets the same grid, a seller included: it is the marketplace, not
  an account view, and a seller's own drafts and paused listings belong on
  their listings page rather than mixed into the public shelf.

  The term lives in the query string rather than in assigns alone, so a search
  can be linked, shared and reloaded, and so the header's box — which is drawn
  on every page and submits here — has somewhere to send it.

  Filtering and paging the grid are not here yet. The bar that carries them
  sits between the heading and the grid; until it exists this page is that
  layout with the bar left out, not a different one.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingGrid

  alias Mercato.Listings

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params |> Map.get("q", "") |> to_string() |> String.trim()
    category = scope(params, socket.assigns.search_categories)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:category, category && category.slug)
     |> assign(:category_name, category && category.name)
     |> assign(:listings, listings(query, category))}
  end

  defp scope(params, categories) do
    slug = params |> Map.get("category", "") |> to_string() |> String.trim()

    Enum.find(categories, &(&1.slug == slug))
  end

  defp listings(query, category) do
    Listings.browse_listings!(%{
      query: query,
      category_slug: (category && category.slug) || ""
    })
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={@current_user}
      admin?={@admin?}
      current_path={~p"/"}
      query={@query}
      categories={@search_categories}
      category={@category}
    >
      <%!-- No breadcrumb: this is where the trail every other page draws
            starts, and a crumb pointing at the page you are on is noise. --%>
      <div id="browse" class="flex flex-col gap-6">
        <.header>
          {heading(@query, @category_name, @listings)}
          <:subtitle>{subtitle(@query, @category_name, @listings)}</:subtitle>
        </.header>

        <%!-- Two different emptinesses, because they have two different causes
              and only one of them is the visitor's to fix. --%>
        <.empty_state
          :if={@listings == [] and @query == "" and is_nil(@category)}
          id="nothing-listed"
          icon="hero-archive-box"
          headline={gettext("Nothing is on offer yet")}
          description={
            gettext(
              "No one has listed anything for sale so far. The first listing published shows up here."
            )
          }
        >
          <:actions>
            <.button :if={@current_user} size="md" navigate={~p"/listings/new"}>
              {gettext("List something")}
            </.button>
          </:actions>
        </.empty_state>

        <.empty_state
          :if={@listings == [] and (@query != "" or not is_nil(@category))}
          id="no-results"
          icon="hero-magnifying-glass"
          headline={no_results_headline(@query, @category_name)}
          description={no_results_description(@query)}
        >
          <:actions>
            <.button id="clear-search" size="md" variant="neutral" phx-click="clear_search">
              {gettext("Clear search")}
            </.button>
          </:actions>
        </.empty_state>

        <.listing_grid :if={@listings != []} id="browse-grid">
          <.listing_card
            :for={listing <- @listings}
            id={"browse-listing-#{listing.id}"}
            title={listing.title}
            price={listing.display_price}
            navigate={~p"/listings/#{listing}"}
            image_src={cover_url(listing)}
            image_alt={gettext("Cover photo of %{title}", title: listing.title)}
            class="transition-shadow hover:shadow-md"
          >
            <:meta>{seller_handle(listing)} · {listed_ago(listing)}</:meta>
          </.listing_card>
        </.listing_grid>
      </div>
    </Layouts.app>
    """
  end

  defp heading("", nil, _listings), do: gettext("Newest listings")

  defp heading("", category, []), do: gettext("Nothing in %{category} yet", category: category)

  defp heading("", category, _listings), do: gettext("Newest in %{category}", category: category)

  defp heading(query, _category, []), do: gettext("No results for “%{query}”", query: query)

  defp heading(query, _category, listings) do
    ngettext(
      "%{count} result for “%{query}”",
      "%{count} results for “%{query}”",
      length(listings),
      query: query
    )
  end

  defp subtitle("", nil, _listings), do: gettext("Everything just listed, freshest first.")

  defp subtitle("", category, []),
    do: gettext("Nothing is listed in %{category} yet.", category: category)

  defp subtitle("", category, _listings),
    do: gettext("Everything in %{category}, freshest first.", category: category)

  defp subtitle(_query, nil, []), do: gettext("Nothing on offer matches that search.")

  defp subtitle(_query, category, []),
    do: gettext("Nothing in %{category} matches that search.", category: category)

  defp subtitle(_query, nil, _listings), do: gettext("Newest first.")

  defp subtitle(_query, category, _listings),
    do: gettext("Newest first in %{category}.", category: category)

  defp no_results_headline("", category),
    do: gettext("Nothing in %{category} yet", category: category)

  defp no_results_headline(query, _category),
    do: gettext("No results for “%{query}”", query: query)

  defp no_results_description(""),
    do:
      gettext("No one has listed anything here so far. Another category may have what you want.")

  defp no_results_description(_query),
    do:
      gettext(
        "Nothing on offer matches that. A shorter or more general term usually turns something up."
      )

  defp cover_url(%{images: images}) when is_list(images) do
    case Enum.find(images, & &1.is_cover) do
      nil -> nil
      cover -> cover.url
    end
  end

  defp cover_url(_listing), do: nil

  defp seller_handle(%{seller: %{handle: handle}}) when is_binary(handle), do: "@" <> handle
  defp seller_handle(_listing), do: nil

  # Relative rather than dated, unlike the seller's own profile. A grid ordered
  # by recency is making a claim about freshness, and "3 days ago" is what
  # checks that claim — "August 2026" leaves the reader doing the arithmetic.
  # Coarse above a week, where the exact day stops being the point.
  defp listed_ago(%{published_at: published_at, updated_at: updated_at}) do
    since(published_at || updated_at)
  end

  defp since(nil), do: gettext("listed at some point")

  defp since(at) do
    hours = DateTime.diff(DateTime.utc_now(), at, :hour)
    days = div(hours, 24)

    cond do
      hours < 1 -> gettext("listed just now")
      hours < 24 -> ngettext("listed %{count} hour ago", "listed %{count} hours ago", hours)
      days == 1 -> gettext("listed yesterday")
      days < 7 -> ngettext("listed %{count} day ago", "listed %{count} days ago", days)
      true -> gettext("listed in %{month}", month: Calendar.strftime(at, "%B %Y"))
    end
  end
end
