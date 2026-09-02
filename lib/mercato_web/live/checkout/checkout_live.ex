defmodule MercatoWeb.Checkout.CheckoutLive do
  @moduledoc """
  Where a seller's group of the cart is paid for.

  One checkout covers one seller, because one order does. The page is addressed
  by the seller whose group it is rather than by the cart, so a buyer with three
  sellers in their cart pays three times and no arrangement of this page can be
  read as one combined purchase.

  A seller naming no group of the buyer's is not a checkout at all — a stranger's
  id, a seller they have gathered nothing from, and no seller at all lead back to
  the cart alike, rather than to an empty page that looks payable. A group that
  emptied by lapsing says so in its own words: a cart clearing itself after the
  buyer left it alone is not the same news as what they gathered having gone.

  Open to a visitor with no account: gathering a cart never needed one and
  neither does buying it. What identifies a guest on the order they place — an
  email at the least — is settled where the order is placed, which is not built
  yet.

  A review and not a second cart: the rows are the cart's own, without the
  controls to change them, so what the buyer weighed is what they read here.
  Changing their mind is done where the cart is.

  The total is what the items come to and nothing else yet. What delivery costs
  and what fee the marketplace takes are their own lines, and neither exists to
  read; paying is not built either.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Carts.CartLine
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.SellerCard

  alias Ash.Type.UUID
  alias Mercato.Accounts
  alias Mercato.Carts

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _uri, socket) do
    case group_for(params["seller"], socket.assigns.current_scope) do
      # Their own cart clearing itself after they left it alone, which is not
      # the same news as what they gathered having gone.
      {:error, :lapsed} ->
        {:noreply,
         back(
           socket,
           gettext(
             "What you had from that seller sat in your cart too long and was cleared. Add it again to buy it."
           )
         )}

      # The cart offers no checkout for a seller it holds nothing from, so an
      # empty group is one that emptied.
      {:error, :gone} ->
        {:noreply, back(socket, gettext("What you had from that seller is no longer available."))}

      {:ok, %{buyable?: false}} ->
        {:noreply,
         back(
           socket,
           gettext("Something in that group is no longer available. Remove it to check out.")
         )}

      {:ok, group} ->
        {:noreply, assign(socket, :group, group)}
    end
  end

  defp back(socket, said) do
    socket
    |> put_flash(:error, said)
    |> push_navigate(to: ~p"/cart")
  end

  defp group_for(seller_id, scope) when is_binary(seller_id) do
    case UUID.cast_input(seller_id, []) do
      {:ok, uuid} -> Carts.checkout_group(uuid, scope: scope)
      _not_a_uuid -> {:error, :gone}
    end
  end

  defp group_for(_seller_id, _scope), do: {:error, :gone}

  # The seller as the buyer knows them: their name where they gave one, their
  # handle where they did not.
  defp seller_name(seller) do
    Accounts.full_name(seller) || seller.handle || gettext("A seller")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/checkout"}
    >
      <div id="checkout" class="flex flex-col gap-6 max-w-3xl">
        <.breadcrumb items={[
          %{label: gettext("Home"), navigate: ~p"/"},
          %{label: gettext("Cart"), navigate: ~p"/cart"},
          %{label: gettext("Checkout")}
        ]} />

        <.header>
          {gettext("Checkout")}
          <:subtitle>{ngettext("1 item", "%{count} items", @group.item_count)}</:subtitle>
        </.header>

        <.seller_card
          name={seller_name(@group.seller)}
          src={@group.seller.avatar_url}
          meta={gettext("You are buying from this seller")}
          navigate={@group.seller.handle && ~p"/users/#{@group.seller.handle}"}
        />

        <section
          id="checkout-items"
          aria-label={gettext("What you are buying")}
          class={[
            "flex flex-col p-5 md:p-8",
            "rounded-lg border border-ink-100 dark:border-ink-700",
            "bg-bg dark:bg-ink-900 shadow-sm"
          ]}
        >
          <.cart_line
            :for={line <- @group.lines}
            line={line}
            editable?={false}
            total={Carts.line_total(line)}
          />

          <div class="flex items-baseline justify-between gap-3 mt-5 p-3.5 rounded-md bg-bg-2 dark:bg-ink-700">
            <span class="text-body-sm font-bold text-ink-900 dark:text-white">
              {gettext("Total")}
            </span>
            <span
              data-role="checkout-total"
              class="text-title-md font-extrabold tabular-nums text-ink-900 dark:text-white"
            >
              {@group.total}
            </span>
          </div>

          <p class="mt-1.5 m-0 text-caption-md text-ink-500 text-pretty">
            {gettext("What the items come to. Nothing else is added to it yet.")}
          </p>
        </section>

        <p
          id="checkout-protection"
          class="flex items-start gap-2 m-0 text-caption-lg text-ink-500 text-pretty"
        >
          <.icon
            name="hero-shield-check"
            aria-hidden="true"
            class="size-4.5 flex-none mt-px text-success-text"
          />
          {gettext(
            "We hold your payment and release it to the seller only once you confirm the delivery arrived."
          )}
        </p>

        <.alert kind="info" title={gettext("Paying is not built yet")}>
          {gettext("Your cart is kept exactly as you left it. Nothing has been charged.")}
        </.alert>

        <div>
          <.button id="checkout-back" size="md" variant="neutral" navigate={~p"/cart"}>
            {gettext("Back to the cart")}
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
