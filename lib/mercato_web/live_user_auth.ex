defmodule MercatoWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use MercatoWeb, :verified_routes

  alias AshAuthentication.Phoenix.LiveSession

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {MercatoWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, assign_admin(socket)}
    else
      {:cont, socket |> assign(:current_user, nil) |> assign(:admin?, false)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, assign_admin(socket)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  @doc """
  Gates a LiveView on admin access.

  A signed-out visitor is sent to sign-in, same as `:live_user_required`. A
  signed-in user who simply isn't an admin is sent home instead: the page is
  not theirs to see, and bouncing them to a sign-in form they've already
  completed would be nonsense.
  """
  def on_mount(:live_admin_required, params, session, socket) do
    case on_mount(:live_user_required, params, session, socket) do
      {:halt, socket} ->
        {:halt, socket}

      {:cont, socket} ->
        if socket.assigns.admin? do
          {:cont, socket}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
        end
    end
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, socket |> assign(:current_user, nil) |> assign(:admin?, false)}
    end
  end

  # Assigned on every authenticated mount, not just under /admin: the sidebar
  # shows the Admin section on every page, so every page needs the answer.
  defp assign_admin(socket) do
    assign_new(socket, :admin?, fn ->
      MercatoWeb.AdminAccess.admin?(socket.assigns.current_user)
    end)
  end
end
