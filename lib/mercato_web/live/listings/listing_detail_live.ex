defmodule MercatoWeb.Listings.ListingDetailLive do
  @moduledoc """
  One listing as a buyer decides on it: what it is, who is selling it, and what
  taking it costs.

  The page carries the whole decision and is also the buy surface, so the
  gallery takes the room and the panel beside it holds the action. It is public
  — a visitor with no account reaches it — and the seller who owns the listing
  gets the same page with their own actions in the panel's slot, which is what
  makes it usable as a preview of what buyers see.

  A listing the viewer may not see is not distinguished from one that never
  existed: draft, paused, sold and unknown all read as "no longer available",
  because a public page saying which would leak what the seller has.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Listings.GalleryViewer
  import MercatoWeb.Listings.PurchasePanel
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.EmptyState
  import MercatoWeb.UI.SellerCard

  alias Mercato.Accounts
  alias Mercato.Listings

  # Enough to tell a buyer what the thing is before they decide whether to read
  # the rest. A seller may write up to 5,000 characters, and a wall of them
  # between the photos and the seller card buries both.
  @preview_length 140

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_photo, 0)
     |> assign(:gallery_expanded?, false)
     |> assign(:description_expanded?, false)
     |> load_listing(id)}
  end

  # Wraps rather than stopping at either end, so neither arrow is ever a control
  # that does nothing.
  defp step_photo(socket, by) do
    count = length(socket.assigns.listing.images)

    update(socket, :active_photo, &Integer.mod(&1 + by, count))
  end

  # Not found and not-allowed are one outcome on purpose: the read policy
  # filters rather than refuses, so a listing the viewer may not see arrives
  # here as an absence, and the page has nothing to say beyond that.
  defp load_listing(socket, id) do
    case Listings.get_listing(id, actor: socket.assigns.current_user) do
      {:ok, listing} -> assign(socket, listing: listing, id: id)
      {:error, _gone} -> assign(socket, listing: nil, id: id)
    end
  end

  @impl true
  def handle_event("choose_photo", %{"index" => index}, socket) do
    {:noreply, assign(socket, :active_photo, String.to_integer(index))}
  end

  def handle_event("previous_photo", _params, socket) do
    {:noreply, step_photo(socket, -1)}
  end

  def handle_event("next_photo", _params, socket) do
    {:noreply, step_photo(socket, 1)}
  end

  def handle_event("expand_gallery", _params, socket) do
    {:noreply, assign(socket, :gallery_expanded?, true)}
  end

  def handle_event("toggle_description", _params, socket) do
    {:noreply, update(socket, :description_expanded?, &(!&1))}
  end

  # The buy surface is finished; what it starts is not. Saying so is better than
  # a control that looks live and does nothing, and better than hiding the
  # action the whole page is built around.
  def handle_event("buy", _params, socket) do
    {:noreply,
     put_flash(socket, :error, "Checkout is not available yet — orders are still being built.")}
  end

  def handle_event("publish", _params, socket) do
    moved(socket, &Listings.publish_listing/2, "is on offer.", "could not be published.")
  end

  def handle_event("pause", _params, socket) do
    moved(socket, &Listings.pause_listing/2, "was paused.", "could not be paused.")
  end

  def handle_event("resume", _params, socket) do
    moved(socket, &Listings.resume_listing/2, "is back on offer.", "could not go back on offer.")
  end

  # Every move re-reads the listing, so the panel, the banner and the badge all
  # describe the same snapshot. A refusal is almost always the gallery minimum
  # or a state someone else moved the listing out of first.
  defp moved(socket, move, said, refused) do
    %{listing: listing, current_user: user} = socket.assigns

    case move.(listing, actor: user) do
      {:ok, _moved} ->
        {:noreply,
         socket
         |> load_listing(listing.id)
         |> put_flash(:info, "“#{listing.title}” #{said}")}

      {:error, _refused} ->
        {:noreply, put_flash(socket, :error, "That listing #{refused}")}
    end
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:banner, owner_banner(assigns.listing, assigns.current_user))
      |> assign(:description, description(assigns))

    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={@current_user}
      admin?={@admin?}
      current_path={~p"/listings/#{@id}"}
    >
      <.empty_state
        :if={!@listing}
        id="listing-gone"
        icon="hero-archive-box-x-mark"
        headline="This listing is no longer available"
        description="It may have sold, been paused by the seller, or been taken down. The link still works, so you can keep it in your history."
      >
        <:actions>
          <.button size="sm" variant="neutral" navigate={~p"/"}>Back to Mercato</.button>
        </:actions>
      </.empty_state>

      <div :if={@listing} id="listing-detail" class="flex flex-col gap-6">
        <%!-- The framing comes before the page rather than being scattered through
              it: the owner has to trust everything below as a faithful preview. --%>
        <.alert :if={@banner} id="owner-banner" kind={@banner.kind} title={@banner.headline}>
          {@banner.body}
        </.alert>

        <%!-- One level deep, because the catalog is flat. The category is a label
              rather than a link until there is a page to browse it on. --%>
        <.breadcrumb items={[%{label: "Home", navigate: ~p"/"}, %{label: @listing.category.name}]} />

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-[minmax(0,1fr)_23.75rem] lg:gap-8 lg:items-start">
          <%!-- Only below `lg`, where the panel comes after the photos and its own
                title would arrive too late to name what is being looked at. From
                `lg` up this one goes and the panel's own heads the column, so the
                listing is named once at either width. --%>
          <h1
            id="listing-title-compact"
            class={[
              "lg:hidden min-w-0 text-h2 font-extrabold leading-tight",
              "text-ink-900 dark:text-white text-pretty"
            ]}
          >
            {@listing.title}
          </h1>

          <div class="flex flex-col gap-7 min-w-0">
            <.gallery_viewer
              images={@listing.images}
              alt={"Photo of #{@listing.title}"}
              active={@active_photo}
              expanded?={@gallery_expanded?}
            >
              <:badges>
                <.badge :if={@listing.status == :sold} kind="info">Sold</.badge>
                <.badge :if={@listing.status == :active and @listing.quantity == 0} kind="warning">
                  Out of stock
                </.badge>
              </:badges>
            </.gallery_viewer>

            <section aria-labelledby="description-heading" class="flex flex-col gap-2.5">
              <h2
                id="description-heading"
                class="text-title-md font-bold text-ink-900 dark:text-white"
              >
                Description
              </h2>
              <div id="listing-description" class="flex flex-col items-start gap-2.5">
                <div id="description-text" class="flex flex-col gap-2.5">
                  <p
                    :for={paragraph <- @description.paragraphs}
                    class="max-w-[66ch] text-body-md leading-relaxed text-ink-700 dark:text-ink-100 text-pretty"
                  >
                    {paragraph}
                  </p>
                </div>

                <%!-- A button rather than a link: it reveals text already on the
                      page and goes nowhere. --%>
                <button
                  :if={@description.truncated?}
                  type="button"
                  id="expand-description"
                  phx-click="toggle_description"
                  aria-expanded={to_string(@description_expanded?)}
                  aria-controls="description-text"
                  class={[
                    "text-body-sm font-semibold text-primary-700 dark:text-primary-100 cursor-pointer",
                    "transition-colors hover:text-primary-600",
                    "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100 rounded-sm"
                  ]}
                >
                  {if @description_expanded?, do: "Show less", else: "Show more"}
                </button>

                <p :if={@description.empty?} class="text-body-md text-ink-500">
                  The seller did not add a description.
                </p>
              </div>
            </section>
          </div>

          <%!-- Who is selling follows what it costs at every width: on a phone the
                two stack in that order, and on a desktop they share the column
                beside the gallery. Sticky from lg up, so a long description never
                scrolls the action away on a wide screen either. --%>
          <div class="lg:sticky lg:top-0 min-w-0 flex flex-col gap-7">
            <aside aria-label="Purchase">
              <.purchase_panel
                title={@listing.title}
                price={@listing.display_price}
                category={@listing.category.name}
                condition={Listings.condition_label(@listing.condition)}
                status={@listing.status}
                quantity={@listing.quantity}
                owner?={owner?(@listing, @current_user)}
                signed_in?={!is_nil(@current_user)}
                edit_path={~p"/listings/#{@listing.id}/edit"}
                sold_at={@listing.updated_at}
              />
            </aside>

            <section aria-labelledby="seller-heading" class="flex flex-col gap-2.5">
              <h2 id="seller-heading" class="text-title-md font-bold text-ink-900 dark:text-white">
                Seller
              </h2>
              <.seller_card
                id="listing-seller"
                name={seller_name(@listing.seller)}
                src={@listing.seller.avatar_url}
                meta={seller_meta(@listing.seller)}
              />
            </section>
          </div>
        </div>

        <%!-- Below lg the panel scrolls away with the page, so the action and the
              price it commits to travel pinned to the bottom instead. --%>
        <.sticky_buy_bar
          :if={buyable?(@listing, @current_user)}
          price={@listing.display_price}
          quantity={@listing.quantity}
        />
      </div>
    </Layouts.app>
    """
  end

  defp owner?(listing, %{id: id}), do: listing.seller_id == id
  defp owner?(_listing, _viewer), do: false

  defp buyable?(listing, viewer) do
    listing.status == :active and not owner?(listing, viewer)
  end

  # Draft and paused are worded apart on purpose: a draft was never public, and
  # confusing the two makes a seller think they lost traffic they never had.
  defp owner_banner(nil, _viewer), do: nil

  defp owner_banner(listing, viewer) do
    if owner?(listing, viewer), do: banner(listing.status)
  end

  defp banner(:active) do
    %{
      kind: "info",
      headline: "This is your listing, shown exactly as buyers see it",
      body:
        "Everything below is the public page. Only the panel on the right changes: " <>
          "buyers see a Buy now button where your seller actions are."
    }
  end

  defp banner(:unavailable) do
    %{
      kind: "warning",
      headline: "Paused — nobody else can open this page",
      body:
        "The link reads “no longer available” for buyers. Resume when you want it back in search."
    }
  end

  defp banner(:draft) do
    %{
      kind: "info",
      headline: "Draft — never published",
      body:
        "This is a preview of what publishing would put in front of buyers. " <>
          "It is not searchable and has no public link yet."
    }
  end

  defp banner(_status), do: nil

  # What to render and whether there is more behind it, decided once so the
  # template does not have to ask the same question three ways.
  defp description(%{listing: nil}), do: %{paragraphs: [], truncated?: false, empty?: true}

  defp description(%{listing: listing, description_expanded?: expanded?}) do
    paragraphs = paragraphs(listing.description)
    full = Enum.join(paragraphs, "\n\n")
    truncated? = String.length(full) > @preview_length

    cond do
      paragraphs == [] ->
        %{paragraphs: [], truncated?: false, empty?: true}

      expanded? or not truncated? ->
        %{paragraphs: paragraphs, truncated?: truncated?, empty?: false}

      true ->
        %{paragraphs: [preview(full)], truncated?: true, empty?: false}
    end
  end

  # Cut at a word boundary rather than mid-word: the preview is meant to be read,
  # and a severed word reads as a rendering fault.
  defp preview(full) do
    full
    |> String.slice(0, @preview_length)
    |> String.replace(~r/\s+\S*$/u, "")
    |> String.trim_trailing()
    |> Kernel.<>("…")
  end

  # Blank lines are the only structure a plain-text description carries, so they
  # are the only structure this reproduces.
  defp paragraphs(nil), do: []

  defp paragraphs(description) do
    description
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  # Stops at the handle. This page is public, so falling back to an email
  # address the way the signed-in user's own menu does would hand a seller's
  # address to every visitor.
  defp seller_name(seller) do
    Accounts.full_name(seller) || to_string(seller.handle || "A Mercato seller")
  end

  # The handle is the only thing about a seller this marketplace records beyond
  # their name, so it is the whole meta line. A rating, a sales count, a join
  # date and a response time belong here too, and land with the features that
  # produce them rather than being invented now.
  defp seller_meta(%{handle: handle}) when handle not in [nil, ""], do: "@#{handle}"
  defp seller_meta(_seller), do: nil
end
