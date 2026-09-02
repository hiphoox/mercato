defmodule MercatoWeb.Carts.CartLine do
  @moduledoc """
  One listing a buyer means to buy, as the cart shows it.

  Colocated with the cart rather than shared: it is a row of a cart and of
  nothing else. It moves up to `MercatoWeb.UI` the day a second surface — a
  cart drawer, an order review — needs the same row as-is.

  The figures arrive already worked out. What a line comes to is money
  arithmetic in a currency this layer does not know, so `Mercato.Carts` does
  it and the row renders the string.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.QuantityStepper

  alias Mercato.Listings

  @doc """
  Renders a line.

  A stepper only where there is something to step: a seller with one of a thing
  gets the one-of-a-kind pill instead, which says why the control is missing
  rather than showing a dead one.
  """
  attr :line, :map, required: true, doc: "a `Mercato.Carts.CartItem` with its listing loaded"
  attr :total, :string, required: true, doc: "what the line comes to, already formatted"

  attr :buyable?, :boolean,
    default: true,
    doc: "whether the listing behind the line can still be bought"

  attr :rest, :global

  def cart_line(assigns) do
    assigns =
      assigns
      |> assign(:listing, assigns.line.listing)
      |> assign(:title, title(assigns.line.listing))
      |> assign(:stock, stock(assigns.line.listing))

    ~H"""
    <div
      id={"cart-line-#{@line.id}"}
      class="flex gap-3 md:gap-3.5 py-3.5 border-t border-ink-100 dark:border-ink-700"
      {@rest}
    >
      <div class={[
        "flex items-center justify-center overflow-hidden flex-none",
        "size-18 md:size-21 rounded-md bg-ink-100 dark:bg-ink-700"
      ]}>
        <img
          :if={cover_url(@listing)}
          src={cover_url(@listing)}
          alt={gettext("Cover photo of %{title}", title: @title)}
          class={["size-full object-cover", !@buyable? && "grayscale opacity-60"]}
        />
        <.icon
          :if={!cover_url(@listing)}
          name="hero-photo"
          data-role="placeholder"
          aria-hidden="true"
          class="size-5.5 text-ink-300"
        />
      </div>

      <div class="flex-1 min-w-0 flex flex-col gap-2">
        <div class="flex items-start gap-3">
          <%!-- Two lines and no more: a long title pushes nothing else off the
                row, and the figures keep their column on the right. --%>
          <h3 class={[
            "flex-1 min-w-0 m-0 text-body-sm font-semibold leading-snug line-clamp-2",
            if(@buyable?, do: "text-ink-900 dark:text-white", else: "text-ink-500 line-through")
          ]}>
            <.link
              :if={@buyable?}
              navigate={~p"/listings/#{@listing}"}
              class="no-underline hover:underline text-inherit"
            >
              {@title}
            </.link>
            <span :if={!@buyable?}>{@title}</span>
          </h3>

          <div :if={@buyable?} class="flex-none text-right">
            <div
              data-role="line-total"
              class="text-body-md font-bold tabular-nums text-ink-900 dark:text-white"
            >
              {@total}
            </div>
            <%!-- Only where the two figures differ: on a line of one the unit
                  price would just restate the total. --%>
            <div :if={@line.quantity > 1} data-role="unit-price" class="text-caption-md text-ink-500">
              {gettext("%{price} each", price: @listing.display_price)}
            </div>
          </div>
        </div>

        <div :if={@buyable? and @listing.condition} class="text-caption-lg text-ink-500 truncate">
          {Listings.condition_label(@listing.condition)}
        </div>

        <div
          :if={!@buyable?}
          data-role="unavailable"
          class="flex items-center gap-1.5 text-caption-lg font-semibold text-error-text"
        >
          <.icon name="hero-exclamation-circle" aria-hidden="true" class="size-4 flex-none" />
          {gettext("No longer available")}
        </div>

        <div class="flex items-center gap-2 flex-wrap pt-0.5">
          <.quantity_stepper
            :if={@buyable? and @stock > 1}
            id={"qty-#{@line.id}"}
            value={@line.quantity}
            max={@stock}
            label={@listing.title}
            phx-click="set_quantity"
            phx-value-id={@line.id}
          />

          <span
            :if={@buyable? and @stock <= 1}
            data-role="one-of-a-kind"
            class={[
              "inline-flex items-center gap-1.5 h-6.5 px-2.5 flex-none rounded-full",
              "border border-ink-100 dark:border-ink-700 bg-bg-2 dark:bg-ink-700",
              "text-caption-md font-semibold text-ink-500 dark:text-ink-100 whitespace-nowrap"
            ]}
          >
            <.icon name="hero-sparkles" aria-hidden="true" class="size-3.5" />
            {gettext("One of a kind")}
          </span>

          <button
            type="button"
            id={"remove-#{@line.id}"}
            phx-click="remove"
            phx-value-id={@line.id}
            aria-label={gettext("Remove %{title} from the cart", title: @title)}
            class={[
              "ml-auto flex items-center justify-center size-9 flex-none rounded-md cursor-pointer",
              "text-ink-500 transition-colors",
              "hover:bg-error-bg hover:text-error-text",
              "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
            ]}
          >
            <.icon name="hero-trash" aria-hidden="true" class="size-4" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  # Nil where moderation took the listing down, which hides it from the buyer too.
  defp title(nil), do: gettext("An item you gathered")
  defp title(listing), do: listing.title

  defp stock(nil), do: 0
  defp stock(listing), do: listing.quantity

  defp cover_url(%{images: images}) when is_list(images) do
    case Enum.find(images, & &1.is_cover) do
      nil -> nil
      cover -> cover.url
    end
  end

  defp cover_url(_listing), do: nil
end
