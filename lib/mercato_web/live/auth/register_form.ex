defmodule MercatoWeb.Live.Auth.RegisterForm do
  @moduledoc """
  Mercato-styled registration form, plugged into `ash_authentication_phoenix`
  via the `register_form_module` override in `MercatoWeb.AuthOverrides` —
  replaces `AshAuthentication.Phoenix.Components.Password.RegisterForm` so we
  can collect `first_name`/`last_name` (matching `register_with_password`'s
  actual accepted fields) instead of a single "full name" field.

  Also renders the same Password/Magic link segmented control as
  `MercatoWeb.Live.Auth.SignInForm` — registering via a magic link only ever
  needs an email (the account is created with a blank name on first sign-in,
  see `sign_in_with_magic_link`), so its tab collects just that.
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
      |> assign(trigger_action: false, subject_name: subject_name, magic_strategy: magic_strategy)
      |> assign_new(:overrides, fn -> [AshAuthentication.Phoenix.Overrides.Default] end)
      |> assign_new(:gettext_fn, fn -> nil end)
      |> assign_new(:current_tenant, fn -> nil end)
      |> assign_new(:context, fn -> %{} end)
      |> assign_new(:auth_routes_prefix, fn -> nil end)
      |> assign_new(:mode, fn -> :password end)
      |> assign_new(:password_form, fn ->
        build_form(strategy, strategy.register_action_name, socket)
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
        "register-#{subject_name}-#{strategy.name}-#{String.replace(to_string(action_name), "_", "-")}"
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2">
      <.card class="flex flex-col gap-5">
        <div class="flex flex-col gap-1 text-center">
          <h2 class="text-h2 font-bold text-ink-900">{gettext("Create your account")}</h2>
          <p class="text-body-md text-ink-500">{gettext("Join Mercato to buy and sell")}</p>
        </div>

        <ModeSwitcher.mode_switcher
          myself={@myself}
          active={@mode}
          options={[{:password, gettext("Password")}, {:magic, gettext("Magic link")}]}
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
          action={auth_path(@socket, @subject_name, @auth_routes_prefix, @strategy, :register)}
          method="POST"
          class="flex flex-col gap-5"
        >
          <div class="flex flex-col gap-2">
            <.input
              id="register-first-name"
              field={form[:first_name]}
              label={gettext("First name")}
              placeholder={gettext("Jane")}
              required
            />
            <.input
              id="register-last-name"
              field={form[:last_name]}
              label={gettext("Last name")}
              placeholder={gettext("Doe")}
            />
            <.input
              id="register-email"
              field={form[:email]}
              type="email"
              label={gettext("Email")}
              placeholder="you@example.com"
              required
            />
            <.input
              id="register-password"
              field={form[:password]}
              type="password"
              label={gettext("Password")}
              placeholder={gettext("At least 8 characters")}
              required
            />
            <.input
              id="register-password-confirmation"
              field={form[:password_confirmation]}
              type="password"
              label={gettext("Confirm password")}
              placeholder={gettext("Re-enter your password")}
              required
            />
          </div>

          <.button
            type="submit"
            variant="primary"
            full_width
            phx-disable-with={gettext("Creating account...")}
          >
            {gettext("Create account")}
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
              id="register-magic-email"
              field={form[:email]}
              type="email"
              label={gettext("Email")}
              placeholder="you@example.com"
              required
            />
            <p class="text-caption-lg text-ink-500">
              {gettext("We'll email you a link to create your account.")}
            </p>
          </div>

          <.button type="submit" variant="primary" full_width phx-disable-with={gettext("Sending...")}>
            {gettext("Send magic link")}
          </.button>
        </.form>

        <p :if={@mode == :password} class="text-caption-md text-ink-500 text-center">
          {gettext(
            "By creating an account, you agree to Mercato's Terms of Service and Privacy Policy."
          )}
        </p>
      </.card>

      <p class="text-center text-body-sm text-ink-500">
        {gettext("Already have an account?")}
        <.accent_link patch={~p"/sign-in"}>{gettext("Log in")}</.accent_link>
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
        gettext(
          "If this address doesn't already have an account, we've emailed you a link to create one."
        )
      )

    {:noreply, socket}
  end

  defp current_email(form), do: Form.value(form, :email) || ""

  defp get_params(params, subject_name), do: Map.get(params, to_string(subject_name), %{})
end
