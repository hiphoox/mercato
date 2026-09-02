defmodule MercatoWeb.Carts.Counting do
  @moduledoc """
  Keeps how much the buyer has gathered on hand, for the header to show.

  Every page draws the cart control, so every page has to know the figure —
  a mount hook rather than a line in each LiveView.

  Counted after mount rather than during it: who is looking is settled by
  `MercatoWeb.LiveUserAuth`, which each page mounts for itself and which has
  not run when a hook of the live session does.

      on_mount MercatoWeb.Carts.Counting

  A page that changes the cart without navigating away from itself says so
  with `refresh/1`, the count being drawn once per arrival otherwise.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias Mercato.Carts

  def on_mount(:count, _params, _session, socket) do
    {:cont, attach_hook(socket, :cart_count, :handle_params, &count/3)}
  end

  defp count(_params, _uri, socket), do: {:cont, refresh(socket)}

  @doc "Reads the cart again and assigns what it comes to."
  def refresh(socket) do
    assign(socket, :cart_count, gathered(socket.assigns.current_scope))
  end

  @doc """
  Assigns a count already worked out, for a page holding the lines already.

  The cart's own page reads them to draw them, and reading them twice to
  count what it is holding would be reading them twice.
  """
  def assign_count(socket, lines), do: assign(socket, :cart_count, Carts.item_count(lines))

  # Counted without sweeping what has lapsed: the figure is drawn on every
  # page, and a page that is not the cart has no business clearing it out.
  defp gathered(scope), do: Carts.gathered_count(scope: scope)
end
