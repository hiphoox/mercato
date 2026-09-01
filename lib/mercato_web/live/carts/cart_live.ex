defmodule MercatoWeb.Carts.CartLive do
  @moduledoc """
  What the buyer has gathered but not yet bought.

  A page rather than a drawer: a cart is worth an address, and the components
  it is built from are shaped so a drawer can render the same groups and rows
  later without either of them changing.

  Open to a visitor with no account: a cart is gathered before it is bought,
  and what is gathered belongs to whoever gathered it, account or not.

  Nothing here is agreed. Prices are read off the listings as they stand now,
  so a seller repricing changes what the cart shows — which is the point, and
  the opposite of an order, where the price is copied at the moment of purchase.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Carts.CartGroup
  import MercatoWeb.Carts.CartLine
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.EmptyState

  alias Mercato.Carts

  on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(_params, _session, socket) do
    # The first, static render shows the shape of a grouped cart rather than a
    # spinner, so the split by seller is legible before the data lands.
    {:ok,
     if connected?(socket) do
       socket |> assign(:loading, false) |> load_cart()
     else
       socket |> assign(:loading, true) |> assign(:lines, []) |> assign(:groups, [])
     end}
  end

  defp load_cart(socket) do
    lines = Carts.list_cart!(scope: socket.assigns.current_scope)

    socket
    |> assign(:lines, lines)
    |> assign(:groups, Carts.group_by_seller(lines))
    |> assign(:cart_total, Carts.cart_total(lines))
  end

  @impl true
  def handle_event("set_quantity", %{"id" => id, "quantity" => quantity}, socket) do
    with %{} = line <- Enum.find(socket.assigns.lines, &(&1.id == id)),
         {:ok, _changed} <-
           Carts.set_cart_quantity(line, %{quantity: String.to_integer(quantity)},
             scope: socket.assigns.current_scope
           ) do
      {:noreply, load_cart(socket)}
    else
      # Almost always a line that left the cart between this page being drawn
      # and the control being pressed: reading the cart again says so better
      # than a message about a line that is no longer there.
      _refused ->
        {:noreply,
         socket
         |> load_cart()
         |> put_flash(:error, gettext("That quantity could not be changed."))}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    with %{} = line <- Enum.find(socket.assigns.lines, &(&1.id == id)),
         :ok <- Carts.remove_from_cart(line, scope: socket.assigns.current_scope) do
      {:noreply,
       socket
       |> load_cart()
       |> put_flash(:info, gettext("“%{title}” is out of your cart.", title: line.listing.title))}
    else
      _refused ->
        {:noreply,
         socket
         |> load_cart()
         |> put_flash(:error, gettext("That line could not be removed."))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/cart"}
    >
      <div id="cart" class="flex flex-col gap-6">
        <.breadcrumb items={[
          %{label: gettext("Home"), navigate: ~p"/"},
          %{label: gettext("Cart")}
        ]} />

        <.header>
          {gettext("Cart")}
          <:subtitle :if={!@loading}>{subtitle(@lines, @groups)}</:subtitle>
        </.header>
      </div>

      <%!-- The cart itself is a single column of cards, so it is centred and
            capped rather than stretched across a wide screen. The breadcrumb and
            the heading above it stay with the page, as they do on the account
            page. --%>
      <div class="flex flex-col gap-6 w-full max-w-[720px] mx-auto py-8">
        <.cart_skeleton :if={@loading} />

        <%!-- Only where there is something to disambiguate: with one group there
              is no combined total anybody could mistake for one purchase. --%>
        <div
          :if={length(@groups) > 1}
          id="cart-split-note"
          class="flex items-start gap-2.5 text-caption-lg text-ink-700 dark:text-ink-100 text-pretty"
        >
          <.icon name="hero-arrows-right-left" aria-hidden="true" class="size-4.5 flex-none mt-px" />
          {split_note(@groups)}
        </div>

        <div :if={@groups != []} class="flex flex-col gap-4">
          <.cart_group :for={group <- @groups} group={group}>
            <.cart_line
              :for={line <- group.lines}
              line={line}
              total={Carts.line_total(line)}
            />
          </.cart_group>
        </div>

        <div
          :if={@groups != []}
          id="cart-total"
          class="p-3.5 rounded-md border border-dashed border-ink-300 dark:border-ink-700"
        >
          <div class="flex items-baseline justify-between gap-3">
            <span class="text-body-sm font-semibold text-ink-700 dark:text-ink-100">
              {gettext("Everything in the cart")}
            </span>
            <span class="text-body-md font-extrabold tabular-nums text-ink-900 dark:text-white">
              {@cart_total}
            </span>
          </div>
          <p class="mt-1.5 m-0 text-caption-md text-ink-500 text-pretty">
            {grand_note(@groups)}
          </p>
        </div>

        <.empty_state
          :if={!@loading and @groups == []}
          id="cart-empty"
          icon="hero-shopping-cart"
          headline={gettext("Nothing in your cart yet")}
          description={
            gettext(
              "Most things here are one of a kind, so adding early is the safer move — a cart holds nothing back from anyone else, but it keeps what you found in one place."
            )
          }
        >
          <:actions>
            <.button id="cart-browse" size="md" navigate={~p"/"}>
              <.icon name="hero-squares-2x2" aria-hidden="true" class="size-4.5" />
              {gettext("Browse listings")}
            </.button>
          </:actions>
        </.empty_state>
      </div>
    </Layouts.app>
    """
  end

  # The shape of a grouped cart, not a spinner: two seller cards with rows and
  # a checkout button, so what is arriving is legible while it arrives.
  defp cart_skeleton(assigns) do
    assigns = assign(assigns, :cards, [2, 1])

    ~H"""
    <div id="cart-skeleton" aria-hidden="true" class="flex flex-col gap-4">
      <div
        :for={{rows, index} <- Enum.with_index(@cards)}
        class={[
          "flex flex-col gap-3.5 p-5 md:p-8 animate-pulse",
          "rounded-lg border border-ink-100 dark:border-ink-700 bg-bg dark:bg-ink-900"
        ]}
      >
        <div class="flex items-center gap-3">
          <div class="size-9 flex-none rounded-full bg-ink-100 dark:bg-ink-700"></div>
          <div class="h-3 w-35 rounded-sm bg-ink-100 dark:bg-ink-700"></div>
        </div>
        <div :for={row <- 1..rows} class="flex gap-3.5" id={"cart-skeleton-#{index}-#{row}"}>
          <div class="size-21 flex-none rounded-md bg-ink-100 dark:bg-ink-700"></div>
          <div class="flex-1 flex flex-col gap-2 pt-1">
            <div class="h-3 w-4/5 rounded-sm bg-ink-100 dark:bg-ink-700"></div>
            <div class="h-3 w-2/5 rounded-sm bg-ink-100 dark:bg-ink-700"></div>
          </div>
        </div>
        <div class="h-13 rounded-md bg-ink-100 dark:bg-ink-700"></div>
      </div>
    </div>
    """
  end

  defp subtitle([], _groups), do: gettext("Nothing gathered yet.")

  defp subtitle(lines, groups) do
    gettext("%{items} from %{sellers}",
      items: ngettext("1 item", "%{count} items", Carts.item_count(lines)),
      sellers: ngettext("1 seller", "%{count} sellers", length(groups))
    )
  end

  defp split_note(groups) do
    gettext(
      "%{count} sellers, %{count} separate purchases. Each one is paid for and delivered on its own — there is no single combined order.",
      count: length(groups)
    )
  end

  defp grand_note([_only_one]) do
    gettext("One purchase, from one seller.")
  end

  defp grand_note(groups) do
    gettext(
      "Split across %{count} payments, one per seller. Nothing is charged until you complete each one.",
      count: length(groups)
    )
  end
end
