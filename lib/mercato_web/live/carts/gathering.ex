defmodule MercatoWeb.Carts.Gathering do
  @moduledoc """
  Makes the card's add-to-cart control work wherever a card is drawn.

  A mount hook rather than a handler written into each page: browse and a
  seller's storefront offer the same action on the same object, and a page
  that shows listings should not have to know how a cart is written to in
  order to show them.

      on_mount MercatoWeb.Carts.Gathering
  """

  import Phoenix.LiveView
  use Gettext, backend: MercatoWeb.Gettext

  alias Mercato.Carts

  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :gathering, :handle_event, &gather/3)}
  end

  defp gather("add_to_cart", %{"listing" => listing_id}, socket) do
    case Carts.add_to_cart(listing_id, %{}, scope: socket.assigns.current_scope) do
      {:ok, _line} ->
        {:halt, put_flash(socket, :info, gettext("Added to your cart."))}

      # Almost always a listing that stopped being available between the grid
      # being drawn and the control being pressed.
      {:error, _refused} ->
        {:halt, put_flash(socket, :error, gettext("That could not be added to your cart."))}
    end
  end

  defp gather(_event, _params, socket), do: {:cont, socket}
end
