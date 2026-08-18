defmodule MercatoWeb.Live.Auth.ModeSwitcher do
  @moduledoc """
  The Password/Magic-link segmented control shared by
  `MercatoWeb.Live.Auth.RegisterForm`, `SignInForm`, and `ResetForm`. Field,
  button, link, and card styling live directly on `MercatoWeb.CoreComponents`
  (`input/1`, `button/1`, `accent_link/1`, `card/1`) as Tailwind utility
  classes, since they're shared across the app rather than auth-specific. See
  docs/architecture/design-tokens.md and ui-components.md.
  """

  use Phoenix.Component

  @doc """
  A Password/Magic-link segmented control. Clicking an option sends a
  `"set_mode"` event (with a `"mode"` param) to `@myself` — the parent
  LiveComponent owns the actual mode/form state and switches which form is
  displayed.
  """
  attr :myself, :any, required: true
  attr :active, :atom, required: true
  attr :options, :list, required: true, doc: "list of {mode :: atom, label :: string}"

  def mode_switcher(assigns) do
    ~H"""
    <div class="flex gap-1 rounded-md bg-bg-2 p-1">
      <button
        :for={{mode, label} <- @options}
        type="button"
        phx-click="set_mode"
        phx-value-mode={mode}
        phx-target={@myself}
        class={[
          "flex-1 rounded-md py-2 text-body-sm font-semibold text-center transition-colors",
          if(@active == mode, do: "bg-ink-900 text-white", else: "bg-transparent text-ink-700")
        ]}
      >
        {label}
      </button>
    </div>
    """
  end
end
