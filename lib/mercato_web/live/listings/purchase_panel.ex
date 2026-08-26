defmodule MercatoWeb.Listings.PurchasePanel do
  @moduledoc """
  The column a listing's detail page turns on: what the thing is, what it costs,
  and the one action that takes it.

  Read top to bottom it answers "what is it, is it worth it, can I get it" in a
  single pass, which is why the title lives here rather than over the gallery.

  One anatomy, two sets of contents. A buyer gets the buy action; the seller
  looking at their own listing gets their seller actions in the same slot, so
  the page stays a faithful preview of what a buyer sees. A listing that has
  come to rest gets a statement instead of a control — a disabled Buy now would
  imply it might come back.

  Colocated with `MercatoWeb.Listings.ListingDetailLive`: it is the buy surface
  of one page, not a shape anything else renders.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.ListingStatusBadge

  @doc """
  Renders the panel.

  `price` arrives already formatted — the panel never sees the currency the
  listing carries. `status` is a `t:Mercato.Listings.Listing.Status.t/0` value
  and `quantity` qualifies it: an active listing with none left is a different
  state from a sold one, and the two must not read alike.
  """
  attr :id, :string, default: "purchase-panel"
  attr :title, :string, required: true
  attr :price, :string, required: true, doc: "already formatted for display"
  attr :category, :string, required: true
  attr :condition, :string, default: nil, doc: "already written the way a person reads it"
  attr :status, :atom, required: true
  attr :quantity, :integer, required: true
  attr :owner?, :boolean, default: false, doc: "whether the viewer is the listing's seller"
  attr :edit_path, :string, default: nil, doc: "where the seller's editing actions lead"
  attr :sold_at, :any, default: nil, doc: "when the sale completed, for the closed statement"
  attr :rest, :global

  def purchase_panel(assigns) do
    assigns =
      assigns
      |> assign(:state, state(assigns))
      |> assign(:availability, availability(assigns))

    ~H"""
    <.card id={@id} class="flex flex-col gap-3.5" {@rest}>
      <%!-- The same badge the seller's form shows, from the one place that decides
            how a state reads — the two surfaces must not word a listing differently. --%>
      <.listing_status_badge
        :if={@state.status_badge}
        id="listing-status"
        status={@state.status_badge}
        class="self-start"
      />

      <%!-- Running out is not a lifecycle state, so it is its own mark: zero stock
            is recoverable and a sale is not, and they never share a colour. --%>
      <.badge :if={@state.out_of_stock?} id="listing-stock" kind="warning" class="self-start gap-1.5">
        <.icon name="hero-exclamation-circle" aria-hidden="true" class="size-3.5" /> Out of stock
      </.badge>

      <h1
        id="listing-title"
        class="text-title-lg font-extrabold leading-tight text-ink-900 dark:text-white text-pretty"
      >
        {@title}
      </h1>

      <%!-- A flex row with a gap, so a listing with no condition leaves no stub
            behind — the category simply sits alone. --%>
      <div class="flex items-center gap-2 flex-wrap text-body-sm text-ink-500">
        <span class="font-semibold">{@category}</span>
        <span :if={@condition} aria-hidden="true" class="size-1 rounded-full bg-ink-300" />
        <span
          :if={@condition}
          id="listing-condition"
          class={[
            "inline-flex items-center h-6.5 px-2.5 rounded-full",
            "border border-ink-300 font-semibold text-ink-700 dark:text-ink-100"
          ]}
        >
          {@condition}
        </span>
      </div>

      <div class="flex flex-col gap-1">
        <%!-- The single number the decision turns on. A sold listing keeps it —
              what it went for is the useful fact — but drops to ink-500, since
              it is a record rather than an offer. --%>
        <p
          id="listing-price"
          class={[
            "text-display font-extrabold leading-none",
            @state.closed? && "text-ink-500",
            !@state.closed? && "text-ink-900 dark:text-white"
          ]}
        >
          {@price}
        </p>
        <p
          id="listing-availability"
          class={["flex items-center gap-1.5 text-body-sm font-semibold", @availability.class]}
        >
          <.icon name={@availability.icon} aria-hidden="true" class="size-3.5" />
          {@availability.label}
        </p>
      </div>

      <div :if={@state.buyable?} class="flex flex-col gap-2">
        <.button
          id="buy-now"
          variant="critical"
          size="lg"
          full_width
          disabled={@quantity == 0}
          phx-click="buy"
        >
          {if @quantity == 0, do: "Sold out", else: "Buy now"}
        </.button>
        <p class="text-caption-md text-ink-500 text-pretty">{@state.footnote}</p>
      </div>

      <div :if={@state.owner_actions} class="flex flex-col gap-2.5">
        <.button
          id="owner-primary"
          variant="primary"
          size="lg"
          full_width
          navigate={@state.owner_actions.primary.navigate}
          phx-click={@state.owner_actions.primary.event}
        >
          {@state.owner_actions.primary.label}
        </.button>
        <.button
          id="owner-secondary"
          variant="tertiary"
          size="md"
          full_width
          navigate={@state.owner_actions.secondary.navigate}
          phx-click={@state.owner_actions.secondary.event}
        >
          {@state.owner_actions.secondary.label}
        </.button>
        <p class={[
          "flex gap-2 px-3 py-2.5 rounded-md bg-bg-2 dark:bg-ink-700",
          "text-caption-lg leading-normal text-ink-500 text-pretty"
        ]}>
          <.icon name="hero-eye" aria-hidden="true" class="size-3.5 flex-none mt-0.5" />
          <span>{@state.owner_actions.note}</span>
        </p>
      </div>

      <%!-- Said in words rather than only by the absence of a button. --%>
      <div
        :if={@state.closed?}
        id="listing-closed"
        class="flex flex-col gap-1.5 px-4 py-3.5 rounded-md bg-bg-2 dark:bg-ink-700"
      >
        <p class="text-body-md font-bold text-ink-900 dark:text-white">This listing is closed</p>
        <p class="text-body-sm text-ink-500 text-pretty">{closed_body(@sold_at)}</p>
      </div>

      <div class="h-px bg-ink-100 dark:bg-ink-700" />

      <%!-- Directly under the action, at caption weight: it answers the fear that
            arrives at the moment of committing, and reassures rather than defends. --%>
      <p id="buyer-protection" class="flex gap-2.5 text-caption-lg leading-normal text-ink-500">
        <.icon name="hero-shield-check" aria-hidden="true" class="size-4.5 flex-none mt-px" />
        <span>
          <span class="font-bold text-ink-700 dark:text-ink-100">Buyer protection.</span>
          Mercato holds the payment until you confirm the item arrived as described. If it doesn't, you get it back.
        </span>
      </p>
    </.card>
    """
  end

  @doc """
  Renders the bar pinned to the bottom of a narrow viewport.

  Carries the price as well as the action, so the buyer never has to scroll back
  to check what they are committing to. It is the panel's action and nothing
  else: a listing with no buy path gets no bar rather than a dead one.
  """
  attr :price, :string, required: true
  attr :quantity, :integer, required: true
  attr :rest, :global

  def sticky_buy_bar(assigns) do
    ~H"""
    <div
      class={
        [
          # Floating inside the column's padding rather than pulled flush to its
          # edges: the scrolling column pads itself differently below `md` than
          # above it, so a negative margin tuned to one width is wrong at the other.
          "lg:hidden sticky bottom-0 z-30 flex items-center gap-3 p-3 rounded-lg",
          "bg-bg dark:bg-ink-900 border border-ink-100 dark:border-ink-700 shadow-md"
        ]
      }
      {@rest}
    >
      <div class="flex-1 min-w-0">
        <p class="text-title-md font-extrabold text-ink-900 dark:text-white">{@price}</p>
        <p class="text-caption-md text-ink-500 truncate">Payment held until delivery</p>
      </div>
      <.button
        id="sticky-buy-now"
        variant="critical"
        size="lg"
        disabled={@quantity == 0}
        phx-click="buy"
      >
        {if @quantity == 0, do: "Sold out", else: "Buy now"}
      </.button>
    </div>
    """
  end

  # Everything that varies by who is looking and what state the listing is in,
  # decided once so the template reads as one anatomy rather than as branches.
  # The lifecycle badge is the seller's, not the buyer's: a listing simply on
  # offer needs no label, while the seller checking their own wants the same
  # state their form shows them.
  defp state(%{owner?: true, status: status} = assigns)
       when status in [:active, :unavailable, :draft] do
    %{
      status_badge: status,
      out_of_stock?: out_of_stock?(assigns),
      buyable?: false,
      closed?: false,
      footnote: nil,
      owner_actions: owner_actions(status, assigns.edit_path)
    }
  end

  defp state(%{status: :sold}) do
    %{
      status_badge: :sold,
      out_of_stock?: false,
      buyable?: false,
      closed?: true,
      footnote: nil,
      owner_actions: nil
    }
  end

  defp state(%{status: status, quantity: quantity} = assigns) do
    %{
      status_badge: nil,
      out_of_stock?: out_of_stock?(assigns),
      buyable?: status == :active,
      closed?: false,
      owner_actions: nil,
      footnote: buy_footnote(quantity)
    }
  end

  defp out_of_stock?(%{status: :active, quantity: 0}), do: true
  defp out_of_stock?(_assigns), do: false

  defp availability(%{status: :sold, sold_at: sold_at}) do
    %{icon: "hero-check-circle", class: "text-ink-500", label: "Sold #{on_date(sold_at)}"}
  end

  # Plain cause rather than "unavailable", which is what a paused listing is and
  # means something else entirely.
  defp availability(%{quantity: 0}) do
    %{
      icon: "hero-exclamation-circle",
      class: "text-warning-text",
      label: "None left — the seller ran out"
    }
  end

  defp availability(%{quantity: 1}) do
    %{icon: "hero-archive-box", class: "text-ink-500", label: "1 available"}
  end

  defp availability(%{quantity: quantity}) do
    %{icon: "hero-archive-box", class: "text-ink-500", label: "#{quantity} available"}
  end

  # The disabled control raises the question of whether pressing it costs
  # anything; the line answers it in place.
  defp buy_footnote(0), do: "Nothing is charged. The seller can restock this listing at any time."

  defp buy_footnote(_quantity) do
    "You can start without an account. Sign in or continue as a guest at the next step, before any payment."
  end

  # Editing is a page, so the primary carries a target rather than an event —
  # except on a draft, where the one thing missing is publication.
  defp owner_actions(:active, edit_path) do
    %{
      primary: %{label: "Edit listing", navigate: edit_path, event: nil},
      secondary: %{label: "Pause listing", navigate: nil, event: "pause"},
      note: "Buyers see a Buy now button in this spot, with the buyer-protection line below it."
    }
  end

  defp owner_actions(:unavailable, edit_path) do
    %{
      primary: %{label: "Edit listing", navigate: edit_path, event: nil},
      secondary: %{label: "Resume listing", navigate: nil, event: "resume"},
      note: "While paused there is no buy path for anyone. Resuming restores it immediately."
    }
  end

  # The one thing a draft is missing is publication, so that is the button, and
  # editing steps down to the secondary rather than disappearing.
  defp owner_actions(:draft, edit_path) do
    %{
      primary: %{label: "Publish listing", navigate: nil, event: "publish"},
      secondary: %{label: "Keep editing", navigate: edit_path, event: nil},
      note: "Publishing turns this panel into the buy panel and puts the listing in search."
    }
  end

  defp closed_body(sold_at) do
    "Sold to a buyer #{on_date(sold_at)}. The page stays up as a record — nothing here can be bought."
  end

  defp on_date(nil), do: "at some point"
  defp on_date(at), do: "on #{Calendar.strftime(at, "%-d %B %Y")}"
end
