defmodule MercatoWeb.Carts.CartGroup do
  @moduledoc """
  Everything one seller has in the buyer's cart, as one card.

  The card is the unit that repeats, so a cart of five sellers gets longer
  without getting denser. It is a card and not a heading because a group is
  what becomes a single order: it carries its own total and its own way to
  pay, and no arrangement of it can be read as one combined purchase.

  Colocated with the cart, like `MercatoWeb.Carts.CartLine`, for the same
  reason — nothing else renders one yet.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.Avatar

  @doc "Renders one seller's group. The lines go in the default slot."
  attr :group, :map, required: true, doc: "a group from `Mercato.Carts.group_by_seller/1`"
  attr :rest, :global

  slot :inner_block, required: true, doc: "the group's lines"

  def cart_group(assigns) do
    assigns = assign(assigns, :seller, assigns.group.seller)

    ~H"""
    <section
      id={"cart-group-#{@seller.id}"}
      aria-labelledby={"cart-group-#{@seller.id}-heading"}
      class={[
        "flex flex-col gap-3 p-5 md:p-8",
        "rounded-lg border border-ink-100 dark:border-ink-700",
        "bg-bg dark:bg-ink-900 shadow-sm"
      ]}
      {@rest}
    >
      <div class="flex items-center gap-3">
        <.avatar name={seller_name(@seller)} src={@seller.avatar_url} size={36} />

        <div class="flex-1 min-w-0">
          <h2
            id={"cart-group-#{@seller.id}-heading"}
            class="text-body-sm font-bold text-ink-900 dark:text-white truncate"
          >
            <.link
              :if={@seller.handle}
              navigate={~p"/users/#{@seller.handle}"}
              class="no-underline hover:underline text-inherit"
            >
              {seller_name(@seller)}
            </.link>
            <span :if={!@seller.handle}>{seller_name(@seller)}</span>
          </h2>
          <div :if={@seller.handle} class="text-caption-md text-ink-500 truncate">
            {"@" <> @seller.handle}
          </div>
        </div>

        <.badge kind="neutral" class="flex-none">{item_count(@group.item_count)}</.badge>
      </div>

      <div>{render_slot(@inner_block)}</div>

      <div class="flex items-baseline justify-between gap-3 p-3.5 rounded-md bg-bg-2 dark:bg-ink-700">
        <span class="text-body-sm font-bold text-ink-900 dark:text-white">
          {gettext("Total for this seller")}
        </span>
        <span
          data-role="group-total"
          aria-live="polite"
          class="text-title-md font-extrabold tabular-nums text-ink-900 dark:text-white"
        >
          {@group.total}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <%!-- `critical`, the one variant above the primary CTA: paying is the
              highest-stakes thing on this screen. --%>
        <.button
          id={"checkout-#{@seller.id}"}
          variant="critical"
          full_width
          navigate={~p"/checkout?#{[seller: @seller.id]}"}
          aria-label={
            gettext("Check out with %{seller} for %{total}",
              seller: seller_name(@seller),
              total: @group.total
            )
          }
        >
          <.icon name="hero-lock-closed" aria-hidden="true" class="size-4.5" />
          {gettext("Check out · %{total}", total: @group.total)}
        </.button>

        <p class="flex items-start gap-2 m-0 text-caption-md text-ink-500 text-pretty">
          <.icon
            name="hero-shield-check"
            aria-hidden="true"
            class="size-4 flex-none mt-px text-success-text"
          />
          {gettext(
            "We hold your payment and release it to the seller only once you confirm the delivery arrived."
          )}
        </p>
      </div>
    </section>
    """
  end

  defp seller_name(seller) do
    [seller.first_name, seller.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
    |> case do
      "" -> seller.handle || gettext("A seller")
      name -> name
    end
  end

  defp item_count(count), do: ngettext("1 item", "%{count} items", count)
end
