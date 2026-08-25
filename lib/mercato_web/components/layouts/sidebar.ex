defmodule MercatoWeb.Layouts.Sidebar do
  @moduledoc """
  The app layout's left navigation rail.

  Only ever composed by `MercatoWeb.Layouts.app/1`, which is why it is not
  imported globally — a second sidebar on a page would be a bug, not a feature.

  Nav entries list only routes that exist. New sections are added here as their
  routes land, rather than shipping links that go nowhere.
  """
  use MercatoWeb, :html

  import MercatoWeb.UI.Menu

  @primary [
    %{label: "Home", icon: "hero-home", navigate: "/"}
  ]

  @account [
    %{label: "My listings", icon: "hero-tag", navigate: "/my-listings"},
    %{label: "Profile", icon: "hero-user", navigate: "/profile"}
  ]

  @admin [
    %{label: "Users", icon: "hero-users", navigate: "/admin/users"}
  ]

  @doc """
  Renders the sidebar.

  Collapse is CSS-driven (see the `sidebar-collapsed` variant in `app.css`), so
  this renders one markup tree that works in both states.
  """
  attr :current_path, :string, default: nil, doc: "used to mark the active entry"

  attr :admin?, :boolean,
    default: false,
    doc: "reveals the Admin section; the routes behind it are admin-gated in their own right"

  def sidebar(assigns) do
    assigns =
      assigns
      |> assign(:primary, @primary)
      |> assign(:account, @account)
      |> assign(:admin, @admin)

    ~H"""
    <%!-- The scrim only exists below lg, where the sidebar overlays the content.
          Kept in the DOM and faded, so opening and closing both animate. --%>
    <div
      id="sidebar-scrim"
      aria-hidden="true"
      phx-click={close_drawer()}
      class={[
        "lg:hidden fixed inset-0 z-45 bg-ink-900/40",
        "opacity-0 pointer-events-none transition-opacity duration-200",
        "sidebar-drawer-open:opacity-100 sidebar-drawer-open:pointer-events-auto"
      ]}
    >
    </div>

    <nav
      id="app-sidebar"
      aria-label="Main navigation"
      phx-window-keydown={close_drawer()}
      phx-key="escape"
      class={
        [
          # Below lg: an off-canvas drawer parked to the left of the viewport.
          "fixed inset-y-3 left-3 z-50 w-72 max-w-[calc(100vw-4rem)] shadow-lg",
          "-translate-x-[calc(100%+1.5rem)] sidebar-drawer-open:translate-x-0",
          "transition-transform duration-200",
          # From lg: back in flow beside the main card, and the drawer classes are undone.
          "lg:static lg:z-auto lg:inset-auto lg:max-w-none lg:translate-x-0",
          "lg:self-stretch lg:shadow-sm lg:transition-[width] lg:duration-150",
          "lg:w-58 sidebar-collapsed:w-18",
          "flex-none overflow-y-auto rounded-md bg-bg dark:bg-ink-900"
        ]
      }
    >
      <div class="flex flex-col gap-0.5 p-3">
        <.nav_entry :for={entry <- @primary} entry={entry} current_path={@current_path} />
      </div>

      <div class="h-px bg-ink-100 dark:bg-ink-700 mx-4"></div>

      <div class="flex flex-col gap-0.5 p-3">
        <div
          id="sidebar-section-you"
          class="px-3.5 pb-2 text-caption-md font-bold text-ink-500 sidebar-collapsed:hidden"
        >
          You
        </div>
        <.nav_entry :for={entry <- @account} entry={entry} current_path={@current_path} />
      </div>

      <%!-- Hiding the section is presentation, not protection: each admin route
            gates itself on `:live_admin_required`, so a non-admin who types the
            URL is still turned away. --%>
      <div :if={@admin?}>
        <div class="h-px bg-ink-100 dark:bg-ink-700 mx-4"></div>

        <div class="flex flex-col gap-0.5 p-3">
          <div
            id="sidebar-section-admin"
            class="px-3.5 pb-2 text-caption-md font-bold text-ink-500 sidebar-collapsed:hidden"
          >
            Admin
          </div>
          <.nav_entry :for={entry <- @admin} entry={entry} current_path={@current_path} />
        </div>
      </div>
    </nav>
    """
  end

  attr :entry, :map, required: true
  attr :current_path, :string, required: true

  defp nav_entry(assigns) do
    ~H"""
    <.menu_item
      label={@entry.label}
      icon={@entry.icon}
      navigate={@entry.navigate}
      active={@current_path == @entry.navigate}
      collapsed={:responsive}
      phx-click={close_drawer()}
    />
    """
  end

  # Drawer state lives on <html>, next to the collapse and theme attributes, so one
  # pre-paint script owns every piece of client-only chrome state.
  defp close_drawer, do: JS.set_attribute({"data-sidebar-drawer", "closed"}, to: "html")
end
