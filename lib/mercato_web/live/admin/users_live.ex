defmodule MercatoWeb.Admin.UsersLive do
  @moduledoc """
  Admin listing of every account on the platform.

  Search, status filter, paging, and a per-row actions menu that moves an
  account between statuses or deletes it outright.

  Filter state lives in the query string rather than in socket assigns alone, so
  a filtered listing is a shareable URL and the browser's back button walks back
  through filters the way a user expects.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Avatar
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.Menu
  import MercatoWeb.UI.Pager

  alias Mercato.Accounts

  on_mount {MercatoWeb.LiveUserAuth, :live_admin_required}

  @page_size 20

  # One row per status: how it reads as a badge, and — for the statuses an admin
  # may move an account *into* — how it reads as a menu item. `:deleted` carries
  # no action: deletion is terminal and erases the account, so it gets its own
  # menu item rather than appearing as just another status toggle.
  @status_values [:active, :restricted, :banned, :deleted]

  # Built per render rather than held as a module attribute: wording baked in at
  # compile time is invisible to translation extraction. Each confirmation is a
  # whole sentence naming the account, so a translator can move the name.
  defp statuses do
    [
      %{
        value: :active,
        label: gettext("Active"),
        badge: "verified",
        action: gettext("Reactivate account"),
        icon: "hero-check-circle",
        variant: :default,
        confirm: nil
      },
      %{
        value: :restricted,
        label: gettext("Restricted"),
        badge: "warning",
        action: gettext("Restrict access"),
        icon: "hero-exclamation-triangle",
        variant: :default,
        confirm:
          &gettext(
            "%{name} will keep their sign-in but lose the actions a restriction blocks.",
            name: &1
          )
      },
      %{
        value: :banned,
        label: gettext("Banned"),
        badge: "danger",
        action: gettext("Ban account"),
        icon: "hero-no-symbol",
        variant: :danger,
        confirm:
          &gettext(
            "%{name} will be signed out of the platform and unable to sign back in.",
            name: &1
          )
      },
      %{
        value: :deleted,
        label: gettext("Deleted"),
        badge: "neutral",
        action: nil,
        icon: nil,
        variant: :default,
        confirm: nil
      }
    ]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_size, @page_size)
     |> assign_can_change_status()
     |> load_status_counts()}
  end

  # Answered once, not per row: both policies guarding `change_status` come down
  # to whether the actor holds `user:update` — the self-update clause on the
  # `:update` policy can only widen the first of the two — so the answer is the
  # same for every account on the page, and the check costs a query each time.
  defp assign_can_change_status(socket) do
    actor = socket.assigns.current_scope.user

    assign(socket, :can_change_status?, Accounts.can_change_status?(actor, actor, :active))
  end

  @impl true
  def handle_params(params, _uri, socket) do
    query = params |> Map.get("query", "") |> to_string()
    status = parse_status(params["status"])
    page = parse_page(params["page"])

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:status, status)
     |> assign(:page, page)
     |> load_accounts()}
  end

  # Derived from the status list rather than a literal list of strings, so a new
  # status is recognised in the URL and in an action event without a second
  # place to update.
  @status_strings Map.new(@status_values, &{to_string(&1), &1})

  defp parse_status(value), do: Map.get(@status_strings, to_string(value))

  defp parse_page(value) do
    case Integer.parse(to_string(value)) do
      {page, ""} when page > 0 -> page
      _ -> 1
    end
  end

  # Asked of another account rather than the actor: the delete policy also
  # authorises self-deletion, so checking the actor against themselves would
  # answer "yes" for an admin who holds no `user:delete` at all. Every non-self
  # row gives the same answer, so one of them settles the whole page.
  defp assign_can_delete_accounts(socket) do
    %{current_scope: %{user: actor}, accounts: accounts} = socket.assigns

    can? =
      case Enum.find(accounts, &(&1.id != actor.id)) do
        nil -> false
        account -> Accounts.can_delete_account?(actor, account)
      end

    assign(socket, :can_delete_accounts?, can?)
  end

  defp load_accounts(socket) do
    %{query: query, status: status, page: page, current_scope: %{user: actor}} = socket.assigns

    {:ok, results} =
      Accounts.list_accounts(%{query: query, status: status},
        actor: actor,
        page: [limit: @page_size, offset: (page - 1) * @page_size, count: true]
      )

    total = results.count || 0
    last_page = max(1, ceil(total / @page_size))

    socket
    |> assign(:accounts, results.results)
    |> assign(:total, total)
    |> assign(:last_page, last_page)
    |> assign_can_delete_accounts()
  end

  # Counted at mount and after a status change, never on a filter change: the
  # chips describe the platform, not the current search. A chip shifting while
  # the user types would make it useless as a starting point for narrowing down.
  defp load_status_counts(socket) do
    actor = socket.assigns.current_scope.user

    counts =
      Map.new(@status_values, fn status ->
        {:ok, page} =
          Accounts.list_accounts(%{status: status},
            actor: actor,
            page: [limit: 1, count: true]
          )

        {status, page.count || 0}
      end)

    assign(socket, :status_counts, Map.put(counts, :all, counts |> Map.values() |> Enum.sum()))
  end

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply, apply_filters(socket, query: Map.get(params, "query", ""), page: 1)}
  end

  def handle_event("filter_status", %{"status" => "all"}, socket) do
    {:noreply, apply_filters(socket, status: nil, page: 1)}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, apply_filters(socket, status: parse_status(status), page: 1)}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, apply_filters(socket, query: "", status: nil, page: 1)}
  end

  def handle_event("change_status", %{"id" => id, "status" => status}, socket) do
    account = Enum.find(socket.assigns.accounts, &(&1.id == id))

    case change_status(socket, account, parse_status(status)) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("%{name} is now %{status}.",
             name: display_name(updated),
             status: status_label(updated.status)
           )
         )
         |> load_status_counts()
         |> load_accounts()}

      :error ->
        {:noreply,
         put_flash(socket, :error, gettext("That account's status could not be changed."))}
    end
  end

  def handle_event("delete_account", %{"id" => id}, socket) do
    account = Enum.find(socket.assigns.accounts, &(&1.id == id))

    case delete_account(socket, account) do
      {:ok, name} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{name}'s account has been deleted.", name: name))
         |> load_status_counts()
         |> load_accounts()}

      :error ->
        {:noreply, put_flash(socket, :error, gettext("That account could not be deleted."))}
    end
  end

  # Same re-check as change_status below, for the same reason: the delete item
  # is withheld from the admin's own row, from another admin, and from an
  # account already deleted, and a hidden control is not an absent one.
  defp delete_account(socket, account) when is_map(account) do
    if deletable?(socket.assigns, account) do
      # Captured first: after deletion the name is erased, and the flash should
      # say whose account went.
      name = display_name(account)

      case Accounts.delete_account(account, actor: socket.assigns.current_scope.user) do
        :ok -> {:ok, name}
        {:error, _} -> :error
      end
    else
      :error
    end
  end

  defp delete_account(_socket, _account), do: :error

  # The row that raised the event is re-checked here rather than trusted: the
  # menu is hidden for the admin's own row and for a deleted account, but a
  # hidden control is not an absent one, and a crafted event must not slip past
  # a rule the markup enforces.
  defp change_status(socket, account, status)
       when is_map(account) and status not in [nil, :deleted] do
    if actionable?(socket.assigns, account) do
      case Accounts.change_status(account, status, %{}, actor: socket.assigns.current_scope.user) do
        {:ok, updated} -> {:ok, updated}
        {:error, _} -> :error
      end
    else
      :error
    end
  end

  defp change_status(_socket, _account, _status), do: :error

  defp actionable?(%{can_change_status?: false}, _account), do: false

  defp actionable?(%{current_scope: %{user: %{id: actor_id}}}, account) do
    account.id != actor_id and not deleted?(account)
  end

  # Deletion is terminal and erases the account, so the dashboard only ever
  # offers it for an ordinary account someone else holds. An admin leaving the
  # platform deletes their own account from the profile page, where they are
  # the one bearing the consequence.
  defp deletable?(%{can_delete_accounts?: false}, _account), do: false

  defp deletable?(assigns, account) do
    actionable?(assigns, account) and not account.admin?
  end

  defp apply_filters(socket, overrides) do
    current = [
      query: socket.assigns.query,
      status: socket.assigns.status,
      page: socket.assigns.page
    ]

    push_patch(socket, to: users_path(Keyword.merge(current, overrides)))
  end

  # Built rather than interpolated, so the unfiltered listing on its first page
  # is plainly `/admin/users` rather than trailing an empty query string.
  defp users_path(opts) do
    case filter_params(opts) do
      [] -> ~p"/admin/users"
      params -> ~p"/admin/users?#{params}"
    end
  end

  # Only non-default values reach the URL, so the unfiltered listing stays a
  # clean `/admin/users` rather than a string of empty parameters.
  defp filter_params(opts) do
    []
    |> maybe_param("query", opts[:query], &(&1 not in [nil, ""]))
    |> maybe_param("status", opts[:status], &(&1 != nil))
    |> maybe_param("page", opts[:page], &(&1 > 1))
    |> Enum.reverse()
  end

  defp maybe_param(params, key, value, keep?) do
    if keep?.(value), do: [{key, to_string(value)} | params], else: params
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      cart_count={@cart_count}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/admin/users"}
    >
      <div class="flex flex-col gap-6">
        <.breadcrumb items={[%{label: gettext("Admin")}, %{label: gettext("Users")}]} />

        <.header>
          {gettext("Users")}
          <:subtitle>{gettext("Review and manage every account on the platform.")}</:subtitle>
        </.header>

        <div class="flex flex-col md:flex-row md:items-start gap-4 md:gap-6">
          <form
            id="user-filters"
            phx-change="filter"
            phx-submit="filter"
            class="w-full md:w-80 md:flex-none"
          >
            <.input
              type="search"
              name="query"
              value={@query}
              label={gettext("Search users")}
              placeholder={gettext("Name, @handle, or email")}
              phx-debounce="300"
            />
          </form>

          <div class="flex flex-col gap-1.5">
            <span id="status-filter-label" class="text-caption-lg font-semibold text-ink-700">
              {gettext("Status")}
            </span>
            <div
              role="group"
              aria-labelledby="status-filter-label"
              class="flex flex-wrap gap-2 pb-1"
            >
              <.filter_chip
                id="status-chip-all"
                label={gettext("All (%{count})", count: @status_counts.all)}
                selected={is_nil(@status)}
                phx-click="filter_status"
                phx-value-status="all"
              />
              <.filter_chip
                :for={status <- statuses()}
                id={"status-chip-#{status.value}"}
                label={
                  gettext("%{status} (%{count})",
                    status: status.label,
                    count: @status_counts[status.value]
                  )
                }
                selected={@status == status.value}
                phx-click="filter_status"
                phx-value-status={status.value}
              />
            </div>
          </div>
        </div>

        <div
          :if={filtered?(@query, @status)}
          class="flex flex-wrap items-center gap-2 px-3.5 py-3 rounded-md bg-bg-2 dark:bg-ink-700 border border-ink-100 dark:border-ink-700"
        >
          <span class="text-caption-lg font-semibold text-ink-500">{gettext("Applied")}</span>
          <.filter_chip
            :if={@query != ""}
            id="remove-query-filter"
            label={gettext("Search: %{query}", query: @query)}
            removable
            phx-click="filter_status"
            phx-value-status={@status || "all"}
          />
          <.filter_chip
            :if={@status}
            id="remove-status-filter"
            label={gettext("Status: %{status}", status: status_label(@status))}
            removable
            phx-click="filter_status"
            phx-value-status="all"
          />
          <button
            id="clear-filters"
            type="button"
            phx-click="clear_filters"
            class="ml-1 px-1.5 py-1 text-body-sm font-semibold text-primary-700 hover:text-primary-600 underline cursor-pointer"
          >
            {gettext("Clear filters")}
          </button>
        </div>

        <div
          :if={@accounts == [] and not filtered?(@query, @status)}
          class="py-14 px-6 text-center border border-ink-100 dark:border-ink-700 rounded-lg"
        >
          <p class="text-body-lg text-ink-500">
            {gettext("No accounts exist on this platform yet.")}
          </p>
        </div>

        <div
          :if={@accounts == [] and filtered?(@query, @status)}
          class="flex flex-col items-center gap-3.5 py-12 px-6 border border-ink-100 dark:border-ink-700 rounded-lg"
        >
          <.icon name="hero-magnifying-glass" class="size-8 text-ink-300" />
          <p class="max-w-[44ch] text-center text-body-md text-ink-700">
            {gettext("No accounts match %{filters}.", filters: applied_summary(@query, @status))}
          </p>
        </div>

        <%!-- Table and card list are two renderings of one listing, so they share a
              container and a single set of pagination controls. From md up the
              container is the bordered card the table sits in; below that it is
              transparent and each row card carries its own border. --%>
        <div
          :if={@accounts != []}
          class="md:border md:border-ink-100 md:dark:border-ink-700 md:rounded-lg md:bg-white md:dark:bg-ink-900"
        >
          <div class="hidden md:block max-h-[min(58vh,520px)] overflow-y-auto rounded-t-lg">
            <.table
              id="users"
              rows={@accounts}
              caption={gettext("User accounts with status and last activity")}
              row_id={&"user-#{&1.id}"}
              row_class={&dimmed/1}
            >
              <:col :let={account} label={gettext("User")} row_header>
                <.identity account={account} size={40} />
              </:col>
              <:col
                :let={account}
                label={gettext("Email")}
                class="hidden xl:table-cell"
                cell_class={&["break-words", email_tone(&1)]}
              >
                {email(account)}
              </:col>
              <:col :let={account} label={gettext("Status")}>
                <.badge kind={status_badge(account.status)}>{status_label(account.status)}</.badge>
              </:col>
              <:col :let={account} label={gettext("Role")} cell_class="whitespace-nowrap">
                {role_label(account)}
              </:col>
              <:col
                :let={account}
                label={gettext("Last active")}
                cell_class="whitespace-nowrap text-ink-500"
              >
                {last_active(account)}
              </:col>
              <:action :let={account}>
                <.row_actions
                  account={account}
                  actionable={actionable?(assigns, account)}
                  deletable={deletable?(assigns, account)}
                />
              </:action>
            </.table>
          </div>

          <div class="md:hidden flex flex-col gap-3">
            <div
              :for={account <- @accounts}
              id={"user-card-#{account.id}"}
              class={[
                "flex flex-col gap-3.5 p-4 rounded-lg border border-ink-100 dark:border-ink-700",
                "bg-white dark:bg-ink-900",
                dimmed(account)
              ]}
            >
              <div class="flex items-start justify-between gap-2">
                <.identity account={account} size={44} />
                <.row_actions
                  account={account}
                  actionable={actionable?(assigns, account)}
                  deletable={deletable?(assigns, account)}
                  prefix="card-"
                />
              </div>

              <dl class="flex flex-col gap-2 text-body-sm text-ink-700 dark:text-ink-100">
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">{gettext("Email")}</dt>
                  <dd class={["min-w-0 break-words", email_tone(account)]}>{email(account)}</dd>
                </div>
                <div class="flex items-center gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">{gettext("Status")}</dt>
                  <dd>
                    <.badge kind={status_badge(account.status)}>
                      {status_label(account.status)}
                    </.badge>
                  </dd>
                </div>
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">{gettext("Role")}</dt>
                  <dd>{role_label(account)}</dd>
                </div>
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">{gettext("Last active")}</dt>
                  <dd>{last_active(account)}</dd>
                </div>
              </dl>
            </div>
          </div>

          <%!-- The same control the browse grid pages with: an admin walking a
                table and a buyer walking a shelf are doing the same thing. --%>
          <.pager
            page={@page}
            pages={@last_page}
            path={&users_path(query: @query, status: @status, page: &1)}
            total={@total}
            page_size={@page_size}
            class={[
              "pt-4 md:px-4 md:pt-3 md:pb-3",
              "md:border-t md:border-ink-100 md:dark:border-ink-700"
            ]}
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  # The per-row actions menu.
  #
  # Rendered twice per account — once in the table, once in the card list — so the
  # ids are prefixed to keep them unique across the two renderings that are both
  # in the DOM at any width.
  attr :account, :map, required: true
  attr :actionable, :boolean, required: true
  attr :deletable, :boolean, required: true
  attr :prefix, :string, default: ""

  defp row_actions(assigns) do
    ~H"""
    <.menu
      :if={@actionable or @deletable}
      id={"user-actions-#{@prefix}#{@account.id}"}
      trigger_class="hover:bg-bg-2 dark:hover:bg-ink-700"
    >
      <:trigger>
        <span class="flex items-center justify-center size-9">
          <.icon name="hero-ellipsis-vertical" class="size-5 text-ink-700 dark:text-ink-100" />
          <span class="sr-only">Actions for {display_name(@account)}</span>
        </span>
      </:trigger>
      <.menu_item
        :for={status <- assignable_statuses(@account)}
        id={"set-status-#{@prefix}#{@account.id}-#{status.value}"}
        role="menuitem"
        icon={status.icon}
        label={status.action}
        variant={status.variant}
        phx-click="change_status"
        phx-value-id={@account.id}
        phx-value-status={status.value}
        data-confirm={status.confirm && confirm_text(@account, status)}
      />

      <%!-- Separated from the status rows: everything above is reversible, this
            is not. --%>
      <div :if={@deletable and @actionable} class="my-1 border-t border-ink-100 dark:border-ink-700">
      </div>

      <.menu_item
        :if={@deletable}
        id={"delete-account-#{@prefix}#{@account.id}"}
        role="menuitem"
        icon="hero-trash"
        label={gettext("Delete account")}
        variant={:danger}
        phx-click="delete_account"
        phx-value-id={@account.id}
        data-confirm={delete_confirm_text(@account)}
      />
    </.menu>
    """
  end

  defp delete_confirm_text(account) do
    gettext(
      "%{name} will be signed out for good, and the account's details erased. " <>
        "This cannot be undone.",
      name: display_name(account)
    )
  end

  # Every status the account could be moved into — i.e. every actionable one it
  # is not already in. Deriving the items from the status list rather than
  # hard-coding a ban/reactivate pair means a new status shows up here on its
  # own, with no second place to remember.
  defp assignable_statuses(account) do
    Enum.filter(statuses(), &(&1.action && &1.value != account.status))
  end

  defp confirm_text(account, status) do
    status.confirm.(display_name(account))
  end

  attr :account, :map, required: true
  attr :size, :integer, required: true

  defp identity(assigns) do
    ~H"""
    <div class="flex items-center gap-3 min-w-0">
      <.avatar name={avatar_name(@account)} src={avatar_src(@account)} size={@size} />
      <div class="min-w-0">
        <div class={[
          "text-body-md",
          anonymous?(@account) && "font-medium italic text-ink-500",
          !anonymous?(@account) && "font-semibold text-ink-900 dark:text-white"
        ]}>
          {display_name(@account)}
        </div>
        <%!-- Deletion clears the handle, so there is nothing to render but a
              stray "@". --%>
        <div :if={@account.handle} class="text-caption-lg text-ink-500">@{@account.handle}</div>
      </div>
    </div>
    """
  end

  defp status_label(status) do
    Enum.find_value(statuses(), gettext("Unknown"), &(&1.value == status && &1.label))
  end

  defp status_badge(status) do
    Enum.find_value(statuses(), "neutral", &(&1.value == status && &1.badge))
  end

  # Plain text rather than a badge: the status badge beside it is the row's one
  # colour signal, and a second badge would compete with it for attention.
  # v1 gives every user exactly one role, but the join allows more, so several
  # are joined rather than silently dropping all but the first.
  defp role_label(%{roles: roles}) when roles != [] do
    roles
    |> Enum.map(&String.capitalize(&1.name))
    |> Enum.sort()
    |> Enum.join(", ")
  end

  defp role_label(_account), do: "\u2014"

  defp filtered?(query, status), do: query not in [nil, ""] or not is_nil(status)

  defp applied_summary(query, status) do
    [
      query != "" && gettext("Search: %{query}", query: query),
      status && gettext("Status: %{status}", status: status_label(status))
    ]
    |> Enum.filter(& &1)
    |> Enum.join(" · ")
  end

  # A deleted account is anonymised in the UI even though its columns still
  # hold data: the row exists to show that an account was there, not to keep
  # its former owner findable by name.
  defp deleted?(account), do: account.status == :deleted

  defp anonymous?(account), do: deleted?(account) or is_nil(name_of(account))

  defp display_name(account) do
    cond do
      deleted?(account) -> gettext("Deleted user")
      name = name_of(account) -> name
      true -> gettext("Name not provided")
    end
  end

  # No fallback to the handle or the email on purpose: an account with no name
  # is reported as having none, which is what keeps a deleted account's former
  # owner unfindable by name.
  defp name_of(account), do: Accounts.full_name(account)

  defp avatar_name(account), do: if(deleted?(account), do: nil, else: name_of(account))
  defp avatar_src(account), do: if(deleted?(account), do: nil, else: account.avatar_url)

  defp email(account) do
    cond do
      deleted?(account) -> gettext("Erased on deletion")
      account.email -> to_string(account.email)
      true -> gettext("None on record")
    end
  end

  defp email_tone(account) do
    if deleted?(account), do: "text-ink-500", else: "text-ink-700 dark:text-ink-100"
  end

  defp last_active(%{last_active_at: nil}), do: gettext("Never")

  defp last_active(%{last_active_at: at}) do
    seconds = DateTime.diff(DateTime.utc_now(), at, :second)

    cond do
      seconds < 60 ->
        gettext("Just now")

      seconds < 3_600 ->
        ngettext("1 minute ago", "%{count} minutes ago", div(seconds, 60))

      seconds < 86_400 ->
        ngettext("1 hour ago", "%{count} hours ago", div(seconds, 3_600))

      seconds < 2_592_000 ->
        ngettext("1 day ago", "%{count} days ago", div(seconds, 86_400))

      true ->
        Calendar.strftime(at, "%d %b %Y")
    end
  end

  defp dimmed(account), do: deleted?(account) && "opacity-55"
end
