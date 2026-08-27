defmodule MercatoWeb.UI.SellerCard do
  @moduledoc """
  Who is on the other side of a transaction, as a row a buyer can weigh.

  The trust signal the design system asks for at every moment of doubt — on a
  listing's detail page, beside an offer, at checkout — which is why it is a
  shared component rather than one page's markup.

  Deliberately unaware of `Mercato.Accounts.User`, like `MercatoWeb.UI.Avatar`:
  callers pass a display name and an already-written meta line. Reputation —
  a rating, a sales count, a response time — is not a field here; it arrives
  through the slots when the features that produce it exist.

      <.seller_card name="Marta Ribeiro" meta="Selling on Mercato since 2023">
        <:badges><.badge kind="verified">Verified</.badge></:badges>
      </.seller_card>
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.Avatar

  @doc """
  Renders a seller row.

  Wraps below `sm`, where the name and the actions cannot share a line.
  """
  attr :name, :string, required: true, doc: "display name — drives the avatar's initials too"
  attr :src, :string, default: nil, doc: "the seller's photo; initials show without one"
  attr :meta, :string, default: nil, doc: "one caption line under the name"
  attr :navigate, :string, default: nil, doc: "makes the name a link to the seller's own page"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :badges, doc: "verification or standing, shown beside the name"
  slot :actions, doc: "what a buyer can do about this seller"

  def seller_card(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center gap-3 flex-wrap sm:flex-nowrap p-3.5",
        "rounded-lg border border-ink-100 dark:border-ink-700 bg-bg dark:bg-ink-900",
        @class
      ]}
      {@rest}
    >
      <.avatar name={@name} src={@src} size={48} />

      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 flex-wrap">
          <%!-- The name is what a buyer reaches for when they want to know more
                about who they are dealing with, so it is what carries the link
                when there is somewhere to go. --%>
          <span data-role="seller-name" class="text-body-md font-bold text-ink-900 dark:text-white">
            <.link :if={@navigate} navigate={@navigate} class="no-underline hover:underline">
              {@name}
            </.link>
            <span :if={!@navigate}>{@name}</span>
          </span>
          <span
            :if={@badges != []}
            data-role="seller-badges"
            class="flex items-center gap-1.5 flex-wrap"
          >
            {render_slot(@badges)}
          </span>
        </div>

        <div :if={@meta} data-role="seller-meta" class="mt-0.5 text-caption-lg text-ink-500">
          {@meta}
        </div>
      </div>

      <div
        :if={@actions != []}
        data-role="seller-actions"
        class="flex items-center gap-2 flex-wrap"
      >
        {render_slot(@actions)}
      </div>
    </div>
    """
  end
end
