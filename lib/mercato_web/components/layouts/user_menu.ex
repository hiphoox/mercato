defmodule MercatoWeb.Layouts.UserMenu do
  @moduledoc """
  The account dropdown in the app header.

  Renders for signed-out visitors too — the trigger is how they reach sign in,
  so hiding the menu entirely would strand them.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.Avatar
  import MercatoWeb.UI.Menu

  @doc """
  Renders the user menu.

  `current_user` is `nil` for a signed-out visitor, which swaps the account
  identity block and the row set rather than changing the menu's shape.

  `admin?` is passed in rather than derived here: whether a user reaches the
  admin area is an authorization question, answered once per request and shared
  with the sidebar, so this menu can't disagree with it.
  """
  attr :current_user, :map, default: nil
  attr :admin?, :boolean, default: false

  def user_menu(assigns) do
    assigns = assign(assigns, :display_name, display_name(assigns.current_user))

    ~H"""
    <.menu id="user-menu">
      <:trigger>
        <span class="flex items-center gap-2 h-12 md:h-14 pl-2 pr-2.5">
          <.avatar
            name={@display_name}
            src={@current_user && @current_user.avatar_url}
            size={34}
          />
          <.icon name="hero-chevron-down-micro" aria-hidden="true" class="size-3.5 text-ink-500" />
        </span>
      </:trigger>

      <div :if={@current_user} class="flex items-center gap-2.5 p-2.5 pb-3">
        <.avatar
          name={@display_name}
          src={@current_user.avatar_url}
          size={38}
        />
        <div class="min-w-0">
          <div class="flex items-center gap-1.5">
            <div class="text-body-sm font-semibold text-ink-900 dark:text-white truncate">
              {@display_name}
            </div>
            <.badge :if={@admin?} kind="featured" class="flex-none">Admin</.badge>
          </div>
          <div class="text-caption-md text-ink-500 truncate">{@current_user.email}</div>
        </div>
      </div>
      <div :if={@current_user} class="h-px bg-ink-100 dark:bg-ink-700 mx-1.5 mb-1.5"></div>

      <.menu_item
        :if={@current_user}
        role="menuitem"
        label="Profile"
        icon="hero-user"
        navigate={~p"/profile"}
      />
      <.menu_item
        :if={@current_user}
        role="menuitem"
        label="Sign out"
        icon="hero-arrow-right-start-on-rectangle"
        href={~p"/sign-out"}
        variant={:danger}
      />

      <.menu_item
        :if={!@current_user}
        role="menuitem"
        label="Sign in"
        icon="hero-arrow-right-end-on-rectangle"
        navigate={~p"/sign-in"}
      />
      <.menu_item
        :if={!@current_user}
        role="menuitem"
        label="Create account"
        icon="hero-user-plus"
        navigate={~p"/register"}
      />
    </.menu>
    """
  end

  # Presentation-only: the avatar and the identity block both need one string,
  # and a user may legitimately have no name yet (OAuth sign-up, magic link).
  defp display_name(nil), do: nil

  # Map.get/2 rather than user[:field]: `Mercato.Accounts.User` is a struct and
  # does not implement Access.
  defp display_name(user) do
    [Map.get(user, :first_name), Map.get(user, :last_name)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
    |> case do
      "" -> to_string(Map.get(user, :handle) || Map.get(user, :email))
      name -> name
    end
  end
end
