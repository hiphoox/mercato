defmodule MercatoWeb.Checkout.CheckoutLive do
  @moduledoc """
  Where a seller's group of the cart is paid for.

  A placeholder for now. It is addressed and reachable so the cart's checkout
  button is a real action rather than a dead control, and it takes the seller
  it is for as a parameter, because one order covers one seller and this page
  will only ever be about one group.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Breadcrumb

  on_mount {MercatoWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :seller_id, params["seller"])}
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
