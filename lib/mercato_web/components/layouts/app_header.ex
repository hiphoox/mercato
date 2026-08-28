defmodule MercatoWeb.Layouts.AppHeader do
  @moduledoc """
  The app layout's top bar: sidebar toggle, brand, search, the call to sell,
  cart and the user menu.

  Only ever composed by `MercatoWeb.Layouts.app/1`.
  """
  use MercatoWeb, :html

  import MercatoWeb.Layouts.UserMenu

  @doc """
  Renders the app header.

  The toggle, the call to sell and the cart are signed-in only: there is no
  sidebar to toggle, nothing to list under, and no cart to open when nobody is
  signed in.
  """
  attr :current_scope, Mercato.Accounts.Scope, required: true

  attr :query, :string,
    default: nil,
    doc: "the search term in force, so the box still reads it after a search"

  attr :categories, :list,
    default: [],
    doc: "the catalog the scope selector offers; assigned by `MercatoWeb.SearchScope`"

  attr :category, :string,
    default: nil,
    doc: "the slug of the scope in force, so the selector still reads it after a search"

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
          :if={@current_scope.user}
          type="button"
          id="sidebar-toggle"
          phx-hook="SidebarToggle"
          aria-label={gettext("Toggle navigation")}
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
      <%!-- A plain GET form rather than a LiveView event: the header is drawn on
            every page, and only the browse page knows what to do with a search
            term. Submitting navigates there from wherever the visitor is, which
            no per-page event handler could do. --%>
      <form
        method="get"
        action={~p"/"}
        role="search"
        class={[
          "order-4 basis-full md:order-none md:basis-0 grow min-w-0",
          "flex items-center gap-2.5 h-12 md:h-14 px-3.5 md:px-4.5",
          "rounded-md bg-bg dark:bg-ink-700 shadow-sm"
        ]}
      >
        <span
          :if={@categories != []}
          class="relative flex-none flex items-center self-stretch -ml-3.5 md:-ml-4.5"
        >
          <select
            id="app-search-scope"
            name="category"
            aria-label={gettext("Search within")}
            class={[
              "max-w-36 md:max-w-44 truncate cursor-pointer appearance-none",
              "h-full pl-3.5 md:pl-4.5 pr-8 rounded-l-md border-none outline-none",
              "text-body-sm font-semibold",
              "bg-ink-100 text-ink-900 dark:bg-ink-900 dark:text-white",
              "transition-[filter] hover:brightness-95",
              "focus-visible:ring-3 focus-visible:ring-primary-100"
            ]}
          >
            <option value="" selected={@category in [nil, ""]}>{gettext("All categories")}</option>
            <option
              :for={category <- @categories}
              value={category.slug}
              selected={category.slug == @category}
            >
              {category.name}
            </option>
          </select>
          <.icon
            name="hero-chevron-down-micro"
            aria-hidden="true"
            class="pointer-events-none absolute right-2.5 size-3.5 text-ink-500 dark:text-ink-100"
          />
        </span>

        <input
          type="search"
          id="app-search"
          name="q"
          value={@query}
          aria-label={gettext("Search listings")}
          placeholder={gettext("Search listings, categories, sellers")}
          autocomplete="off"
          class={[
            "flex-1 min-w-0 border-none bg-transparent outline-none",
            "text-body-md text-ink-900 dark:text-white placeholder:text-ink-500"
          ]}
        />

        <%!-- The magnifier is the submit control, so the form is reachable
              without a keyboard. --%>
        <button
          type="submit"
          aria-label={gettext("Search")}
          class="flex-none flex items-center cursor-pointer focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100 rounded-sm"
        >
          <.icon name="hero-magnifying-glass" aria-hidden="true" class="size-4.5 text-ink-500" />
        </button>
      </form>

      <%!-- The filled action in the bar. Every account here both buys and
            sells, so listing something is not a minority errand tucked into a
            utility strip — it is the thing the marketplace is for.

            The layout lives on the wrapper rather than on the button: a class
            given to the button replaces its variant outright, and restating
            the fill here is how a vocabulary drifts. --%>
      <div :if={@current_scope.user} class="order-1 md:order-none flex-none">
        <.button id="sell-cta" navigate={~p"/listings/new"} aria-label={gettext("Sell an item")}>
          <.icon name="hero-tag" aria-hidden="true" class="size-4.5" />
          <%!-- The span carries the responsive display rather than the button, whose
                own `inline-flex` is an unprefixed display utility and would race
                `hidden` in Tailwind's output. Below md the bar is already wrapping,
                so the label goes and the aria-label speaks for it. --%>
          <span class="hidden md:inline">{gettext("Sell")}</span>
        </.button>
      </div>

      <.link
        :if={@current_scope.user}
        id="app-cart"
        navigate={~p"/"}
        aria-label={gettext("Cart")}
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
      <div class="order-2 ml-auto md:order-none md:ml-0 flex items-center gap-2">
        <%!-- The span carries the responsive display, not the badge: `hidden` and the
              badge's own `inline-flex` are both unprefixed display utilities, so which
              one won would depend on Tailwind's output order rather than on intent.
              Below md the header is already wrapping two rows, and the same badge sits
              in the account menu, so the indicator is dropped rather than crowded in. --%>
        <span class="hidden md:inline">
          <.badge :if={@current_scope.admin?} id="admin-indicator" kind="featured">
            {gettext("Admin")}
          </.badge>
        </span>
        <.user_menu current_scope={@current_scope} />
      </div>
    </header>
    """
  end
end
