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

  The order is a third such parameter, and the heading says nothing about it:
  the pill on the bar states the order in force, so restating it above the grid
  would be one claim in two places, and the wrong one half the time. An order is
  not a filter either, which is why clearing the filters leaves it alone.

  Which facets the bar offers is declared rather than written out here, so a
  marketplace narrows its grid by what its own catalog has. This page reads the
  declarations, states them in the query string, and draws a control per facet;
  it knows that a facet exists and what kind it is, never that it happens to be
  a condition. A facet with nothing to offer — a condition list an instance
  selling services left empty — draws nothing rather than an empty panel.

  The page is a fourth query-string parameter, and numbered rather than
  scrolled for the same reason the rest of them are there: a shelf reached by
  scrolling cannot be linked, shared, or returned to. It is not a facet
  though — it says where you are in a result set rather than what the set is —
  so changing any facet drops it and starts again at the first page, which is
  what every control here does for free by building its link from the facets.

  How many fit a page is decided here rather than by the resource: it follows
  from how many tiles fill a grid, which is a question about this page and not
  about a listing.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.AddToCart
  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.FacetControls
  import MercatoWeb.UI.FilterBar
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingGrid
  import MercatoWeb.UI.Pager
  import MercatoWeb.UI.Sheet

  alias Mercato.Discovery
  alias Mercato.Listings
  alias Mercato.Listings.Listing.SortOrder

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  # Divides evenly by every column count the grid actually resolves to, so the
  # last row of a full page is never left short by one tile.
  @per_page 24

  @impl true
  def mount(_params, _session, socket) do
    facets = Discovery.facets()

    # Read once here rather than per render: a facet's options come from the
    # catalog or from configuration, and neither changes while the grid is
    # being narrowed.
    {:ok,
     socket
     |> assign(:facets, facets)
     |> assign(:facet_options, options(facets))
     |> assign(:per_page, @per_page)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:query, params |> Map.get("q", "") |> to_string() |> String.trim())
      |> assign(:filters, Discovery.from_params(params, socket.assigns.facet_options))
      |> assign(:sort, order(params))

    socket =
      socket
      |> assign(:category_name, category_name(socket))
      |> assign(:narrowed?, narrowed?(socket))
      |> assign(:filtered?, filtered?(socket))

    {:noreply, paged(socket, page(params))}
  end

  # A page beyond the end is a stale link rather than an error, the same
  # forgiveness a hand-typed order or category gets — but it takes the read to
  # know where the end is, so it is asked for and then landed back on the first
  # page, rather than guessed at beforehand.
  defp paged(socket, wanted) do
    {page, number} = at(socket, wanted)

    socket
    |> assign(:listings, page.results)
    |> assign(:total, page.count)
    |> assign(:page, number)
    |> assign(:pages, ceil(page.count / @per_page))
  end

  defp at(socket, wanted) do
    case listings(socket, wanted) do
      %{results: [], count: count} when count > 0 and wanted > 1 -> {listings(socket, 1), 1}
      page -> {page, wanted}
    end
  end

  # An order nobody offers is read as no order at all, the same way an unknown
  # category is: a stale or hand-typed link lands on the grid rather than on an
  # error.
  defp order(params) do
    named = params |> Map.get("sort", "") |> to_string()

    Enum.find(SortOrder.values(), :newest, &(to_string(&1) == named))
  end

  # A number that is not one, or one below the first page, is read as no page
  # asked for. Where it lands past the last page is settled after the read, in
  # `at/2`, since nothing here knows yet how long the shelf is.
  defp page(params) do
    case params |> Map.get("page", "") |> to_string() |> Integer.parse() do
      {number, ""} when number > 0 -> number
      _unreadable -> 1
    end
  end

  # The heading names the category the way it names the term, so the one facet
  # the copy speaks about is worded here. Every other facet is named by its
  # chip instead.
  defp category_name(%{assigns: assigns}) do
    stated = assigns.filters[:category]

    case Enum.find(assigns.facet_options[:category] || [], fn {slug, _name} -> slug == stated end) do
      {_slug, name} -> name
      nil -> nil
    end
  end

  # The order is deliberately not counted: it is not a filter, so it neither
  # summons the bar nor keeps the "nothing listed" state off the page.
  defp narrowed?(%{assigns: assigns}) do
    assigns.query != "" or in_force(assigns) != []
  end

  # A facet that narrows the shelf without appearing in the heading the way a
  # term or a category does makes the copy above the grid stop claiming to be
  # everything on offer.
  defp filtered?(%{assigns: assigns}) do
    Enum.any?(in_force(assigns), &(&1.key != :category))
  end

  defp in_force(assigns) do
    Enum.filter(assigns.facets, &Discovery.in_force?(&1, assigns.filters))
  end

  defp listings(%{assigns: assigns}, page) do
    Listings.browse_listings!(
      %{query: assigns.query, filters: assigns.filters, sort: assigns.sort},
      page: [limit: @per_page, offset: (page - 1) * @per_page, count: true]
    )
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: address(socket, filters: %{}, q: nil))}
  end

  def handle_event("drop_query", _params, socket) do
    {:noreply, push_patch(socket, to: address(socket, q: nil))}
  end

  # One handler for every facet, named by the chip that was clicked: a facet
  # added to the declarations is droppable without a handler of its own.
  def handle_event("drop_facet", %{"facet" => key}, socket) do
    {:noreply, push_patch(socket, to: address(socket, filters: dropped(socket, key)))}
  end

  # A range arrives as the address states it, so what a buyer typed is read by
  # the same code that reads a link. Its facet's own values are cleared first,
  # so emptying both ends removes the narrowing rather than leaving the old one
  # standing.
  def handle_event("apply_facet", %{"facet" => key} = params, socket) do
    stated =
      Map.merge(dropped(socket, key), Discovery.from_params(params, socket.assigns.facet_options))

    {:noreply, push_patch(socket, to: address(socket, filters: stated))}
  end

  defp dropped(socket, key) do
    Enum.reduce(socket.assigns.facets, socket.assigns.filters, fn facet, filters ->
      if to_string(facet.key) == key, do: Map.delete(filters, facet.key), else: filters
    end)
  end

  # Every parameter in force, with only what the caller names changed, so a
  # control that changes one facet leaves the term, the order and the other
  # facets standing rather than dropping whatever it forgot.
  defp address(socket, changed) do
    changed
    |> Keyword.put_new(:q, socket.assigns.query)
    |> Keyword.put_new(:filters, socket.assigns.filters)
    |> Keyword.put_new(:sort, socket.assigns.sort)
    |> browse_path()
  end

  # Built rather than interpolated, so a facet that is unset leaves no empty
  # parameter behind and the whole shelf is plainly `/`.
  defp browse_path(opts) do
    params =
      [q: opts[:q]] ++
        Discovery.to_params(opts[:filters] || %{}) ++
        [sort: sort_param(opts[:sort]), page: page_param(opts[:page])]

    case Enum.reject(params, fn {_key, value} -> value in [nil, ""] end) do
      [] -> ~p"/"
      kept -> ~p"/?#{kept}"
    end
  end

  # The default order is the absence of the parameter, so the plain shelf has
  # one address rather than two that render the same page.
  defp sort_param(order) when order in [nil, :newest], do: nil
  defp sort_param(order), do: to_string(order)

  # The first page is the absence of the parameter, for the same reason the
  # default order is: the plain shelf keeps one address, and the page is left
  # out of the facets so that changing any of them lands back here.
  defp page_param(number) when number in [nil, 1], do: nil
  defp page_param(number), do: to_string(number)

  # Derived from the type, so an order added to the resource reaches the bar
  # without being listed a second time here. The labels stay clauses rather
  # than a lookup table: one built at compile time is invisible to extraction.
  defp sort_options, do: Enum.map(SortOrder.values(), &{&1, sort_label(&1)})

  defp sort_label(:newest), do: gettext("Newest")
  defp sort_label(:price_asc), do: gettext("Price: low to high")
  defp sort_label(:price_desc), do: gettext("Price: high to low")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/"}
      query={@query}
      categories={@search_categories}
      category={@filters[:category]}
    >
      <%!-- No breadcrumb: this is where the trail every other page draws
            starts, and a crumb pointing at the page you are on is noise. --%>
      <div id="browse" class="flex flex-col gap-6">
        <.header>
          {heading(@query, @category_name, @total, @filtered?)}
          <:subtitle>{subtitle(@query, @category_name, @total, @filtered?)}</:subtitle>
        </.header>

        <%!-- Left out when the marketplace itself is empty: there is nothing to
              narrow, and a bar of filters over an empty shelf reads as though
              the filters are what emptied it. --%>
        <.filter_bar :if={@listings != [] or @narrowed?} id="browse-filters">
          <%!-- md:contents, so the pills join the bar's flex row directly and the
                wrapper hiding them below md leaves no gap behind. Only the
                facets that asked for the bar are drawn; the rest wait in the
                sheet, which holds every one of them. --%>
          <div class="hidden md:contents">
            <.facet_menu
              :for={facet <- @facets}
              :if={facet.placement == :bar}
              facet={facet}
              filters={@filters}
              options={@facet_options}
              path={&browse_path(q: @query, filters: &1, sort: @sort)}
            />
          </div>

          <.filter_menu
            id="browse-sort"
            label={sort_label(@sort)}
            name={gettext("Sort")}
            class="w-60"
          >
            <.sort_choices prefix="browse-sort" query={@query} filters={@filters} sort={@sort} />
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

          <:chips :if={@narrowed?}>
            <.filter_chip
              :if={@query != ""}
              id="browse-chip-query"
              label={@query}
              removable
              phx-click="drop_query"
            />
            <.facet_chip
              :for={facet <- @facets}
              facet={facet}
              filters={@filters}
              options={@facet_options}
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
          <%!-- Every declared facet, including the ones the bar had no room
                for, so the same narrowing is reachable at every width. A facet
                with nothing to offer draws nothing. --%>
          <.facet_section
            :for={facet <- @facets}
            facet={facet}
            filters={@filters}
            options={@facet_options}
            path={&browse_path(q: @query, filters: &1, sort: @sort)}
          />

          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Sort")}
            </h3>
            <.sort_choices prefix="browse-sheet-sort" query={@query} filters={@filters} sort={@sort} />
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
          :if={@listings == [] and not @narrowed?}
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
          :if={@listings == [] and @narrowed?}
          id="no-results"
          icon="hero-magnifying-glass"
          headline={no_results_headline(@query, @category_name)}
          description={no_results_description(@query, @category_name)}
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
            <%!-- On the slot rather than on the badge, so a listing whose seller
                  stated no condition leaves no empty row above the price. --%>
            <:badges :if={listing.condition}>
              <.badge kind="neutral">{Listings.condition_label(listing.condition)}</.badge>
            </:badges>
            <:meta>{seller_handle(listing)} · {listed_ago(listing)}</:meta>
            <:corner>
              <.add_to_cart id={"add-to-cart-#{listing.id}"} />
            </:corner>
          </.listing_card>
        </.listing_grid>

        <%!-- Built from the facets rather than from the address, so a page
              link carries the term, the scope and the order in force without
              this page having to parse back what it just wrote. --%>
        <.pager
          page={@page}
          pages={@pages}
          path={&browse_path(q: @query, filters: @filters, sort: @sort, page: &1)}
          total={@total}
          page_size={@per_page}
          class="pt-2"
        />
      </div>
    </Layouts.app>
    """
  end

  # An order is offered by this page rather than declared as a facet, since it
  # states how the shelf is read rather than what is on it.
  attr :prefix, :string, required: true, doc: "the bar and the sheet both draw these"
  attr :query, :string, required: true
  attr :filters, :map, required: true
  attr :sort, :atom, required: true

  defp sort_choices(assigns) do
    assigns = assign(assigns, :options, sort_options())

    ~H"""
    <.filter_option
      :for={{order, label} <- @options}
      id={"#{@prefix}-#{order}"}
      label={label}
      selected={order == @sort}
      patch={browse_path(q: @query, filters: @filters, sort: order)}
    />
    """
  end

  # A filtered shelf is counted rather than described: the facets in force are
  # already named by the chips, and a count is the one claim that stays true
  # whichever of them is doing the narrowing.
  defp heading("", _category, 0, true), do: gettext("Nothing matches those filters")

  defp heading("", _category, total, true) do
    ngettext("%{count} listing matches", "%{count} listings match", total)
  end

  defp heading("", nil, _total, _filtered?), do: gettext("Everything on offer")

  defp heading("", category, 0, _filtered?),
    do: gettext("Nothing in %{category} yet", category: category)

  defp heading("", category, _total, _filtered?),
    do: gettext("Everything in %{category}", category: category)

  defp heading(query, _category, 0, _filtered?),
    do: gettext("No results for “%{query}”", query: query)

  defp heading(query, _category, total, _filtered?) do
    ngettext(
      "%{count} result for “%{query}”",
      "%{count} results for “%{query}”",
      total,
      query: query
    )
  end

  defp subtitle("", _category, 0, true),
    do: gettext("Nothing on offer matches those filters.")

  defp subtitle("", nil, _total, true), do: gettext("Everything on offer that matches.")

  defp subtitle("", category, _total, true),
    do: gettext("Everything in %{category} that matches.", category: category)

  defp subtitle("", nil, _total, _filtered?),
    do: gettext("Every listing on offer, from every seller.")

  defp subtitle("", category, 0, _filtered?),
    do: gettext("Nothing is listed in %{category} yet.", category: category)

  defp subtitle("", category, _total, _filtered?),
    do: gettext("Every listing in %{category}, from every seller.", category: category)

  defp subtitle(_query, nil, 0, _filtered?), do: gettext("Nothing on offer matches that search.")

  defp subtitle(_query, category, 0, _filtered?),
    do: gettext("Nothing in %{category} matches that search.", category: category)

  defp subtitle(_query, nil, _total, _filtered?),
    do: gettext("Everything on offer that matches.")

  defp subtitle(_query, category, _total, _filtered?),
    do: gettext("Everything in %{category} that matches.", category: category)

  defp no_results_headline("", nil), do: gettext("Nothing matches those filters")

  defp no_results_headline("", category),
    do: gettext("Nothing in %{category} yet", category: category)

  defp no_results_headline(query, _category),
    do: gettext("No results for “%{query}”", query: query)

  defp no_results_description("", nil),
    do:
      gettext(
        "Nothing on offer matches those filters. Loosening one of them usually turns something up."
      )

  defp no_results_description("", _category),
    do:
      gettext("No one has listed anything here so far. Another category may have what you want.")

  defp no_results_description(_query, _category),
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
