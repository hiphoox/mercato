defmodule MercatoWeb.ProfileLive do
  @moduledoc """
  Account settings page: name, handle, avatar, password, and account deletion —
  each its own independent form/submit, so a failure in one section never
  blocks another.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Avatar
  import MercatoWeb.UI.Breadcrumb

  alias Mercato.Accounts

  on_mount {MercatoWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(:user, user)
      |> assign(:name_form, name_form(user))
      |> assign(:handle_form, handle_form(user))
      |> assign(:security_form, security_form(user))
      |> assign(:delete_form, delete_form())
      |> assign(:delete_confirmed?, false)
      |> assign(:delete_error, nil)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_avatar_progress/3
      )

    {:ok, socket}
  end

  defp name_form(user) do
    user
    |> AshPhoenix.Form.for_update(:update_profile_info,
      domain: Accounts,
      as: "name",
      actor: user
    )
    |> to_form()
  end

  defp handle_form(user) do
    user
    |> AshPhoenix.Form.for_update(:update_handle, domain: Accounts, as: "handle", actor: user)
    |> to_form()
  end

  defp security_form(user) do
    user
    |> AshPhoenix.Form.for_update(:change_password, domain: Accounts, as: "security", actor: user)
    |> to_form()
  end

  # A plain form, not an AshPhoenix one: nothing here is submitted to the
  # action. The typed handle exists only to make the user spell out which
  # account they are erasing.
  defp delete_form(params \\ %{"handle" => ""}), do: to_form(params, as: "delete")

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/users/me/profile"}
    >
      <div class="flex flex-col gap-6">
        <.breadcrumb items={[
          %{label: gettext("Home"), navigate: ~p"/"},
          %{label: gettext("Account settings")}
        ]} />

        <.header>
          {gettext("Account settings")}
          <:subtitle>{gettext("Manage your profile and security")}</:subtitle>
        </.header>
      </div>

      <div class="flex flex-col items-center gap-8 max-w-[560px] mx-auto py-8">
        <.card class="w-full flex flex-col gap-5">
          <div>
            <h2 class="text-title-lg font-bold text-ink-900">{gettext("Name")}</h2>
            <p class="text-caption-lg text-ink-500 mt-0.5">
              {gettext("Your first and last name as shown to other members.")}
            </p>
          </div>
          <.form
            :let={form}
            id="name-form"
            for={@name_form}
            phx-change="validate_name"
            phx-submit="save_name"
            class="flex flex-col gap-5"
          >
            <div class="grid grid-cols-2 gap-3">
              <.input field={form[:first_name]} label={gettext("First name")} required />
              <.input field={form[:last_name]} label={gettext("Last name")} required />
            </div>
            <.button type="submit" variant="primary" full_width phx-disable-with={gettext("Saving…")}>
              {gettext("Save name")}
            </.button>
          </.form>
        </.card>

        <.card class="w-full flex flex-col gap-5">
          <div>
            <h2 class="text-title-lg font-bold text-ink-900">{gettext("Handle")}</h2>
            <p class="text-caption-lg text-ink-500 mt-0.5">
              {gettext("Your public @handle, used across Mercato.")}
            </p>
          </div>
          <.form
            :let={form}
            id="handle-form"
            for={@handle_form}
            phx-change="validate_handle"
            phx-submit="save_handle"
            class="flex flex-col gap-5"
          >
            <.input field={form[:handle]} label={gettext("Handle")} required />
            <.button type="submit" variant="primary" full_width phx-disable-with={gettext("Saving…")}>
              {gettext("Save handle")}
            </.button>
          </.form>
        </.card>

        <.card class="w-full flex flex-col gap-5">
          <div>
            <h2 class="text-title-lg font-bold text-ink-900">{gettext("Avatar")}</h2>
            <p class="text-caption-lg text-ink-500 mt-0.5">
              {gettext("JPG or PNG, up to 5MB. Saves automatically.")}
            </p>
          </div>
          <form id="avatar-form" phx-change="noop" phx-submit="noop" class="flex items-center gap-5">
            <div class="relative w-[72px] h-[72px] shrink-0">
              <.avatar
                name={Accounts.full_name(@user)}
                src={@user.avatar_url}
                size={72}
              />
              <div
                :if={@uploads.avatar.entries != []}
                class="absolute inset-0 rounded-full bg-ink-900/45 flex items-center justify-center"
              >
                <.icon name="hero-arrow-path" class="size-5 text-white animate-spin" />
              </div>
            </div>
            <div class="flex flex-col gap-2">
              <label class="inline-flex items-center justify-center h-9 px-3.5 rounded-md bg-ink-100 text-ink-700 font-semibold text-body-sm cursor-pointer w-fit">
                {avatar_button_label(@uploads.avatar.entries, @user.avatar_url)}
                <.live_file_input upload={@uploads.avatar} class="hidden" />
              </label>
              <p class="text-caption-md text-ink-500">{gettext("Square images look best.")}</p>
              <p :for={err <- upload_errors(@uploads.avatar)} class="text-caption-md text-error">
                {error_to_string(err)}
              </p>
            </div>
          </form>
        </.card>

        <.card class="w-full flex flex-col gap-5 border-[1.5px] border-ink-300 shadow-md">
          <div class="flex items-center gap-2.5">
            <.icon name="hero-shield-check" class="size-5 text-ink-900" />
            <h2 class="text-title-lg font-bold text-ink-900 flex-1">{gettext("Security")}</h2>
            <span class="inline-flex items-center h-6 px-2 rounded-full bg-ink-100 text-ink-700 text-caption-md font-semibold">
              {gettext("Sensitive")}
            </span>
          </div>
          <p class="text-caption-lg text-ink-500 -mt-3">
            {gettext("Choose a strong password you don't use anywhere else.")}
          </p>
          <.form
            :let={form}
            id="security-form"
            for={@security_form}
            phx-change="validate_security"
            phx-submit="save_security"
            class="flex flex-col gap-4"
          >
            <.input
              field={form[:current_password]}
              type="password"
              label={gettext("Current password")}
              required
            />
            <.input field={form[:password]} type="password" label={gettext("New password")} required />
            <.input
              field={form[:password_confirmation]}
              type="password"
              label={gettext("Confirm new password")}
              required
            />
            <.button
              type="submit"
              variant="primary"
              full_width
              phx-disable-with={gettext("Updating…")}
            >
              {gettext("Update password")}
            </.button>
          </.form>
        </.card>

        <.card class="w-full flex flex-col gap-5 border-[1.5px] border-error/40 shadow-md">
          <div class="flex items-center gap-2.5">
            <.icon name="hero-exclamation-triangle" class="size-5 text-error-text" />
            <h2 class="text-title-lg font-bold text-error-text flex-1">
              {gettext("Delete account")}
            </h2>
          </div>
          <p class="text-caption-lg text-ink-500 -mt-3">
            {gettext(
              "Deleting your account signs you out for good and erases your name, handle, " <>
                "email, and photo. Your past orders stay on record, without your details " <>
                "attached. This cannot be undone."
            )}
          </p>
          <.form
            :let={form}
            id="delete-account-form"
            for={@delete_form}
            phx-change="validate_delete"
            phx-submit="delete_account"
            class="flex flex-col gap-4"
          >
            <.input
              field={form[:handle]}
              label={gettext("Type @%{handle} to confirm", handle: @user.handle)}
              autocomplete="off"
            />
            <p :if={@delete_error} class="text-caption-md text-error-text">{@delete_error}</p>
            <.button
              id="delete-account-button"
              type="submit"
              variant="danger"
              full_width
              disabled={!@delete_confirmed?}
              phx-disable-with={gettext("Deleting…")}
            >
              {gettext("Delete my account")}
            </.button>
          </.form>
        </.card>

        <.link
          id="sign-out-link"
          href={~p"/sign-out"}
          method="delete"
          class="text-error-text hover:text-error font-medium text-body-sm"
        >
          {gettext("Sign out")}
        </.link>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate_name", %{"name" => params}, socket) do
    {:noreply,
     assign(socket, :name_form, AshPhoenix.Form.validate(socket.assigns.name_form, params))}
  end

  def handle_event("save_name", %{"name" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.name_form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:name_form, name_form(user))
         |> put_flash(:info, gettext("Name updated."))}

      {:error, form} ->
        {:noreply, assign(socket, :name_form, form)}
    end
  end

  def handle_event("validate_handle", %{"handle" => params}, socket) do
    {:noreply,
     assign(socket, :handle_form, AshPhoenix.Form.validate(socket.assigns.handle_form, params))}
  end

  def handle_event("save_handle", %{"handle" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.handle_form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:handle_form, handle_form(user))
         |> put_flash(:info, gettext("Handle updated."))}

      {:error, form} ->
        {:noreply, assign(socket, :handle_form, form)}
    end
  end

  def handle_event("validate_security", %{"security" => params}, socket) do
    {:noreply,
     assign(
       socket,
       :security_form,
       AshPhoenix.Form.validate(socket.assigns.security_form, params)
     )}
  end

  def handle_event("save_security", %{"security" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.security_form, params: params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:security_form, security_form(user))
         |> put_flash(:info, gettext("Password updated."))}

      {:error, form} ->
        {:noreply, assign(socket, :security_form, form)}
    end
  end

  def handle_event("validate_delete", %{"delete" => params}, socket) do
    {:noreply,
     socket
     |> assign(:delete_form, delete_form(params))
     |> assign(:delete_confirmed?, confirms_handle?(socket.assigns.user, params))
     |> assign(:delete_error, nil)}
  end

  # The typed handle is re-checked on submit rather than trusted from the
  # disabled button: the button is a hint to the user, not a gate on the event.
  def handle_event("delete_account", %{"delete" => params}, socket) do
    user = socket.assigns.user

    if confirms_handle?(user, params) do
      case Accounts.delete_account(user, actor: user) do
        :ok ->
          {:noreply, redirect(socket, to: ~p"/sign-out")}

        {:error, _} ->
          {:noreply, assign(socket, :delete_error, gettext("Your account could not be deleted."))}
      end
    else
      {:noreply,
       socket
       |> assign(:delete_form, delete_form(params))
       |> assign(:delete_confirmed?, false)
       |> assign(:delete_error, gettext("That does not match your handle."))}
    end
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  # A leading @ is accepted because the label shows one; it is a prompt, not
  # part of the handle.
  defp confirms_handle?(user, params) do
    typed = params |> Map.get("handle", "") |> to_string() |> String.trim_leading("@")

    typed != "" and typed == user.handle
  end

  defp handle_avatar_progress(:avatar, entry, socket) do
    if entry.done? do
      current_user = socket.assigns.user

      user =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          {:ok, File.read!(path)}
        end)
        |> then(
          &Accounts.update_avatar!(current_user, &1, entry.client_name, actor: current_user)
        )

      {:noreply,
       socket
       |> assign(:user, user)
       |> put_flash(:info, gettext("Avatar updated."))}
    else
      {:noreply, socket}
    end
  end

  defp error_to_string(:too_large), do: gettext("Image is too large (max 5MB).")
  defp error_to_string(:not_accepted), do: gettext("Only JPG or PNG images are accepted.")
  defp error_to_string(:too_many_files), do: gettext("Only one image at a time.")
  defp error_to_string(_), do: gettext("Could not upload this image.")

  # A clause each rather than a nested conditional in the template: extraction
  # reads the source, and each state is its own message.
  defp avatar_button_label([_ | _], _avatar_url), do: gettext("Uploading…")
  defp avatar_button_label([], nil), do: gettext("Upload photo")
  defp avatar_button_label([], _avatar_url), do: gettext("Change photo")
end
