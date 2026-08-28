defmodule MercatoWeb.Listings.MyListingsLive do
  @moduledoc """
  Everything the signed-in trader has listed, grouped by the state it is in.

  Editing and composing are pages, so those actions are links, and removing
  happens here, as do pausing and relisting. Opening the order behind a sold
  listing waits on there being orders to open.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingStatusBadge

  alias Mercato.Listings

  on_mount {MercatoWeb.LiveUserAuth, :live_user_required}

  @state_values [:draft, :active, :unavailable, :sold]

  @status_strings Map.new(@state_values, &{to_string(&1), &1})

  # Built per render rather than held as a module attribute: wording baked in at
  # compile time is invisible to translation extraction.
  defp states do
    [
      %{
        value: :draft,
        section: gettext("Drafts"),
        help: gettext("Not visible to buyers yet."),
        icon: "hero-pencil-square",
        actions: [%{label: gettext("Continue editing"), variant: "primary", event: "edit"}]
      },
      %{
        value: :active,
        section: gettext("Active"),
        help: gettext("On offer to buyers now."),
        icon: "hero-photo",
        actions: [
          %{label: gettext("Edit"), variant: "neutral", event: "edit"},
          %{label: gettext("Pause"), variant: "neutral", event: "pause"}
        ]
      },
      %{
        value: :unavailable,
        section: gettext("Paused"),
        help: gettext("Hidden from search until you relist."),
        icon: "hero-photo",
        actions: [
          %{label: gettext("Relist"), variant: "primary", event: "resume"},
          %{label: gettext("Edit"), variant: "neutral", event: "edit"}
        ]
      },
      %{
        value: :sold,
        section: gettext("Sold"),
        help: gettext("Kept for your records."),
        icon: "hero-photo",
        actions: [%{label: gettext("View order"), variant: "neutral", event: "view_order"}]
      }
    ]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_listings(socket)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :status, parse_status(params["status"]))}
  end

  # An unrecognised state reads as no filter rather than as an error: a stale
  # or hand-edited URL should still show the trader their listings.
  defp parse_status(value), do: Map.get(@status_strings, to_string(value))

  # Fetched once and grouped in memory rather than queried per state. A trader
  # holds few enough listings that one read is cheaper than five, and the
  # counts on the chips have to describe the same snapshot the sections do.
  defp load_listings(socket) do
    listings = Listings.list_my_listings!(actor: socket.assigns.current_scope.user)
    grouped = Enum.group_by(listings, & &1.status)

    socket
    |> assign(:listings, listings)
    |> assign(:grouped, grouped)
    |> assign(:counts, Map.new(@state_values, &{&1, length(Map.get(grouped, &1, []))}))
  end

  @impl true
  def handle_event("remove", %{"id" => id}, socket) do
    with %{} = listing <- Enum.find(socket.assigns.listings, &(&1.id == id)),
         :ok <- Listings.delete_listing(listing, actor: socket.assigns.current_scope.user) do
      {:noreply,
       socket
       |> load_listings()
       |> put_flash(:info, gettext("“%{title}” was removed.", title: listing.title))}
    else
      # Almost always a listing sold between this page being drawn and the
      # control being pressed: a sale outlives the seller's wish to be rid of it.
      _refused ->
        {:noreply, put_flash(socket, :error, gettext("That listing could not be removed."))}
    end
  end

  def handle_event("pause", %{"id" => id}, socket) do
    moved(
      socket,
      id,
      &Listings.pause_listing/2,
      fn title -> gettext("“%{title}” was paused.", title: title) end,
      gettext("That listing could not be paused.")
    )
  end

  def handle_event("resume", %{"id" => id}, socket) do
    moved(
      socket,
      id,
      &Listings.resume_listing/2,
      fn title -> gettext("“%{title}” is back on offer.", title: title) end,
      gettext("That listing could not go back on offer.")
    )
  end

  def handle_event("filter_status", %{"status" => "all"}, socket) do
    {:noreply, push_patch(socket, to: ~p"/users/me/listings")}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    case parse_status(status) do
      nil -> {:noreply, push_patch(socket, to: ~p"/users/me/listings")}
      status -> {:noreply, push_patch(socket, to: ~p"/users/me/listings?status=#{status}")}
    end
  end

  # Every move a listing makes from this page reads the shelf again afterwards,
  # so the card, the section it sits in and the counts on the chips all describe
  # the same snapshot.
  defp moved(socket, id, move, said, refused) do
    with %{} = listing <- Enum.find(socket.assigns.listings, &(&1.id == id)),
         {:ok, _moved} <- move.(listing, actor: socket.assigns.current_scope.user) do
      {:noreply,
       socket
       |> load_listings()
       |> put_flash(:info, said.(listing.title))}
    else
      _refused -> {:noreply, put_flash(socket, :error, refused)}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:states, states())
      |> assign(:sections, sections(assigns))

    ~H"""
    <Layouts.app
      categories={@search_categories}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/users/me/listings"}
    >
      <div id="my-listings" class="flex flex-col gap-6">
        <.breadcrumb items={[
          %{label: gettext("Home"), navigate: ~p"/"},
          %{label: gettext("Selling")},
          %{label: gettext("My listings")}
        ]} />

        <.header>
          {gettext("My listings")}
          <:subtitle>{subtitle(@listings, @counts)}</:subtitle>
          <:actions>
            <.button id="new-listing" size="md" navigate={~p"/listings/new"}>
              <.icon name="hero-plus" aria-hidden="true" class="size-4.5" /> {gettext("New listing")}
            </.button>
          </:actions>
        </.header>

        <%!-- Chips describe the whole shelf, so they only appear once there is a
              shelf to describe. --%>
        <div
          :if={@listings != []}
          role="group"
          aria-label={gettext("Filter by state")}
          class="flex flex-wrap gap-2"
        >
          <.filter_chip
            id="status-chip-all"
            label={gettext("All (%{count})", count: length(@listings))}
            selected={is_nil(@status)}
            phx-click="filter_status"
            phx-value-status="all"
          />
          <.filter_chip
            :for={state <- @states}
            id={"status-chip-#{state.value}"}
            label={
              gettext("%{section} (%{count})", section: state.section, count: @counts[state.value])
            }
            selected={@status == state.value}
            phx-click="filter_status"
            phx-value-status={state.value}
          />
        </div>

        <section
          :for={state <- @sections}
          id={"section-#{state.value}"}
          aria-labelledby={"section-#{state.value}-heading"}
          class="flex flex-col gap-3.5"
        >
          <div class="flex items-baseline gap-2.5 flex-wrap">
            <h2
              id={"section-#{state.value}-heading"}
              class="text-title-lg font-bold text-ink-900 dark:text-white"
            >
              {state.section}
            </h2>
            <span class="text-body-sm font-semibold text-ink-500">
              {listing_count(@counts[state.value])}
            </span>
            <span class="text-body-sm text-ink-500">{state.help}</span>
          </div>

          <%!-- One column below md, where each card is a row, and a filling grid
                from md up, where each card is a tile. --%>
          <div class="grid grid-cols-1 gap-3 md:grid-cols-[repeat(auto-fill,minmax(15.5rem,1fr))] md:gap-4">
            <.listing_card
              :for={listing <- @grouped[state.value]}
              id={"listing-#{listing.id}"}
              title={listing.title}
              price={listing.display_price}
              navigate={~p"/listings/#{listing}"}
              image_src={cover_url(listing)}
              image_alt={gettext("Cover photo of %{title}", title: listing.title)}
              placeholder_icon={state.icon}
              dimmed={state.value == :sold}
            >
              <:badges>
                <.listing_status_badge status={listing.status} />
                <.badge :if={listing.condition} kind="neutral">
                  {Listings.condition_label(listing.condition)}
                </.badge>
              </:badges>
              <:meta>{meta(listing, state)}</:meta>
              <:actions>
                <.button
                  :for={action <- state.actions}
                  id={"#{action.event}-#{listing.id}"}
                  size="sm"
                  variant={action.variant}
                  navigate={action_target(action, listing)}
                  phx-click={action_event(action)}
                  phx-value-id={listing.id}
                >
                  {action.label}
                </.button>

                <%!-- A sold listing is the record of a sale, so it has no remove
                      control at all — the resource refuses the destroy too. --%>
                <button
                  :if={state.value != :sold}
                  type="button"
                  id={"remove-#{listing.id}"}
                  phx-click="remove"
                  phx-value-id={listing.id}
                  aria-label={gettext("Remove %{title}", title: listing.title)}
                  data-confirm={
                    gettext(
                      "“%{title}” will be taken off Mercato. This cannot be undone.",
                      title: listing.title
                    )
                  }
                  class={[
                    "ml-auto flex-none flex items-center justify-center size-9 cursor-pointer",
                    "rounded-md border border-ink-100 dark:border-ink-700 text-ink-500",
                    "transition-colors hover:bg-error-bg hover:text-error-text hover:border-error-bg",
                    "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
                  ]}
                >
                  <.icon name="hero-trash" aria-hidden="true" class="size-4" />
                </button>
              </:actions>
            </.listing_card>
          </div>
        </section>

        <.empty_state
          :if={@listings != [] and @sections == []}
          id="no-matching-listings"
          icon="hero-archive-box"
          headline={gettext("Nothing in %{section} right now.", section: section_label(@status))}
          description={gettext("Every listing you have is in another state.")}
        >
          <:actions>
            <.button
              size="sm"
              variant="neutral"
              phx-click="filter_status"
              phx-value-status="all"
            >
              {gettext("Show all listings")}
            </.button>
          </:actions>
        </.empty_state>

        <div :if={@listings == []} class="flex flex-col gap-4">
          <.empty_state
            id="no-listings"
            icon="hero-square-3-stack-3d"
            headline={gettext("Your first listing starts here")}
            description={gettext("Photos, a price, and a short description are all it takes.")}
          />

          <div class="grid grid-cols-1 gap-3 md:grid-cols-3">
            <div
              :for={step <- steps()}
              class="flex items-start gap-3 p-4 rounded-md border border-ink-100 dark:border-ink-700"
            >
              <.icon
                name={step.icon}
                aria-hidden="true"
                class="size-5 flex-none text-primary-600"
              />
              <div class="min-w-0">
                <div class="text-body-sm font-bold text-ink-900 dark:text-white">{step.title}</div>
                <div class="mt-0.5 text-caption-lg text-ink-500 text-pretty">{step.body}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # The states with something in them, narrowed to the chosen one when there is
  # a filter. An empty result is what the "nothing here" state keys off.
  defp sections(%{status: status, counts: counts}) do
    Enum.filter(states(), fn state ->
      counts[state.value] > 0 and (is_nil(status) or state.value == status)
    end)
  end

  # Editing is a page rather than an event, so its control is a link. Every
  # other action changes the listing where it stands.
  defp action_target(%{event: "edit"}, listing), do: ~p"/listings/#{listing.id}/edit"
  defp action_target(_action, _listing), do: nil

  # A link carries no event, and there is nothing yet to open behind a sale.
  defp action_event(%{event: "edit"}), do: nil
  defp action_event(%{event: "view_order"}), do: nil
  defp action_event(%{event: event}), do: event

  defp section_label(status) do
    case Enum.find(states(), &(&1.value == status)) do
      nil -> gettext("that state")
      state -> String.downcase(state.section)
    end
  end

  defp subtitle([], _counts), do: gettext("Everything you sell on Mercato lives here.")

  defp subtitle(listings, counts) do
    gettext(
      "%{listings} · %{active} on offer · %{drafts} unfinished",
      listings: listing_count(length(listings)),
      active: counts.active,
      drafts: counts.draft
    )
  end

  # A count and its noun are one string, so a language that inflects the noun
  # with the number can say so.
  defp listing_count(count) do
    ngettext("1 listing", "%{count} listings", count)
  end

  defp photo_count(count) do
    ngettext("1 photo", "%{count} photos", count)
  end

  defp cover_url(%{images: images}) when is_list(images) do
    case Enum.find(images, & &1.is_cover) do
      nil -> nil
      cover -> cover.url
    end
  end

  defp cover_url(_listing), do: nil

  # Built from stamps the listing actually carries. View and offer counts belong
  # here too, and land with the features that produce them.
  defp meta(listing, %{value: :draft}) do
    photos =
      case length(listing.images) do
        0 -> gettext("needs a photo")
        count -> photo_count(count)
      end

    gettext("Saved %{when} · %{photos}", when: relative_time(listing.updated_at), photos: photos)
  end

  defp meta(listing, %{value: :active}) do
    gettext("Listed %{when}", when: relative_time(listing.published_at || listing.updated_at))
  end

  defp meta(listing, %{value: :unavailable}) do
    gettext("Paused %{when}", when: relative_time(listing.updated_at))
  end

  defp meta(listing, %{value: :sold}) do
    gettext("Sold %{when}", when: relative_time(listing.updated_at))
  end

  # Coarse on purpose: the trader wants to know whether a listing is fresh or
  # stale, not the minute it changed. Past a week the date says more than a
  # growing number of days would.
  defp relative_time(nil), do: gettext("at some point")

  defp relative_time(at) do
    case DateTime.diff(DateTime.utc_now(), at, :second) do
      seconds when seconds < 60 ->
        gettext("just now")

      seconds when seconds < 3_600 ->
        ngettext("1 minute ago", "%{count} minutes ago", div(seconds, 60))

      seconds when seconds < 86_400 ->
        ngettext("1 hour ago", "%{count} hours ago", div(seconds, 3_600))

      seconds when seconds < 172_800 ->
        gettext("yesterday")

      seconds when seconds < 604_800 ->
        ngettext("1 day ago", "%{count} days ago", div(seconds, 86_400))

      _ ->
        gettext("on %{date}", date: Calendar.strftime(at, "%-d %b %Y"))
    end
  end

  defp steps do
    [
      %{
        icon: "hero-camera",
        title: gettext("Photograph it"),
        body: gettext("Daylight, plain background, four or five angles.")
      },
      %{
        icon: "hero-tag",
        title: gettext("Set a price"),
        body: gettext("Buyers compare, so price it against what similar items went for.")
      },
      %{
        icon: "hero-paper-airplane",
        title: gettext("Publish"),
        body: gettext("Buyers see it straight away and can make offers.")
      }
    ]
  end
end
