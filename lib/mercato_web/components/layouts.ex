defmodule MercatoWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MercatoWeb, :html

  import MercatoWeb.Layouts.AppHeader
  import MercatoWeb.Layouts.Sidebar

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders the app layout: header, sidebar, and the main content card.

  One layout serves signed-in and signed-out visitors. Signing out doesn't
  change the layout's shape — it removes the parts that need an account (the
  sidebar, its toggle, the cart) and swaps the user menu's contents.

  ## Examples

      <Layouts.app flash={@flash} current_user={@current_user} current_path={~p"/profile"}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :current_user, :map, default: nil, doc: "drives the sidebar, cart and user menu"
  attr :current_path, :string, default: nil, doc: "used to mark the active sidebar entry"

  attr :admin?, :boolean,
    default: false,
    doc: "reveals the sidebar's Admin section; assigned by `MercatoWeb.LiveUserAuth`"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%!-- h-screen + overflow-hidden, so the page itself never scrolls: the sidebar
          and the main column each get their own scrollbar below. --%>
    <div class="h-screen overflow-hidden flex flex-col font-sans bg-bg-2 dark:bg-ink-900 text-ink-900 dark:text-white">
      <.app_header current_user={@current_user} admin?={@admin?} />

      <%!-- The gap is lg-only: below that the sidebar is a fixed drawer and takes no
            space in this row, so a gap would just indent the main card against nothing. --%>
      <div class="flex-1 min-h-0 flex items-stretch lg:gap-3 px-3 pb-3 md:px-4 md:pb-4">
        <.sidebar :if={@current_user} current_path={@current_path} admin?={@admin?} />

        <main class={[
          "flex-1 min-w-0 overflow-y-auto rounded-md bg-bg dark:bg-ink-900 shadow-sm",
          "px-4 pt-5 pb-8 md:px-8 md:pt-7 md:pb-12"
        ]}>
          {render_slot(@inner_block)}
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border-2 border-ink-100 dark:border-ink-700 bg-ink-100 dark:bg-ink-700 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-ink-100 dark:border-ink-700 bg-white dark:bg-ink-900 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
