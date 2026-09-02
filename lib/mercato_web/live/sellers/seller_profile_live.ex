defmodule MercatoWeb.Sellers.SellerProfileLive do
  @moduledoc """
  The page a seller has of their own, as a buyer mid-decision reads it.

  A buyer arrives from a listing's seller card wanting to know who is on the
  other side of the transaction, so the identity band frames the page and the
  listings are what fills it.

  Everyone gets the same page, the seller included: it is a storefront rather
  than an account view, and one that differed for its owner could not be used
  to check what buyers see. Nothing on it is a control over the seller — there
  is no follow, no message, no report — so the only thing to press is a listing.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.AddToCart
  import MercatoWeb.UI.Avatar
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.ListingCard
  import MercatoWeb.UI.ListingGrid
  import MercatoWeb.UI.ListingStatusBadge

  alias Mercato.Accounts
  alias Mercato.Listings

  # Enough history to prove the seller delivers, few enough that it cannot push
  # what is actually for sale off the screen. The rest is a press away.
  @sold_shown 4

  # How recently an account has to have opened to be worth saying so. A buyer
  # finding no sales behind a seller deserves the reason rather than a guess.
  @new_seller_days 30

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}
  on_mount MercatoWeb.Carts.Gathering

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    {:ok,
     socket
     |> assign(:handle, handle)
     |> assign(:sold_expanded?, false)
     |> load_seller(handle)}
  end

  # No actor is passed to either read. The profile is public and shows the same
  # thing to everyone, so who is looking cannot change what comes back.
  defp load_seller(socket, handle) do
    case Accounts.get_seller(handle) do
      {:ok, seller} -> assign(socket, seller: seller, listings: listings(seller))
      {:error, _gone} -> assign(socket, seller: nil, listings: %{active: [], sold: []})
    end
  end

  # One read, grouped in memory: the counts in the band and the cards in the
  # grids have to describe the same snapshot, and a seller holds few enough
  # listings that two queries would cost more than they saved.
  defp listings(seller) do
    seller.id
    |> Listings.list_seller_listings!()
    |> Enum.group_by(& &1.status)
    |> then(&%{active: Map.get(&1, :active, []), sold: Map.get(&1, :sold, [])})
  end

  @impl true
  def handle_event("show_all_sold", _params, socket) do
    {:noreply, assign(socket, :sold_expanded?, true)}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:on_offer, assigns.listings.active)
      |> assign(:sold, assigns.listings.sold)

    ~H"""
    <Layouts.app
      current_scope={@current_scope}
      categories={@search_categories}
      cart_count={@cart_count}
      flash={@flash}
      current_path={~p"/users/#{@handle}"}
    >
      <.seller_gone :if={is_nil(@seller)} />

      <div :if={@seller} id="seller-profile" class="flex flex-col gap-7">
        <.breadcrumb items={[
          %{label: "Home", navigate: ~p"/"},
          %{label: name(@seller)}
        ]} />

        <.identity_band seller={@seller} on_offer={length(@on_offer)} sold={length(@sold)} />

        <.empty_state
          :if={@on_offer == [] and @sold == []}
          id="seller-has-nothing"
          icon="hero-archive-box"
          headline="Nothing listed right now"
          description="This seller has nothing on offer and no sales yet. The profile stays here, and anything they list shows up on this page."
        />

        <section
          :if={@on_offer != [] or @sold != []}
          aria-labelledby="on-offer-heading"
          class="flex flex-col gap-4"
        >
          <.section_heading id="on-offer-heading" count={length(@on_offer)} unit="listing">
            On offer
          </.section_heading>

          <.listing_grid :if={@on_offer != []}>
            <.listing_card
              :for={listing <- @on_offer}
              id={"on-offer-listing-#{listing.id}"}
              title={listing.title}
              price={listing.display_price}
              navigate={~p"/listings/#{listing}"}
              image_src={cover_url(listing)}
              image_alt={"Cover photo of #{listing.title}"}
              class="transition-shadow hover:shadow-md"
            >
              <:badges>
                <.badge :if={condition(listing)} kind="neutral">{condition(listing)}</.badge>
              </:badges>
              <:meta>Listed {when_listed(listing)}</:meta>
              <:corner>
                <.add_to_cart id={"add-to-cart-#{listing.id}"} listing_id={listing.id} />
              </:corner>
            </.listing_card>
          </.listing_grid>

          <%!-- Selling out is a good outcome, so it is stated in the success
                colour rather than left as a hole where the grid should be. --%>
          <div
            :if={@on_offer == []}
            id="everything-sold"
            class="flex items-start gap-3 p-5 rounded-lg border border-ink-100 dark:border-ink-700"
          >
            <.icon
              name="hero-check-circle"
              aria-hidden="true"
              class="size-5 flex-none mt-0.5 text-success-text"
            />
            <p class="text-body-md text-ink-700 dark:text-ink-300 text-pretty">
              Everything this seller listed has sold. Nothing is on offer at the moment — their record is below.
            </p>
          </div>
        </section>

        <%!-- Absent rather than empty when there is no history: an empty sold
              grid would advertise the absence instead of ending the page on
              what the seller is offering. --%>
        <section
          :if={@sold != []}
          id="sold-section"
          aria-labelledby="sold-heading"
          class="flex flex-col gap-4 pt-6 border-t border-ink-100 dark:border-ink-700"
        >
          <.section_heading id="sold-heading" count={length(@sold)} unit="sale" muted>
            Sold
          </.section_heading>

          <.listing_grid>
            <%!-- No navigate: a sold listing is a record rather than somewhere
                  to go, and its own page would refuse a visitor anyway. --%>
            <.listing_card
              :for={listing <- shown_sold(@sold, @sold_expanded?)}
              id={"sold-listing-#{listing.id}"}
              title={listing.title}
              price={listing.display_price}
              image_src={cover_url(listing)}
              image_alt={"Photo of #{listing.title}"}
              dimmed
            >
              <:badges>
                <.listing_status_badge status={:sold} />
              </:badges>
              <:meta>Sold {when_sold(listing)}</:meta>
            </.listing_card>
          </.listing_grid>

          <div :if={capped?(@sold, @sold_expanded?)} class="flex justify-center">
            <.button id="show-all-sold" size="md" variant="neutral" phx-click="show_all_sold">
              Show all {length(@sold)} sold
            </.button>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  # A band rather than a rail: a left column would cost the grid its width for
  # the whole scroll, where this pays for itself once at the top.
  attr :seller, :map, required: true
  attr :on_offer, :integer, required: true
  attr :sold, :integer, required: true

  defp identity_band(assigns) do
    ~H"""
    <section
      aria-label="Seller"
      class={[
        "flex flex-col gap-5 p-6 sm:flex-row sm:items-center sm:gap-8 sm:p-8",
        "rounded-lg border border-ink-100 dark:border-ink-700 bg-bg-2 dark:bg-ink-900"
      ]}
    >
      <div class={[
        "flex flex-col items-center gap-3.5 text-center min-w-0 flex-1",
        "sm:flex-row sm:items-start sm:gap-5 sm:text-left"
      ]}>
        <.avatar name={name(@seller)} src={@seller.avatar_url} size={96} />

        <div class="flex flex-col items-center gap-1 sm:items-start min-w-0">
          <div class="flex items-center gap-2.5 flex-wrap justify-center sm:justify-start">
            <h1
              id="seller-name"
              class={[
                "text-title-lg sm:text-display font-extrabold text-pretty",
                "text-ink-900 dark:text-white [overflow-wrap:anywhere]"
              ]}
            >
              {name(@seller)}
            </h1>
            <%!-- Stated plainly rather than left for a buyer to infer from an
                  absent sales history. --%>
            <.badge :if={new_seller?(@seller)} kind="new">New seller</.badge>
          </div>

          <%!-- The handle is an identifier, so a tail ellipsis costs nothing;
                the name above is content and wraps in full. --%>
          <div id="seller-handle" class="max-w-full truncate text-body-md font-medium text-ink-500">
            @{@seller.handle}
          </div>

          <%!-- One line, because a rating, a response time and a dispatch time
                are all facts about the same subject and join it as they arrive
                rather than each claiming a box of its own. --%>
          <div class="mt-1.5 flex items-center gap-1.5 text-body-sm text-ink-700 dark:text-ink-300">
            <.icon name="hero-calendar" aria-hidden="true" class="size-3.5" />
            Member since {member_since(@seller)}
          </div>
        </div>
      </div>

      <%!-- On offer and sold are the two numbers that place a seller, so they
            summarise the band from its far end rather than sitting beside the
            name as a claim. --%>
      <div class={[
        "flex items-center justify-center gap-7 pt-4 border-t border-ink-100 dark:border-ink-700",
        "sm:justify-end sm:pt-0 sm:border-t-0"
      ]}>
        <.count id="count-on-offer" value={@on_offer} label="On offer" />
        <div class="w-px self-stretch min-h-10 bg-ink-100 dark:bg-ink-700"></div>
        <.count id="count-sold" value={@sold} label="Sold" />
      </div>
    </section>
    """
  end

  attr :id, :string, required: true
  attr :value, :integer, required: true
  attr :label, :string, required: true

  defp count(assigns) do
    ~H"""
    <%!-- The number and its word read together in document order, so a zero
          states itself rather than being hidden as an absence. --%>
    <div id={@id} class="flex flex-col items-center gap-1 min-w-18 sm:items-end">
      <span class="text-title-lg font-extrabold leading-tight text-ink-900 dark:text-white">
        {@value}
      </span>
      <span class="text-caption-lg font-semibold text-ink-500">{@label}</span>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :count, :integer, required: true
  attr :unit, :string, required: true
  attr :muted, :boolean, default: false
  slot :inner_block, required: true

  defp section_heading(assigns) do
    ~H"""
    <div class="flex items-baseline gap-2.5 flex-wrap">
      <%!-- Sold is demoted rather than hidden: it is evidence, and evidence
            must stay findable without competing with what is for sale. --%>
      <h2
        id={@id}
        class={
          if @muted,
            do: "text-title-md font-bold text-ink-700 dark:text-ink-300",
            else: "text-title-lg font-bold text-ink-900 dark:text-white"
        }
      >
        {render_slot(@inner_block)}
      </h2>
      <span class="text-body-sm text-ink-500">{pluralize(@count, @unit)}</span>
    </div>
    """
  end

  # An account that never existed and one that has been closed read the same,
  # for the same reason a listing does: saying which would answer a question
  # about someone who is not here to be asked.
  defp seller_gone(assigns) do
    ~H"""
    <.empty_state
      id="seller-gone"
      icon="hero-user-circle"
      headline="No seller here"
      description="This profile may have been closed, or the address may be wrong. Nothing else about it can be said."
    >
      <:actions>
        <.button size="sm" variant="neutral" navigate={~p"/"}>Back to Mercato</.button>
      </:actions>
    </.empty_state>
    """
  end

  defp shown_sold(sold, true), do: sold
  defp shown_sold(sold, false), do: Enum.take(sold, @sold_shown)

  defp capped?(sold, expanded?), do: length(shown_sold(sold, expanded?)) < length(sold)

  # A public page may not fall back to the email address the way a signed-in
  # user's own menu does — that would hand a seller's address to anyone.
  defp name(seller), do: Accounts.full_name(seller) || "@#{seller.handle}"

  defp new_seller?(%{inserted_at: opened_at}) do
    DateTime.diff(DateTime.utc_now(), opened_at, :day) < @new_seller_days
  end

  defp member_since(%{inserted_at: opened_at}), do: Calendar.strftime(opened_at, "%B %Y")

  defp condition(listing), do: Listings.condition_label(listing.condition)

  defp cover_url(%{images: images}) when is_list(images) do
    case Enum.find(images, & &1.is_cover) do
      nil -> nil
      cover -> cover.url
    end
  end

  defp cover_url(_listing), do: nil

  # Coarse on purpose. A buyer weighing a seller wants to know whether the shelf
  # is fresh, not the minute a listing changed.
  defp when_listed(%{published_at: published_at, updated_at: updated_at}) do
    month_of(published_at || updated_at)
  end

  defp when_sold(%{updated_at: updated_at}), do: month_of(updated_at)

  defp month_of(nil), do: "at some point"
  defp month_of(at), do: Calendar.strftime(at, "%B %Y")

  defp pluralize(1, unit), do: "1 #{unit}"
  defp pluralize(count, unit), do: "#{count} #{unit}s"
end
