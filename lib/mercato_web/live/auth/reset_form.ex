defmodule MercatoWeb.Live.Auth.ResetForm do
  @moduledoc """
  Mercato-styled password-reset form, plugged into `ash_authentication_phoenix`
  via the `reset_form_module` override in `MercatoWeb.AuthOverrides` — replaces
  `AshAuthentication.Phoenix.Components.Password.ResetForm`.

  Renders the same Password/Magic link segmented control as
  `MercatoWeb.Live.Auth.SignInForm`: a user who forgot their password may not
  want to reset it at all, just get back in — the "Magic link" tab requests a
  one-time sign-in link (`request_magic_link`) instead of a password-reset
  email (`request_password_reset_token`). Both tabs only ever collect an
  email address.
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
      |> assign(subject_name: subject_name, magic_strategy: magic_strategy)
      |> assign_new(:overrides, fn -> [AshAuthentication.Phoenix.Overrides.Default] end)
      |> assign_new(:gettext_fn, fn -> nil end)
      |> assign_new(:current_tenant, fn -> nil end)
      |> assign_new(:context, fn -> %{} end)
      |> assign_new(:auth_routes_prefix, fn -> nil end)
      |> assign_new(:mode, fn -> :reset end)
      |> assign_new(:reset_form, fn ->
        build_form(strategy, strategy.resettable.request_password_reset_action_name, socket)
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
        "reset-#{subject_name}-#{strategy.name}-#{String.replace(to_string(action_name), "_", "-")}"
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.card class="flex flex-col gap-5">
        <div class="flex flex-col gap-1 text-center">
          <h2 class="text-h2 font-bold text-ink-900">Reset your password</h2>
          <p class="text-body-md text-ink-500">We'll help you get back into your account</p>
        </div>

        <ModeSwitcher.mode_switcher
          myself={@myself}
          active={@mode}
          options={[{:reset, "Reset password"}, {:magic, "Magic link"}]}
        />

        <.form
          :let={form}
          :if={@mode == :reset}
          id={@reset_form.id}
          for={@reset_form}
          phx-change="change"
          phx-submit="submit"
          phx-target={@myself}
          action={auth_path(@socket, @subject_name, @auth_routes_prefix, @strategy, :reset_request)}
          method="POST"
          class="flex flex-col gap-5"
        >
          <div class="flex flex-col gap-2">
            <.input
              id="reset-email"
              field={form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
            />
            <p class="text-caption-lg text-ink-500">
              We'll email you a link to set a new password.
            </p>
          </div>

          <.button type="submit" variant="primary" phx-disable-with="Sending...">
            Send reset instructions
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
              id="reset-magic-email"
              field={form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
            />
            <p class="text-caption-lg text-ink-500">
              Skip the password reset — we'll email you a one-time sign-in link instead.
            </p>
          </div>

          <.button type="submit" variant="primary" phx-disable-with="Sending...">
            Send magic link
          </.button>
        </.form>
      </.card>
    </div>
    """
  end

  @impl true
  def handle_event("set_mode", %{"mode" => "reset"}, socket) do
    email = current_email(socket.assigns.magic_form)

    {:noreply,
     socket
     |> assign(:mode, :reset)
     |> assign(
       :reset_form,
       Form.validate(socket.assigns.reset_form, %{"email" => email}, errors: false)
     )}
  end

  def handle_event("set_mode", %{"mode" => "magic"}, socket) do
    email = current_email(socket.assigns.reset_form)

    {:noreply,
     socket
     |> assign(:mode, :magic)
     |> assign(
       :magic_form,
       Form.validate(socket.assigns.magic_form, %{"email" => email}, errors: false)
     )}
  end

  def handle_event("change", params, %{assigns: %{mode: :reset}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    {:noreply,
     assign(socket, reset_form: Form.validate(socket.assigns.reset_form, params, errors: false))}
  end

  def handle_event("change", params, %{assigns: %{mode: :magic}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    {:noreply,
     assign(socket, magic_form: Form.validate(socket.assigns.magic_form, params, errors: false))}
  end

  def handle_event("submit", params, %{assigns: %{mode: :reset}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    submit_and_reset(
      socket,
      :reset_form,
      socket.assigns.strategy,
      socket.assigns.strategy.resettable.request_password_reset_action_name,
      params,
      "If this user exists in our system, you will be contacted with password reset instructions shortly."
    )
  end

  def handle_event("submit", params, %{assigns: %{mode: :magic}} = socket) do
    params = get_params(params, socket.assigns.subject_name)

    submit_and_reset(
      socket,
      :magic_form,
      socket.assigns.magic_strategy,
      socket.assigns.magic_strategy.request_action_name,
      params,
      "If this user exists, we've sent a sign-in link to that email address."
    )
  end

  defp submit_and_reset(socket, form_key, strategy, action_name, params, flash_message) do
    form = Map.fetch!(socket.assigns, form_key)

    case Form.submit(form, params: params) do
      {:ok, _result} -> :ok
      :ok -> :ok
      {:error, _form} -> :ok
    end

    socket =
      socket
      |> assign(form_key, build_form(strategy, action_name, socket))
      |> put_flash!(:info, flash_message)

    {:noreply, socket}
  end

  defp current_email(form), do: Form.value(form, :email) || ""

  defp get_params(params, subject_name), do: Map.get(params, to_string(subject_name), %{})
end
