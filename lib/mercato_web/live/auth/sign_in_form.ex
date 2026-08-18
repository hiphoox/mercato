defmodule MercatoWeb.Live.Auth.SignInForm do
  @moduledoc """
  Mercato-styled sign-in form, plugged into `ash_authentication_phoenix` via
  the `sign_in_form_module` override in `MercatoWeb.AuthOverrides` — replaces
  `AshAuthentication.Phoenix.Components.Password.SignInForm`.

  Renders a Password/Magic link segmented control that switches between the
  `sign_in_with_password` and `request_magic_link` actions in place, so the
  two sign-in methods share one card instead of stacking as separate
  sections (see `MercatoWeb.AuthOverrides` for why the library's own
  `Components.MagicLink` section is hidden).
  """

  use MercatoWeb, :live_component

  alias AshAuthentication.Info
  alias AshPhoenix.Form

  import AshAuthentication.Phoenix.Components.Helpers
  import AshAuthentication.Phoenix.Utils.Flash, only: [put_flash!: 3]

  alias MercatoWeb.Live.Auth.ModeSwitcher

  @impl true
  def update(assigns, socket) do
    strategy = assigns.strategy
    magic_strategy = Info.strategy!(strategy.resource, :magic_link)
    subject_name = Info.authentication_subject_name!(strategy.resource)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        trigger_action: false,
        subject_name: subject_name,
        magic_strategy: magic_strategy
      )
      |> assign_new(:overrides, fn -> [AshAuthentication.Phoenix.Overrides.Default] end)
      |> assign_new(:gettext_fn, fn -> nil end)
      |> assign_new(:current_tenant, fn -> nil end)
      |> assign_new(:context, fn -> %{} end)
      |> assign_new(:auth_routes_prefix, fn -> nil end)
      |> assign_new(:mode, fn -> :password end)
      |> assign_new(:password_form, fn ->
        build_form(strategy, strategy.sign_in_action_name, socket)
      end)
      |> assign_new(:magic_form, fn ->
        build_form(magic_strategy, magic_strategy.request_action_name, socket)
      end)

    {:ok, socket}
  end

  defp build_form(strategy, action_name, socket) do
    domain = Info.authentication_domain!(strategy.resource)
    subject_name = Info.authentication_subject_name!(strategy.resource)

    strategy.resource
    |> Form.for_action(action_name,
      domain: domain,
      as: subject_name |> to_string(),
      tenant: socket.assigns[:current_tenant],
      context:
        socket.assigns[:context]
        |> Kernel.||(%{})
        |> Map.put(:strategy, strategy)
        |> Map.update(
          :private,
          %{ash_authentication?: true},
          &Map.put(&1, :ash_authentication?, true)
        ),
      id:
        "sign-in-#{subject_name}-#{strategy.name}-#{String.replace(to_string(action_name), "_", "-")}"
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <.card class="flex flex-col gap-5">
        <div class="flex flex-col gap-1 text-center">
          <h2 class="text-h2 font-bold text-ink-900">Welcome back</h2>
          <p class="text-body-md text-ink-500">Sign in to buy and sell on Mercato</p>
        </div>

        <ModeSwitcher.mode_switcher
          myself={@myself}
          active={@mode}
          options={[{:password, "Password"}, {:magic, "Magic link"}]}
        />

        <.form
          :let={form}
          :if={@mode == :password}
          id={@password_form.id}
          for={@password_form}
          phx-change="change"
          phx-submit="submit"
          phx-trigger-action={@trigger_action}
          phx-target={@myself}
          action={auth_path(@socket, @subject_name, @auth_routes_prefix, @strategy, :sign_in)}
          method="POST"
          class="flex flex-col gap-5"
        >
          <div class="flex flex-col gap-2">
            <.input
              id="sign-in-email"
              field={form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
            />
            <div class="flex flex-col gap-1">
              <.input
                id="sign-in-password"
                field={form[:password]}
                type="password"
                label="Password"
                placeholder="Your password"
                required
              />
              <div class="flex justify-end">
                <.accent_link patch={~p"/reset"} class="text-caption-lg">
                  Forgot your password?
                </.accent_link>
              </div>
            </div>
          </div>

          <.button type="submit" variant="primary" phx-disable-with="Signing in...">
            Sign in
          </.button>
        </.form>

        <.form
          :let={form}
          :if={@mode == :magic}
          id={@magic_form.id}
          for={@magic_form}
          phx-change="change"
          phx-submit="submit"
          phx-target={@myself}
          class="flex flex-col gap-5"
        >
          <div class="flex flex-col gap-2">
            <.input
              id="magic-email"
              field={form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
            />
            <p class="text-caption-lg text-ink-500">We'll email you a link to sign in instantly.</p>
          </div>

          <.button type="submit" variant="primary" phx-disable-with="Sending...">
            Send magic link
          </.button>
        </.form>
      </.card>

      <p class="text-center text-body-sm text-ink-500">
        Need an account? <.accent_link patch={~p"/register"}>Sign up</.accent_link>
      </p>
    </div>
    """
  end

  @impl true
  def handle_event("set_mode", %{"mode" => "password"}, socket) do
    email = current_email(socket.assigns.magic_form)

    {:noreply,
     socket
     |> assign(:mode, :password)
     |> assign(
       :password_form,
       Form.validate(socket.assigns.password_form, %{"email" => email}, errors: false)
     )}
  end

  def handle_event("set_mode", %{"mode" => "magic"}, socket) do
    email = current_email(socket.assigns.password_form)

    {:noreply,
     socket
     |> assign(:mode, :magic)
     |> assign(
       :magic_form,
       Form.validate(socket.assigns.magic_form, %{"email" => email}, errors: false)
     )}
  end

  def handle_event("change", params, %{assigns: %{mode: :password}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    {:noreply,
     assign(socket,
       password_form: Form.validate(socket.assigns.password_form, params, errors: false)
     )}
  end

  def handle_event("change", params, %{assigns: %{mode: :magic}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    {:noreply,
     assign(socket, magic_form: Form.validate(socket.assigns.magic_form, params, errors: false))}
  end

  def handle_event("submit", params, %{assigns: %{mode: :password}} = socket) do
    params = get_params(params, socket.assigns.subject_name)
    form = Form.validate(socket.assigns.password_form, params)

    {:noreply,
     socket
     |> assign(:password_form, form)
     |> assign(:trigger_action, form.valid?)}
  end

  def handle_event("submit", params, %{assigns: %{mode: :magic}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    case Form.submit(socket.assigns.magic_form, params: params) do
      {:ok, _result} -> :ok
      :ok -> :ok
      {:error, _form} -> :ok
    end

    socket =
      socket
      |> assign(
        :magic_form,
        build_form(
          socket.assigns.magic_strategy,
          socket.assigns.magic_strategy.request_action_name,
          socket
        )
      )
      |> put_flash!(
        :info,
        "If this user exists, we've sent a sign-in link to that email address."
      )

    {:noreply, socket}
  end

  defp current_email(form), do: Form.value(form, :email) || ""

  defp get_params(params, subject_name), do: Map.get(params, to_string(subject_name), %{})
end
