defmodule MercatoWeb.UI.ChoiceChips do
  @moduledoc """
  A labelled group of chips for picking one value out of a short list.

  Radio inputs rather than buttons, so the choice is part of the form the group
  sits in and needs nothing wired to carry a value. The chips stay
  black-and-white in both states, which is what keeps the primary color to
  actions.

      <.choice_chips
        field={@form[:condition]}
        label="Condition"
        options={[{"New", "new"}, {"Like new", "like_new"}]}
        clear_label="No preference"
      />
  """
  use MercatoWeb, :html

  @doc """
  Renders the group.

  `options` are `{label, value}` pairs in display order. A `clear_label` adds a
  leading chip holding the empty value, which is how an optional field is
  unset again once something has been picked; omit it and the group offers no
  way back to nothing.

  An empty `options` list renders nothing at all — a marketplace that
  configures no values for a field gets no empty legend announced for it.
  """
  attr :id, :any, default: nil
  attr :name, :any
  # No default: a declared default is always assigned, which would make the
  # `assign_new` below a no-op and leave a field's own value unread.
  attr :value, :any
  attr :label, :string, required: true
  attr :options, :list, required: true, doc: "{label, value} pairs, in display order"
  attr :errors, :list, default: []

  attr :clear_label, :string,
    default: nil,
    doc: "labels a leading empty-value chip; omitted, the group cannot be unset"

  attr :field, Phoenix.HTML.FormField, doc: "a form field, e.g. @form[:condition]"
  attr :class, :any, default: nil
  attr :rest, :global

  def choice_chips(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> choice_chips()
  end

  def choice_chips(%{options: []} = assigns), do: ~H""

  def choice_chips(assigns) do
    assigns = assign_new(assigns, :value, fn -> nil end)

    assigns =
      assigns
      |> assign(:value, to_string(assigns.value))
      |> assign(:chips, chips(assigns))

    ~H"""
    <fieldset id={@id} class={["min-w-0", @class]} {@rest}>
      <legend class="text-body-sm font-medium text-ink-700 dark:text-ink-100 mb-2">
        {@label}
      </legend>

      <div class="flex flex-wrap gap-2">
        <label :for={{label, value} <- @chips} class="cursor-pointer">
          <%!-- Screen-reader-only rather than hidden: the radio still takes
                focus and answers arrow keys, and `peer-checked` styles the chip
                beside it without a round-trip to the server. --%>
          <input
            type="radio"
            id={@id && "#{@id}-#{value}"}
            name={@name}
            value={value}
            checked={value == @value}
            class="sr-only peer"
          />
          <span class={[
            "inline-flex items-center h-9 px-3.5 rounded-full border transition-colors",
            "text-body-sm font-medium whitespace-nowrap",
            "bg-white dark:bg-ink-900 border-ink-300 text-ink-700 dark:text-ink-100",
            "hover:border-ink-900 hover:text-ink-900 dark:hover:text-white",
            "peer-checked:bg-ink-900 peer-checked:border-ink-900 peer-checked:border-[1.5px]",
            "peer-checked:font-semibold peer-checked:text-white",
            "dark:peer-checked:bg-white dark:peer-checked:text-ink-900",
            "peer-focus-visible:outline-none peer-focus-visible:ring-3 peer-focus-visible:ring-primary-100",
            @errors != [] && "border-error"
          ]}>
            {label}
          </span>
        </label>
      </div>

      <p :for={msg <- @errors} class="mt-1.5 flex gap-2 items-center text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-5" />
        {msg}
      </p>
    </fieldset>
    """
  end

  # The clearing chip leads rather than trails: it is the state the field starts
  # in, so it reads as the first of the choices rather than an afterthought.
  defp chips(%{clear_label: nil, options: options}), do: options
  defp chips(%{clear_label: label, options: options}), do: [{label, ""} | options]
end
