defmodule MercatoWeb.Layouts.AppHeader do
  @moduledoc """
  The app layout's top bar: sidebar toggle, brand, search, cart and the
  user menu.

  Only ever composed by `MercatoWeb.Layouts.app/1`.
  """
  use MercatoWeb, :html

  import MercatoWeb.Layouts.UserMenu

  @doc """
  Renders the app header.

  The toggle and cart are signed-in only: there is no sidebar to toggle and no
  cart to open when nobody is signed in.
  """
  attr :current_user, :map, default: nil

  def app_header(assigns) do
    ~H"""
    <%!-- Below md the bar wraps to two rows: controls on top, search underneath.
          `order` does the rearranging, so the DOM keeps its reading order. --%>
    <header class={[
      "flex-none z-40 flex items-center flex-wrap md:flex-nowrap",
      "gap-2 md:gap-3 p-2.5 px-3 md:p-3 md:px-4 bg-bg-2 dark:bg-ink-900"
    ]}>
      <div class={[
        "flex-none flex items-center gap-2 overflow-hidden",
        "lg:w-58 sidebar-collapsed:w-18 lg:transition-[width] lg:duration-150"
      ]}>
        <button
          :if={@current_user}
          type="button"
          id="sidebar-toggle"
          phx-hook=".SidebarToggle"
          aria-label="Toggle navigation"
          aria-controls="app-sidebar"
          class={[
            "flex-none flex items-center justify-center size-11 rounded-md cursor-pointer",
            "text-ink-700 dark:text-ink-100 transition-colors hover:bg-ink-100 dark:hover:bg-ink-700",
            "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
          ]}
        >
          <.icon name="hero-bars-3" aria-hidden="true" class="size-5" />
        </button>

        <.link
          id="app-brand"
          navigate={~p"/"}
          class="flex items-center gap-2 min-w-0 no-underline sidebar-collapsed:hidden"
        >
          <img src={~p"/images/mercato-logo.png"} width="28" height="28" alt="" />
          <span class="text-title-lg font-extrabold text-ink-900 dark:text-white truncate">
            Mercato
          </span>
        </.link>
      </div>

      <%!-- `grow basis-full`, never `flex-1`: the shorthand would set flex-basis to 0
            and the search would sit on the first row instead of forcing the wrap. --%>
      <div class={[
        "order-4 basis-full md:order-none md:basis-0 grow min-w-0",
        "flex items-center gap-2.5 h-12 md:h-14 px-3.5 md:px-4.5",
        "rounded-md bg-bg dark:bg-ink-700 shadow-sm"
      ]}>
        <.icon name="hero-magnifying-glass" aria-hidden="true" class="size-4.5 text-ink-500" />
        <input
          type="search"
          id="app-search"
          name="q"
          aria-label="Search listings"
          placeholder="Search listings, categories, sellers"
          autocomplete="off"
          class={[
            "flex-1 min-w-0 border-none bg-transparent outline-none",
            "text-body-md text-ink-900 dark:text-white placeholder:text-ink-500"
          ]}
        />
      </div>

      <.link
        :if={@current_user}
        id="app-cart"
        navigate={~p"/"}
        aria-label="Cart"
        class={[
          "order-3 flex-none flex items-center justify-center size-12 md:size-14 rounded-md no-underline",
          "bg-bg dark:bg-ink-700 shadow-sm transition-[filter] hover:brightness-97",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
        ]}
      >
        <.icon
          name="hero-shopping-cart"
          aria-hidden="true"
          class="size-4.5 text-ink-900 dark:text-white"
        />
      </.link>

      <%!-- `ml-auto` on the wrapped layout pins the account control to the right of
            the first row, with the cart beside it and search on the row below. --%>
      <div class="order-2 ml-auto md:order-none md:ml-0">
        <.user_menu current_user={@current_user} />
      </div>
    </header>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".SidebarToggle">
      export default {
        mounted() {
          const root = document.documentElement

          // Asks CSS which regime is live instead of restating a breakpoint here. The
          // values come from --sidebar-mode in app.css, which is driven by the theme's
          // own --breakpoint-* tokens, so retuning the theme moves this too.
          const mode = () =>
            getComputedStyle(root).getPropertyValue("--sidebar-mode").trim()

          this.el.addEventListener("click", () => {
            const current = mode()

            if (current === "drawer") {
              const open = root.getAttribute("data-sidebar-drawer") !== "open"
              root.setAttribute("data-sidebar-drawer", open ? "open" : "closed")
              return
            }

            // The stored preference is deliberately tri-state. Absent means "whatever
            // this width defaults to", so the toggle has to resolve that default before
            // it can invert it — otherwise the first click on a small laptop, where the
            // rail is already showing, would appear to do nothing.
            const stored = root.getAttribute("data-sidebar-collapsed")
            const collapsed = stored === null ? current === "rail" : stored === "true"

            root.setAttribute("data-sidebar-collapsed", String(!collapsed))
            localStorage.setItem("mercato:sidebar-collapsed", String(!collapsed))
          })
        }
      }
    </script>
    """
  end
end
