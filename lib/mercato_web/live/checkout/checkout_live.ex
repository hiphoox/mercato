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

  The total is broken into what it is made of rather than shown as one number:
  the items, then whatever the marketplace adds on top. What delivery costs is
  a line of the same kind and does not exist to read yet. Paying is not built
  either.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Carts.CartLine
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.MoneyBreakdown
  import MercatoWeb.UI.SellerCard

  alias Ash.Type.UUID
  alias Mercato.Accounts
  alias Mercato.Carts
  alias Mercato.Payments.BuyerFee

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
        {:noreply, assign(socket, group: group, summary: summary(group))}
    end
  end

  # What the buyer pays, and every part of it: the items first, then each fee
  # the marketplace charges on top, under the name the operator gave it.
  #
  # A row that comes to nothing draws no line. A marketplace configuring a fee
  # at zero is one that charges no fee, and a buyer reading a line of nothing
  # has been told about a charge that is not being made.
  defp summary(group) do
    fees = BuyerFee.breakdown(group.amount)
    charged = Enum.reject(fees.lines, &(&1.amount == 0))

    %{
      lines: [%{name: gettext("Items"), amount: group.amount} | charged],
      total: group.amount + fees.total
    }
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
      cart_count={@cart_count}
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

          <.money_breakdown
            id="checkout-summary"
            lines={@summary.lines}
            currency={@group.currency}
            total={@summary.total}
            total_label={gettext("Total")}
            size="lg"
            class="mt-5 p-3.5 rounded-md bg-bg-2 dark:bg-ink-700"
          >
            <:note>{gettext("What you pay, in full. Nothing is added after this.")}</:note>
          </.money_breakdown>
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
