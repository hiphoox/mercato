defmodule MercatoWeb.Admin.UsersLive do
  @moduledoc """
  Admin listing of every account on the platform.

  Read-only for now: search, status filter, and paging. The per-row actions the
  design calls for (change status, delete) land in a later change, so nothing
  here mutates a user.

  Filter state lives in the query string rather than in socket assigns alone, so
  a filtered listing is a shareable URL and the browser's back button walks back
  through filters the way a user expects.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Avatar
  import MercatoWeb.UI.Breadcrumb

  alias Mercato.Accounts

  on_mount {MercatoWeb.LiveUserAuth, :live_admin_required}

  @page_size 20

  @statuses [
    %{value: :active, label: "Active", badge: "verified"},
    %{value: :banned, label: "Banned", badge: "featured"},
    %{value: :deleted, label: "Deleted", badge: "neutral"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_size, @page_size) |> load_status_counts()}
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

  defp parse_status(value) when value in ["active", "banned", "deleted"],
    do: String.to_existing_atom(value)

  defp parse_status(_), do: nil

  defp parse_page(value) do
    case Integer.parse(to_string(value)) do
      {page, ""} when page > 0 -> page
      _ -> 1
    end
  end

  defp load_accounts(socket) do
    %{query: query, status: status, page: page, current_user: actor} = socket.assigns

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
  end

  # Counted once at mount, not per filter change: the chips describe the
  # platform, not the current search, and this page can't change anyone's
  # status yet. Once it can, the mutation handler is what re-counts — a chip
  # shifting while the user types would make it useless as a starting point for
  # narrowing down.
  defp load_status_counts(socket) do
    actor = socket.assigns.current_user

    counts =
      Map.new(@statuses, fn %{value: status} ->
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

  def handle_event("page", %{"to" => to}, socket) do
    {:noreply, apply_filters(socket, page: parse_page(to))}
  end

  defp apply_filters(socket, overrides) do
    current = [
      query: socket.assigns.query,
      status: socket.assigns.status,
      page: socket.assigns.page
    ]

    push_patch(socket, to: ~p"/admin/users?#{filter_params(Keyword.merge(current, overrides))}")
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
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={@current_user}
      admin?={@admin?}
      current_path={~p"/admin/users"}
    >
      <div class="flex flex-col gap-6">
        <.breadcrumb items={[%{label: "Admin"}, %{label: "Users"}]} />

        <.header>
          Users
          <:subtitle>Review and manage every account on the platform.</:subtitle>
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
              label="Search users"
              placeholder="Name, @handle, or email"
              phx-debounce="300"
            />
          </form>

          <div class="flex flex-col gap-1.5">
            <span id="status-filter-label" class="text-caption-lg font-semibold text-ink-700">
              Status
            </span>
            <div
              role="group"
              aria-labelledby="status-filter-label"
              class="flex flex-wrap gap-2 pb-1"
            >
              <.filter_chip
                id="status-chip-all"
                label={"All (#{@status_counts.all})"}
                selected={is_nil(@status)}
                phx-click="filter_status"
                phx-value-status="all"
              />
              <.filter_chip
                :for={status <- statuses()}
                id={"status-chip-#{status.value}"}
                label={"#{status.label} (#{@status_counts[status.value]})"}
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
          <span class="text-caption-lg font-semibold text-ink-500">Applied</span>
          <.filter_chip
            :if={@query != ""}
            id="remove-query-filter"
            label={"Search: #{@query}"}
            removable
            phx-click="filter_status"
            phx-value-status={@status || "all"}
          />
          <.filter_chip
            :if={@status}
            id="remove-status-filter"
            label={"Status: #{status_label(@status)}"}
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
            Clear filters
          </button>
        </div>

        <div
          :if={@accounts == [] and not filtered?(@query, @status)}
          class="py-14 px-6 text-center border border-ink-100 dark:border-ink-700 rounded-lg"
        >
          <p class="text-body-lg text-ink-500">No accounts exist on this platform yet.</p>
        </div>

        <div
          :if={@accounts == [] and filtered?(@query, @status)}
          class="flex flex-col items-center gap-3.5 py-12 px-6 border border-ink-100 dark:border-ink-700 rounded-lg"
        >
          <.icon name="hero-magnifying-glass" class="size-8 text-ink-300" />
          <p class="max-w-[44ch] text-center text-body-md text-ink-700">
            No accounts match {applied_summary(@query, @status)}.
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
              caption="User accounts with status and last activity"
              row_id={&"user-#{&1.id}"}
              row_class={&dimmed/1}
            >
              <:col :let={account} label="User" row_header>
                <.identity account={account} size={40} />
              </:col>
              <:col
                :let={account}
                label="Email"
                class="hidden xl:table-cell"
                cell_class={&["break-words", email_tone(&1)]}
              >
                {email(account)}
              </:col>
              <:col :let={account} label="Status">
                <.badge kind={status_badge(account.status)}>{status_label(account.status)}</.badge>
              </:col>
              <:col :let={account} label="Role" cell_class="whitespace-nowrap">
                {role_label(account)}
              </:col>
              <:col :let={account} label="Last active" cell_class="whitespace-nowrap text-ink-500">
                {last_active(account)}
              </:col>
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
              <.identity account={account} size={44} />

              <dl class="flex flex-col gap-2 text-body-sm text-ink-700 dark:text-ink-100">
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">Email</dt>
                  <dd class={["min-w-0 break-words", email_tone(account)]}>{email(account)}</dd>
                </div>
                <div class="flex items-center gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">Status</dt>
                  <dd>
                    <.badge kind={status_badge(account.status)}>
                      {status_label(account.status)}
                    </.badge>
                  </dd>
                </div>
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">Role</dt>
                  <dd>{role_label(account)}</dd>
                </div>
                <div class="flex gap-2.5">
                  <dt class="min-w-[88px] text-ink-500">Last active</dt>
                  <dd>{last_active(account)}</dd>
                </div>
              </dl>
            </div>
          </div>

          <.pagination
            page={@page}
            last_page={@last_page}
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
        <div class="text-caption-lg text-ink-500">@{@account.handle}</div>
      </div>
    </div>
    """
  end

  attr :page, :integer, required: true
  attr :last_page, :integer, required: true
  attr :total, :integer, required: true
  attr :page_size, :integer, required: true
  attr :class, :any, default: nil

  defp pagination(assigns) do
    ~H"""
    <div class={["flex flex-wrap items-center justify-between gap-3", @class]}>
      <span aria-live="polite" class="text-caption-lg text-ink-500">
        {page_label(@page, @last_page, @total, @page_size)}
      </span>
      <div class="flex items-center gap-2">
        <.page_button id="prev-page" to={@page - 1} disabled={@page <= 1}>Previous</.page_button>
        <.page_button id="next-page" to={@page + 1} disabled={@page >= @last_page}>
          Next
        </.page_button>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :to, :integer, required: true
  attr :disabled, :boolean, required: true
  slot :inner_block, required: true

  defp page_button(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      disabled={@disabled}
      phx-click="page"
      phx-value-to={@to}
      class={[
        "inline-flex items-center h-8 px-3 rounded-md text-caption-lg font-semibold transition-colors",
        "bg-ink-100 text-ink-900 hover:brightness-95 cursor-pointer",
        "disabled:bg-ink-100 disabled:text-ink-300 disabled:cursor-not-allowed disabled:hover:brightness-100"
      ]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp statuses, do: @statuses

  defp status_label(status) do
    Enum.find_value(@statuses, "Unknown", &(&1.value == status && &1.label))
  end

  defp status_badge(status) do
    Enum.find_value(@statuses, "neutral", &(&1.value == status && &1.badge))
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
    [query != "" && "Search: #{query}", status && "Status: #{status_label(status)}"]
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
      deleted?(account) -> "Deleted user"
      name = name_of(account) -> name
      true -> "Name not provided"
    end
  end

  defp name_of(account) do
    case [account.first_name, account.last_name] |> Enum.reject(&(&1 in [nil, ""])) do
      [] -> nil
      parts -> Enum.join(parts, " ")
    end
  end

  defp avatar_name(account), do: if(deleted?(account), do: nil, else: name_of(account))
  defp avatar_src(account), do: if(deleted?(account), do: nil, else: account.avatar_url)

  defp email(account) do
    cond do
      deleted?(account) -> "Erased on deletion"
      account.email -> to_string(account.email)
      true -> "None on record"
    end
  end

  defp email_tone(account) do
    if deleted?(account), do: "text-ink-500", else: "text-ink-700 dark:text-ink-100"
  end

  defp last_active(%{last_active_at: nil}), do: "Never"

  defp last_active(%{last_active_at: at}) do
    seconds = DateTime.diff(DateTime.utc_now(), at, :second)

    cond do
      seconds < 60 -> "Just now"
      seconds < 3_600 -> "#{div(seconds, 60)} minutes ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)} hours ago"
      seconds < 2_592_000 -> "#{div(seconds, 86_400)} days ago"
      true -> Calendar.strftime(at, "%d %b %Y")
    end
  end

  defp page_label(_page, _last_page, 0, _page_size), do: ""

  defp page_label(page, last_page, total, page_size) do
    first = (page - 1) * page_size + 1
    last = min(page * page_size, total)

    "Showing #{first}–#{last} of #{total} · page #{page} of #{last_page}"
  end

  defp dimmed(account), do: deleted?(account) && "opacity-55"
end
