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

  The term and the scope live in the query string rather than in assigns alone,
  so a search can be linked, shared and reloaded, and so the header's box —
  which is drawn on every page and submits here — has somewhere to send it. The
  bar below the heading writes to the same query string, which is why picking a
  category there is a link rather than an event.

  Price and sort are drawn but not yet wired: `browse_listings!` takes neither,
  and giving it them is a change to the read action rather than to this page.
  They are here so the bar is the shape it will keep, not so they work today.

  Paging the grid is not here yet either.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.FilterBar
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingGrid
  import MercatoWeb.UI.Sheet

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

  def handle_event("drop_query", _params, socket) do
    {:noreply, push_patch(socket, to: browse_path(category: socket.assigns.category))}
  end

  def handle_event("drop_category", _params, socket) do
    {:noreply, push_patch(socket, to: browse_path(q: socket.assigns.query))}
  end

  # Built rather than interpolated, so a facet that is unset leaves no empty
  # parameter behind and the whole shelf is plainly `/`.
  defp browse_path(params) do
    case Enum.reject(params, fn {_key, value} -> value in [nil, ""] end) do
      [] -> ~p"/"
      kept -> ~p"/?#{kept}"
    end
  end

  # A clause per option rather than a lookup table: a label built at compile
  # time is invisible to translation extraction.
  defp sort_options do
    [
      {"newest", gettext("Newest")},
      {"price_asc", gettext("Price: low to high")},
      {"price_desc", gettext("Price: high to low")}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
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

        <%!-- Left out when the marketplace itself is empty: there is nothing to
              narrow, and a bar of filters over an empty shelf reads as though
              the filters are what emptied it. --%>
        <.filter_bar
          :if={@listings != [] or @query != "" or not is_nil(@category)}
          id="browse-filters"
        >
          <%!-- md:contents, so the pill joins the bar's flex row directly and the
                wrapper hiding it below md leaves no gap behind. --%>
          <div class="hidden md:contents">
            <.filter_menu
              id="browse-category"
              label={@category_name || gettext("Category")}
              name={gettext("Category")}
              active={not is_nil(@category)}
              class="w-64 max-h-72 overflow-y-auto"
            >
              <.category_choices query={@query} category={@category} categories={@search_categories} />
            </.filter_menu>

            <.filter_menu
              id="browse-price"
              label={gettext("Price")}
              name={gettext("Price range")}
              role="dialog"
              class="w-72 gap-3 p-3.5"
            >
              <.price_fields prefix="browse-price" />
            </.filter_menu>
          </div>

          <.filter_menu
            id="browse-sort"
            label={sort_label()}
            name={gettext("Sort")}
            class="w-60"
          >
            <.sort_choices prefix="browse-sort" />
          </.filter_menu>

          <div class="flex-1"></div>

          <.filter_button
            id="browse-all-filters"
            label={gettext("All filters")}
            icon="hero-adjustments-horizontal"
            aria-haspopup="dialog"
            aria-controls="browse-filters-sheet"
            phx-click={show_sheet("browse-filters-sheet")}
          />

          <:chips :if={@query != "" or not is_nil(@category)}>
            <.filter_chip
              :if={@query != ""}
              id="browse-chip-query"
              label={@query}
              removable
              phx-click="drop_query"
            />
            <.filter_chip
              :if={@category_name}
              id="browse-chip-category"
              label={@category_name}
              removable
              phx-click="drop_category"
            />
            <button
              type="button"
              id="browse-clear-all"
              phx-click="clear_search"
              class={[
                "h-8 px-1.5 text-caption-lg font-bold cursor-pointer underline",
                "text-primary-700 dark:text-primary-100 hover:text-primary-600",
                "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
              ]}
            >
              {gettext("Clear all")}
            </button>
          </:chips>
        </.filter_bar>

        <%!-- Everything the bar holds, plus room for the facets that do not fit
              it — one sheet rather than a second bar below md. --%>
        <.sheet id="browse-filters-sheet" title={gettext("All filters")}>
          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Category")}
            </h3>
            <div class="flex flex-wrap gap-2">
              <.filter_chip
                label={gettext("All categories")}
                selected={is_nil(@category)}
                patch={browse_path(q: @query)}
              />
              <.filter_chip
                :for={category <- @search_categories}
                label={category.name}
                selected={category.slug == @category}
                patch={browse_path(q: @query, category: category.slug)}
              />
            </div>
          </section>

          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Price")}
            </h3>
            <.price_fields prefix="browse-sheet-price" />
          </section>

          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Sort")}
            </h3>
            <.sort_choices prefix="browse-sheet-sort" />
          </section>

          <:footer>
            <.button size="md" variant="neutral" phx-click="clear_search">
              {gettext("Clear")}
            </.button>
            <div class="flex-1"></div>
            <.button size="md" phx-click={hide_sheet("browse-filters-sheet")}>
              {gettext("Show results")}
            </.button>
          </:footer>
        </.sheet>

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
            <.button :if={@current_scope.user} size="md" navigate={~p"/listings/new"}>
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

  # The bar and the sheet offer the same facets, so each is written once and
  # rendered in both. They live here rather than in components/ui/ because only
  # this page has these facets to offer.
  attr :query, :string, required: true
  attr :category, :string, default: nil
  attr :categories, :list, required: true

  defp category_choices(assigns) do
    ~H"""
    <.filter_option
      id="browse-category-any"
      label={gettext("All categories")}
      selected={is_nil(@category)}
      patch={browse_path(q: @query)}
    />
    <.filter_option
      :for={category <- @categories}
      id={"browse-category-#{category.slug}"}
      label={category.name}
      selected={category.slug == @category}
      patch={browse_path(q: @query, category: category.slug)}
    />
    """
  end

  # Drawn, not wired: the read action takes no order yet, so every option but
  # the one in force reports the choice and changes nothing.
  attr :prefix, :string, required: true, doc: "the bar and the sheet both draw these"

  defp sort_choices(assigns) do
    assigns = assign(assigns, :options, sort_options())

    ~H"""
    <.filter_option
      :for={{key, label} <- @options}
      id={"#{@prefix}-#{key}"}
      label={label}
      selected={key == "newest"}
    />
    """
  end

  # Drawn, not wired, for the same reason as the sort options.
  attr :prefix, :string, required: true

  defp price_fields(assigns) do
    ~H"""
    <div class="flex items-end gap-2.5">
      <.input
        type="number"
        id={"#{@prefix}-min"}
        name="price_min"
        value=""
        label={gettext("Min")}
        min="0"
      />
      <.input
        type="number"
        id={"#{@prefix}-max"}
        name="price_max"
        value=""
        label={gettext("Max")}
        min="0"
      />
    </div>
    """
  end

  defp sort_label, do: sort_options() |> hd() |> elem(1)

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
