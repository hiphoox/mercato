defmodule MercatoWeb.Checkout.CheckoutLive do
  @moduledoc """
  Where a seller's group of the cart is paid for.

  One checkout covers one seller, because one order does. The page is addressed
  by the seller whose group it is rather than by the cart, so a buyer with three
  sellers in their cart pays three times and no arrangement of this page can be
  read as one combined purchase.

  A seller naming no group of the buyer's is not a checkout at all — a stranger's
  id, a seller they have gathered nothing from, and no seller at all lead back to
  the cart alike, rather than to an empty page that looks payable.

  Open to a visitor with no account: gathering a cart never needed one and
  neither does buying it. What identifies a guest on the order they place — an
  email at the least — is settled where the order is placed, which is not built
  yet.

  What is being bought, from whom, and at what total is still a placeholder.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Breadcrumb

  alias Ash.Type.UUID
  alias Mercato.Carts

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _uri, socket) do
    case group_for(params["seller"], socket.assigns.current_scope) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("There is nothing from that seller in your cart."))
         |> push_navigate(to: ~p"/cart")}

      group ->
        {:noreply, assign(socket, :group, group)}
    end
  end

  # A seller id that is not a uuid never reaches the cart: it cannot name a
  # group, so it is the same nothing as a seller they have gathered nothing from.
  defp group_for(seller_id, scope) when is_binary(seller_id) do
    case UUID.cast_input(seller_id, []) do
      {:ok, uuid} -> Carts.seller_group(uuid, scope: scope)
      _not_a_uuid -> nil
    end
  end

  defp group_for(_seller_id, _scope), do: nil

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

        <.header>{gettext("Checkout")}</.header>

        <.alert kind="info" title={gettext("Checkout is not built yet")}>
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
