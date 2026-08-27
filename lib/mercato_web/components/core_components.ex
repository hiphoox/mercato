defmodule MercatoWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework.
  Components are hand-written directly with Tailwind utility classes rather
  than a component library like daisyUI. Here are useful references:

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: MercatoWeb.Gettext

  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50"
      {@rest}
    >
      <div class={[
        "flex items-start gap-2 w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap rounded-md shadow-md p-4 text-body-sm",
        @kind == :info && "bg-info-bg text-info-text",
        @kind == :error && "bg-error-bg text-error-text"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button, or a link when given a navigation target.

  Hugs its content unless `full_width`.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button size="sm" variant="neutral" phx-click="pause">Pause</.button>
      <.button variant="secondary" phx-click="follow">Follow</.button>
      <.button variant="tertiary" size="md" phx-click="pause">
        <.icon name="hero-pause" class="size-4" /> Pause
      </.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled type)
  attr :class, :any, doc: "replaces every default class, rather than adding to them"

  attr :variant, :string,
    default: "primary",
    values: ~w(critical primary secondary tertiary neutral danger)

  attr :size, :string,
    default: "lg",
    values: ~w(xs sm md lg),
    doc: "32 / 36 / 44 / 52px tall"

  attr :full_width, :boolean, default: false, doc: "fills the row it sits in"

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    # The shadow belongs to the variant rather than to every button: an outlined
    # one sits on the page rather than above it, and two competing shadow
    # utilities would be settled by the order Tailwind happened to emit them in.
    variants = %{
      # The one non-brand-coloured fill, so the single highest-stakes action on
      # a screen outranks the primary CTA without borrowing its colour. Inverted
      # on dark, where ink-900 is the page rather than the mark on it.
      "critical" => "shadow-sm bg-ink-900 text-white dark:bg-white dark:text-ink-900",
      "primary" => "shadow-sm bg-primary-500 text-white",
      "secondary" => "shadow-sm bg-secondary-500 text-white dark:bg-secondary-600",
      "tertiary" =>
        "border-[1.5px] border-primary-500 text-primary-700 dark:text-primary-100 " <>
          "hover:bg-primary-050 dark:hover:bg-ink-700",
      "neutral" => "shadow-sm bg-ink-100 text-ink-900 dark:bg-ink-700 dark:text-white",
      "danger" => "shadow-sm bg-error text-white"
    }

    sizes = %{
      "xs" => "h-8 px-3 text-caption-lg",
      "sm" => "h-9 px-3.5 text-body-sm",
      "md" => "h-11 px-4 text-body-md",
      "lg" => "h-[52px] px-5 text-body-md"
    }

    assigns =
      assign_new(assigns, :class, fn ->
        [
          "inline-flex items-center justify-center gap-2 whitespace-nowrap",
          "rounded-md font-semibold cursor-pointer",
          "transition-[filter,background-color] hover:brightness-95",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
          # Spelled out rather than left to opacity: the disabled palette is a
          # design token pair, not a faded version of the variant's own colors.
          "disabled:bg-ink-100 disabled:text-ink-300 disabled:shadow-none",
          "disabled:cursor-not-allowed disabled:hover:brightness-100",
          Map.fetch!(sizes, assigns.size),
          Map.fetch!(variants, assigns.variant),
          assigns.full_width && "w-full"
        ]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an accent link (form footers, "forgot password?", etc).

  ## Examples

      <.accent_link patch={~p"/sign-in"}>Log in</.accent_link>
  """
  attr :rest, :global, include: ~w(href navigate patch)
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def accent_link(assigns) do
    ~H"""
    <.link class={[@class, "text-primary-700 hover:text-primary-600 font-medium"]} {@rest}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a white, bordered, shadowed card surface.

  Padding follows the page's own margin regime — tighter on a phone, wider from
  `md` up — rather than being chosen per card, so cards on one screen agree.

  ## Examples

      <.card class="flex flex-col gap-5">...</.card>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      class={[
        @class,
        "bg-white dark:bg-ink-900 border border-ink-100 dark:border-ink-700 rounded-lg shadow-sm",
        "p-5 md:p-8"
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an alert: an icon, a headline, and the supporting text under it.

  A standing statement about the state a page or a record is in, which is what
  separates it from a flash — a flash reports what just happened and dismisses
  itself, an alert stays as long as the state it describes does.

  Every kind carries an icon as well as a colour, so the state is never told by
  colour alone.

  | Kind | Use |
  |---|---|
  | `success` | Something completed and needs no further action |
  | `info` | A neutral fact about the state a record is in |
  | `warning` | A state that limits the record without ending it |
  | `error` | A state that stops the record |

  ## Examples

      <.alert kind="warning" title="Paused — nobody else can open this page">
        Resume when you want it back in search.
      </.alert>
  """
  attr :kind, :string, default: "info", values: ~w(success info warning error)
  attr :title, :string, default: nil, doc: "the headline; the body alone reads fine without one"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def alert(assigns) do
    kinds = %{
      "success" => {"bg-success-bg text-success-text", "hero-check-circle"},
      "info" => {"bg-info-bg text-info-text", "hero-information-circle"},
      "warning" => {"bg-warning-bg text-warning-text", "hero-pause-circle"},
      "error" => {"bg-error-bg text-error-text", "hero-exclamation-circle"}
    }

    {kind_class, icon} = Map.fetch!(kinds, assigns.kind)

    assigns = assign(assigns, kind_class: kind_class, icon: icon)

    ~H"""
    <div
      role="alert"
      class={["flex items-start gap-3 px-4 py-3.5 rounded-lg", @kind_class, @class]}
      {@rest}
    >
      <.icon name={@icon} aria-hidden="true" class="size-5 flex-none mt-px" />
      <div class="min-w-0">
        <p :if={@title} class="text-body-md font-bold text-pretty">{@title}</p>
        <div class={["text-body-sm text-pretty", @title && "mt-0.5 opacity-90"]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a status badge.

  Badges label a record's state; they never carry an action, which is why this
  is a `<span>` and not a button.

  | Kind | Use |
  |---|---|
  | `verified` | A confirmed or healthy state — an active account, a verified seller |
  | `featured` | Sets a record apart — a promoted listing, an admin account |
  | `warning` | A state that limits the record without ending it — a restricted account |
  | `danger` | A state that stops the record — a banned account, a failed payment |
  | `info` | A state the record has come to rest in — a sold listing, a settled order |
  | `neutral` | Anything with no state of its own — a category, a count |

  `warning` and `danger` are the semantic alert tokens, not `accent` and not
  `sale`: `accent` is reserved for featured/highlighted records and `sale` for
  discounts, so borrowing either to mean "something is wrong" would collide
  with a meaning the design system already assigns it.

  ## Examples

      <.badge kind="verified">Active</.badge>
  """
  attr :kind, :string,
    default: "neutral",
    values: ~w(verified featured new warning danger info neutral)

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    kinds = %{
      "verified" => "bg-success-bg text-success-text",
      "featured" => "bg-accent-100 text-accent-600",
      "new" => "bg-primary-050 text-primary-700",
      "warning" => "bg-warning-bg text-warning-text",
      "danger" => "bg-error-bg text-error-text",
      "info" => "bg-info-bg text-info-text",
      "neutral" => "bg-ink-100 text-ink-700"
    }

    assigns = assign(assigns, :kind_class, Map.fetch!(kinds, assigns.kind))

    ~H"""
    <span
      class={[
        "inline-flex items-center h-[22px] px-2 rounded-full",
        "text-caption-md font-semibold whitespace-nowrap",
        @kind_class,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders a filter chip.

  Two shapes in one component, because they are the same object at two moments:
  a *selectable* chip offers a filter, and a *removable* one shows a filter
  that's already applied. Both stay black-and-white, since the primary color is
  reserved for actions.

  ## Examples

      <.filter_chip label="Active (12)" selected phx-click="filter" />
      <.filter_chip label="Status: Banned" removable phx-click="clear" />
  """
  attr :label, :string, required: true
  attr :selected, :boolean, default: false
  attr :removable, :boolean, default: false, doc: "renders as an applied-filter chip"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled name value)

  def filter_chip(%{removable: true} = assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1 h-6 pl-2.5 pr-1 rounded-full",
      "bg-white dark:bg-ink-900 border border-ink-900 dark:border-ink-100",
      "text-caption-md font-semibold text-ink-900 dark:text-white whitespace-nowrap",
      @class
    ]}>
      {@label}
      <button
        type="button"
        aria-label={"Remove #{@label}"}
        class="inline-flex items-center justify-center size-4 rounded-full hover:bg-ink-100 dark:hover:bg-ink-700"
        {@rest}
      >
        <.icon name="hero-x-mark-micro" class="size-3" />
      </button>
    </span>
    """
  end

  def filter_chip(assigns) do
    ~H"""
    <button
      type="button"
      aria-pressed={to_string(@selected)}
      class={[
        "inline-flex items-center h-8 px-3.5 rounded-full border transition-colors",
        "text-caption-lg font-semibold whitespace-nowrap cursor-pointer",
        @selected && "bg-ink-900 border-ink-900 text-white dark:bg-white dark:text-ink-900",
        !@selected &&
          "bg-white dark:bg-ink-900 border-ink-900 dark:border-ink-100 text-ink-900 dark:text-white hover:bg-bg-2 dark:hover:bg-ink-700",
        @class
      ]}
      {@rest}
    >
      {@label}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://phoenix-html.hexdocs.pm/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="text-body-sm font-medium text-ink-700">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "size-4 rounded border-ink-300 text-primary-500 focus:ring-primary-100"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label for={@id}>
        <span :if={@label} class="block text-body-sm font-medium text-ink-700 mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              "block w-full rounded-md border-[1.5px] border-ink-300 px-[14px] py-[11px] text-body-md focus:outline-none focus:ring-[3px] focus:ring-primary-100 focus:border-primary-500",
            @errors != [] && (@error_class || "border-error focus:ring-error-bg focus:border-error")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label for={@id}>
        <span :if={@label} class="block text-body-sm font-medium text-ink-700 mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              "block w-full rounded-md border-[1.5px] border-ink-300 px-[14px] py-[11px] text-body-md placeholder-ink-500 focus:outline-none focus:ring-[3px] focus:ring-primary-100 focus:border-primary-500",
            @errors != [] && (@error_class || "border-error focus:ring-error-bg focus:border-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="mb-2">
      <label for={@id}>
        <span :if={@label} class="block text-body-sm font-medium text-ink-700 mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class ||
              "block w-full rounded-md border-[1.5px] border-ink-300 px-[14px] py-[11px] text-body-md placeholder-ink-500 focus:outline-none focus:ring-[3px] focus:ring-primary-100 focus:border-primary-500",
            @errors != [] && (@error_class || "border-error focus:ring-error-bg focus:border-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a page header: title, optional subtitle, optional actions.

  ## Examples

      <.header>
        Furniture
        <:subtitle>412 listings within 10 km</:subtitle>
        <:actions><.button>Sell</.button></:actions>
      </.header>
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[
      "flex items-end gap-4 flex-wrap",
      @actions != [] && "justify-between"
    ]}>
      <div>
        <h1 class="text-display font-extrabold text-ink-900 dark:text-white">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-1 text-body-sm text-ink-500">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div :if={@actions != []} class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table.

  Columns are declared with `:col`. A column may be marked `row_header` to render
  its cells as the row's header rather than a data cell, which is what lets a
  screen reader announce which row a cell belongs to.

  `row_class` and a column's `cell_class` each accept either a class or a
  function of the row, so a row or cell can be styled from its own data.

  ## Examples

      <.table id="users" rows={@users} caption="Registered users">
        <:col :let={user} label="User" row_header>{user.name}</:col>
        <:col :let={user} label="Email" class="hidden xl:table-cell">{user.email}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :class, :any, default: nil

  attr :caption, :string,
    default: nil,
    doc: "describes the table to a screen reader; not shown visually"

  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  attr :row_class, :any,
    default: nil,
    doc: "a class for every row, or a function of the row returning one"

  slot :col, required: true do
    attr :label, :string
    attr :class, :any, doc: "applied to this column's header cell and every one of its body cells"

    attr :cell_class, :any,
      doc: "applied to this column's body cells only; a class or a function of the row"

    attr :row_header, :boolean, doc: "renders this column's cells as the row's header"
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class={["w-full border-collapse text-left text-body-sm", @class]}>
      <caption :if={@caption} class="sr-only">{@caption}</caption>
      <thead>
        <tr>
          <th :for={col <- @col} scope="col" class={[table_head_class(), col[:class]]}>
            {col[:label]}
          </th>
          <th :if={@action != []} scope="col" class={table_head_class()}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr
          :for={row <- @rows}
          id={@row_id && @row_id.(row)}
          class={[
            "border-t border-ink-100 dark:border-ink-700",
            from_row(@row_class, @row_item.(row))
          ]}
        >
          <.table_cell
            :for={col <- @col}
            row_header={!!col[:row_header]}
            phx-click={@row_click && @row_click.(row)}
            class={[
              table_cell_class(),
              @row_click && "hover:cursor-pointer",
              col[:class],
              from_row(col[:cell_class], @row_item.(row))
            ]}
          >
            {render_slot(col, @row_item.(row))}
          </.table_cell>
          <td :if={@action != []} class={[table_cell_class(), "w-0"]}>
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr :row_header, :boolean, required: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  defp table_cell(%{row_header: true} = assigns) do
    ~H"""
    <th scope="row" class={[@class, "font-normal"]} {@rest}>{render_slot(@inner_block)}</th>
    """
  end

  defp table_cell(assigns) do
    ~H"""
    <td class={@class} {@rest}>{render_slot(@inner_block)}</td>
    """
  end

  # The header sticks so it stays readable when the table body scrolls; it has no
  # effect on a table that isn't inside a scroll container.
  defp table_head_class do
    [
      "sticky top-0 z-[2] px-4 py-3 bg-white dark:bg-ink-900",
      "text-caption-lg font-bold text-ink-500 shadow-[inset_0_-1px_0_var(--color-ink-100)]"
    ]
  end

  defp table_cell_class, do: "px-4 py-3.5 align-top"

  defp from_row(fun, row) when is_function(fun, 1), do: fun.(row)
  defp from_row(class, _row), do: class

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-ink-100">
      <li :for={item <- @item} class="flex items-center justify-between py-3">
        <div class="flex-1">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"
  attr :rest, :global, doc: "arbitrary attributes, e.g. aria-hidden on a decorative icon"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(MercatoWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MercatoWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
