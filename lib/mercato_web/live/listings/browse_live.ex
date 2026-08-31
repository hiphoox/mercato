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

  Condition is offered only where the marketplace configures conditions at
  all, so an instance selling services or digital goods never draws a facet
  with nothing in it.

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
  import MercatoWeb.UI.FilterBar
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingGrid
  import MercatoWeb.UI.Pager
  import MercatoWeb.UI.Sheet

  alias Mercato.Listings
  alias Mercato.Listings.Listing.SortOrder
  alias Mercato.Money

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  # Divides evenly by every column count the grid actually resolves to, so the
  # last row of a full page is never left short by one tile.
  @per_page 24

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conditions, Listings.conditions())
     |> assign(:per_page, @per_page)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = scope(params, socket.assigns.search_categories)

    socket =
      socket
      |> assign(:query, params |> Map.get("q", "") |> to_string() |> String.trim())
      |> assign(:category, category && category.slug)
      |> assign(:category_name, category && category.name)
      |> assign(:sort, order(params))
      |> assign(:price_min, price(params, "price_min"))
      |> assign(:price_max, price(params, "price_max"))
      |> assign(:condition, condition(params))

    socket =
      socket
      |> assign(:facets, facets(socket))
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

  defp scope(params, categories) do
    slug = params |> Map.get("category", "") |> to_string() |> String.trim()

    Enum.find(categories, &(&1.slug == slug))
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

  # Read as a person types it, in major units, and held in the minor units the
  # resource compares against. A bound that cannot be read is no bound at all,
  # the same forgiveness a hand-typed order or category gets.
  defp price(params, key) do
    case params |> Map.get(key, "") |> to_string() |> String.trim() do
      "" -> nil
      typed -> typed |> Money.to_minor() |> readable()
    end
  end

  defp readable({:ok, amount}), do: amount
  defp readable(:error), do: nil

  # Checked against what this marketplace actually configures, so an instance
  # offering no conditions cannot be filtered by one asked for by hand either.
  defp condition(params) do
    named = params |> Map.get("condition", "") |> to_string()

    Enum.find(Listings.conditions(), &(&1 == named))
  end

  # Every facet in force in one list, so a control that changes one names only
  # that one and the rest survive the patch rather than being dropped by
  # whichever handler forgot them.
  defp facets(%{assigns: assigns}) do
    [
      q: assigns.query,
      category: assigns.category,
      condition: assigns.condition,
      price_min: assigns.price_min,
      price_max: assigns.price_max,
      sort: assigns.sort
    ]
  end

  # The order is deliberately not counted: it is not a filter, so it neither
  # summons the bar nor keeps the "nothing listed" state off the page.
  defp narrowed?(%{assigns: assigns}) do
    Enum.any?([assigns.category, assigns.condition, assigns.price_min, assigns.price_max]) or
      assigns.query != ""
  end

  # A price or a condition narrows the shelf without appearing in the heading
  # the way a term or a category does, so the copy above the grid has to stop
  # claiming to be everything on offer.
  defp filtered?(%{assigns: assigns}) do
    Enum.any?([assigns.condition, assigns.price_min, assigns.price_max])
  end

  defp listings(%{assigns: assigns}, page) do
    Listings.browse_listings!(
      %{
        query: assigns.query,
        category_slug: assigns.category || "",
        condition: assigns.condition || "",
        price_min: assigns.price_min,
        price_max: assigns.price_max,
        sort: assigns.sort
      },
      page: [limit: @per_page, offset: (page - 1) * @per_page, count: true]
    )
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, push_patch(socket, to: browse_path(sort: socket.assigns.sort))}
  end

  def handle_event("drop_query", _params, socket), do: narrow(socket, q: nil)

  def handle_event("drop_category", _params, socket), do: narrow(socket, category: nil)

  def handle_event("drop_condition", _params, socket), do: narrow(socket, condition: nil)

  def handle_event("drop_price", _params, socket),
    do: narrow(socket, price_min: nil, price_max: nil)

  def handle_event("apply_price", params, socket) do
    narrow(socket, price_min: price(params, "price_min"), price_max: price(params, "price_max"))
  end

  defp narrow(socket, changed) do
    {:noreply, push_patch(socket, to: browse_path(Keyword.merge(socket.assigns.facets, changed)))}
  end

  # Built rather than interpolated, so a facet that is unset leaves no empty
  # parameter behind and the whole shelf is plainly `/`.
  defp browse_path(opts) do
    params = [
      q: opts[:q],
      category: opts[:category],
      condition: opts[:condition],
      price_min: Money.amount(opts[:price_min]),
      price_max: Money.amount(opts[:price_max]),
      sort: sort_param(opts[:sort]),
      page: page_param(opts[:page])
    ]

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
      category={@category}
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
              <.category_choices facets={@facets} categories={@search_categories} />
            </.filter_menu>

            <.filter_menu
              id="browse-price"
              label={gettext("Price")}
              name={gettext("Price range")}
              role="dialog"
              class="w-72 gap-3 p-3.5"
            >
              <.price_fields prefix="browse-price" min={@price_min} max={@price_max} />
            </.filter_menu>
          </div>

          <.filter_menu
            id="browse-sort"
            label={sort_label(@sort)}
            name={gettext("Sort")}
            class="w-60"
          >
            <.sort_choices prefix="browse-sort" facets={@facets} />
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
            <.filter_chip
              :if={@category_name}
              id="browse-chip-category"
              label={@category_name}
              removable
              phx-click="drop_category"
            />
            <.filter_chip
              :if={@condition}
              id="browse-chip-condition"
              label={Listings.condition_label(@condition)}
              removable
              phx-click="drop_condition"
            />
            <.filter_chip
              :if={@price_min || @price_max}
              id="browse-chip-price"
              label={price_label(@price_min, @price_max)}
              removable
              phx-click="drop_price"
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
                patch={browse_path(Keyword.put(@facets, :category, nil))}
              />
              <.filter_chip
                :for={category <- @search_categories}
                label={category.name}
                selected={category.slug == @category}
                patch={browse_path(Keyword.put(@facets, :category, category.slug))}
              />
            </div>
          </section>

          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Price")}
            </h3>
            <.price_fields prefix="browse-sheet-price" min={@price_min} max={@price_max} />
          </section>

          <%!-- Left out where the marketplace configures no conditions: a
                services or digital-goods instance has none to offer, and a
                facet with nothing in it reads as a page that failed to load. --%>
          <section :if={@conditions != []} class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Condition")}
            </h3>
            <.condition_choices facets={@facets} conditions={@conditions} />
          </section>

          <section class="flex flex-col gap-3">
            <h3 class="text-caption-lg font-bold uppercase tracking-wide text-ink-500">
              {gettext("Sort")}
            </h3>
            <.sort_choices prefix="browse-sheet-sort" facets={@facets} />
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
          path={&browse_path(Keyword.put(@facets, :page, &1))}
          total={@total}
          page_size={@per_page}
          class="pt-2"
        />
      </div>
    </Layouts.app>
    """
  end

  # The bar and the sheet offer the same facets, so each is written once and
  # rendered in both. They live here rather than in components/ui/ because only
  # this page has these facets to offer.
  attr :facets, :list, required: true, doc: "every facet in force, so a pick changes only its own"
  attr :categories, :list, required: true

  defp category_choices(assigns) do
    ~H"""
    <.filter_option
      id="browse-category-any"
      label={gettext("All categories")}
      selected={is_nil(@facets[:category])}
      patch={browse_path(Keyword.put(@facets, :category, nil))}
    />
    <.filter_option
      :for={category <- @categories}
      id={"browse-category-#{category.slug}"}
      label={category.name}
      selected={category.slug == @facets[:category]}
      patch={browse_path(Keyword.put(@facets, :category, category.slug))}
    />
    """
  end

  attr :facets, :list, required: true
  attr :conditions, :list, required: true

  defp condition_choices(assigns) do
    ~H"""
    <.filter_option
      id="browse-condition-any"
      label={gettext("Any condition")}
      selected={is_nil(@facets[:condition])}
      patch={browse_path(Keyword.put(@facets, :condition, nil))}
    />
    <%!-- Worded by the domain, not here: the list is what the operator
          configured, so it is data rather than copy to translate. --%>
    <.filter_option
      :for={condition <- @conditions}
      id={"browse-condition-#{condition}"}
      label={Listings.condition_label(condition)}
      selected={condition == @facets[:condition]}
      patch={browse_path(Keyword.put(@facets, :condition, condition))}
    />
    """
  end

  attr :prefix, :string, required: true, doc: "the bar and the sheet both draw these"
  attr :facets, :list, required: true

  defp sort_choices(assigns) do
    assigns = assign(assigns, :options, sort_options())

    ~H"""
    <.filter_option
      :for={{order, label} <- @options}
      id={"#{@prefix}-#{order}"}
      label={label}
      selected={order == @facets[:sort]}
      patch={browse_path(Keyword.put(@facets, :sort, order))}
    />
    """
  end

  # A range is stated by typing rather than by picking, so it is submitted
  # rather than patched on every keystroke: half a range is a bound the buyer
  # has not finished writing, and applying it would empty the grid underneath
  # them mid-word.
  attr :prefix, :string, required: true, doc: "the bar and the sheet both draw these"
  attr :min, :integer, default: nil
  attr :max, :integer, default: nil

  defp price_fields(assigns) do
    ~H"""
    <.form for={%{}} id={"#{@prefix}-form"} phx-submit="apply_price" class="flex flex-col gap-2.5">
      <div class="flex items-end gap-2.5">
        <.input
          type="number"
          id={"#{@prefix}-min"}
          name="price_min"
          value={Money.amount(@min)}
          label={gettext("Min")}
          min="0"
          step="0.01"
        />
        <.input
          type="number"
          id={"#{@prefix}-max"}
          name="price_max"
          value={Money.amount(@max)}
          label={gettext("Max")}
          min="0"
          step="0.01"
        />
      </div>
      <.button type="submit" size="sm">{gettext("Apply")}</.button>
    </.form>
    """
  end

  # Three whole messages rather than one built from a fragment and a bound:
  # which end is open changes the sentence, not just a word inside it.
  defp price_label(min, nil), do: gettext("From %{min}", min: money(min))
  defp price_label(nil, max), do: gettext("Up to %{max}", max: money(max))

  defp price_label(min, max),
    do: gettext("%{min} – %{max}", min: money(min), max: money(max))

  defp money(amount), do: Money.format(amount, Listings.currency())

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
