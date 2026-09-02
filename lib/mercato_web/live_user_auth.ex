defmodule MercatoWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use MercatoWeb, :verified_routes

  alias AshAuthentication.Phoenix.LiveSession
  alias Mercato.Accounts.Scope
  alias MercatoWeb.GuestToken

  @doc """
  Mount hooks, selected by name:

    * `:current_user` — assigns `:current_scope`, requiring no account
    * `:live_user_optional` — the same
    * `:live_user_required` — sends a signed-out visitor to sign-in
    * `:live_admin_required` — the same, and sends a non-admin home
    * `:live_no_user` — sends a signed-in user home

      on_mount {MercatoWeb.LiveUserAuth, :live_admin_required}
  """
  def on_mount(hook, params, session, socket)

  def on_mount(:current_user, _params, session, socket) do
    {:cont, socket |> LiveSession.assign_new_resources(session) |> assign_scope(session)}
  end

  def on_mount(:live_user_optional, _params, session, socket) do
    {:cont, assign_scope(socket, session)}
  end

  def on_mount(:live_user_required, _params, session, socket) do
    if socket.assigns[:current_user] do
      {:cont, assign_scope(socket, session)}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  # Home rather than sign-in for a non-admin: the page is not theirs to see,
  # and bouncing them to a form they have already completed would be nonsense.
  def on_mount(:live_admin_required, params, session, socket) do
    case on_mount(:live_user_required, params, session, socket) do
      {:halt, socket} ->
        {:halt, socket}

      {:cont, socket} ->
        if socket.assigns.current_scope.admin? do
          {:cont, socket}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
        end
    end
  end

  def on_mount(:live_no_user, _params, session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign_scope(socket, session)}
    end
  end

  # Every hook ends here, so a mount always leaves the same shape behind
  # whichever way it got there. The guest token comes with it, so a visitor
  # with no account is still somebody a cart can belong to.
  defp assign_scope(socket, session) do
    assign_new(socket, :current_scope, fn ->
      Scope.for_user(socket.assigns[:current_user], GuestToken.token(session))
    end)
  end
end
