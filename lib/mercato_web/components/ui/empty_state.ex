defmodule MercatoWeb.UI.EmptyState do
  @moduledoc """
  What a collection shows when it holds nothing.

      <.empty_state
        icon="hero-square-3-stack-3d"
        headline="Your first listing starts here"
        description="Photos, a price, and a short description are all it takes."
      >
        <:actions>
          <.button size="sm">List something</.button>
        </:actions>
      </.empty_state>
  """
  use MercatoWeb, :html

  @doc "Renders an empty state. The headline is a heading, not loose text."
  attr :headline, :string, required: true
  attr :description, :string, default: nil
  attr :icon, :string, default: nil, doc: "heroicon name, e.g. \"hero-inbox\""
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "what the visitor can do about the emptiness"

  def empty_state(assigns) do
    ~H"""
    <div
      class={[
        "flex flex-col items-center gap-3 text-center",
        "px-6 py-11 rounded-lg border border-ink-100 dark:border-ink-700",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} aria-hidden="true" class="size-7 text-ink-300" />

      <h2 class="text-title-lg font-bold text-ink-900 dark:text-white text-pretty">
        {@headline}
      </h2>

      <p :if={@description} class="max-w-[52ch] text-body-md text-ink-500 text-pretty">
        {@description}
      </p>

      <div :if={@actions != []} data-role="empty-state-actions" class="mt-1 flex flex-wrap gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end
end
