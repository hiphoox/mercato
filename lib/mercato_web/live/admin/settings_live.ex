defmodule MercatoWeb.Admin.SettingsLive do
  @moduledoc """
  Marketplace settings: what the platform is priced in, what a listing may say
  about itself and show, how long a cart keeps an untouched line, and how often
  an account may rename itself.

  One row holds them all, but each section is its own form and its own submit,
  so a value one section refuses never blocks saving another. Where no row has
  been saved yet every field starts from the platform default the marketplace
  has been running on all along.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Breadcrumb

  alias Mercato.Accounts
  alias Mercato.Accounts.Setting

  on_mount {MercatoWeb.LiveUserAuth, :live_admin_required}

  # Each section is one card, one form, one submit. A list is typed as one line
  # of comma-separated values, so the field says which kind it is.
  #
  # Built per render rather than held as a module attribute: wording baked in at
  # compile time is invisible to translation extraction.
  defp sections do
    [
      %{
        key: :marketplace,
        title: gettext("Marketplace"),
        hint: gettext("What every price on this platform is denominated in."),
        submit: gettext("Save marketplace"),
        fields: [
          %{
            key: :currency,
            kind: :text,
            label: gettext("Currency"),
            hint: gettext("An ISO 4217 code, such as USD or EUR.")
          }
        ]
      },
      %{
        key: :listings,
        title: gettext("Listings"),
        hint: gettext("What a seller may say about an item, and what they may show of it."),
        submit: gettext("Save listings"),
        fields: [
          %{
            key: :listing_conditions,
            kind: :list,
            label: gettext("Conditions"),
            hint: gettext("Comma separated. Leave empty to drop the field from every listing.")
          },
          %{
            key: :listing_image_types,
            kind: :list,
            label: gettext("Image types"),
            hint: gettext("Comma separated media types a gallery accepts.")
          },
          %{
            key: :listing_image_max_bytes,
            kind: :number,
            label: gettext("Largest image (bytes)"),
            hint: gettext("The biggest file a gallery accepts.")
          },
          %{
            key: :listing_min_images,
            kind: :number,
            label: gettext("Fewest images"),
            hint: gettext("Zero lets a listing go on offer showing nothing.")
          },
          %{
            key: :listing_max_images,
            kind: :number,
            label: gettext("Most images"),
            hint: gettext("How many photos a gallery holds.")
          }
        ]
      },
      %{
        key: :cart,
        title: gettext("Cart"),
        hint: gettext("How long a buyer's intention to buy is kept."),
        submit: gettext("Save cart"),
        fields: [
          %{
            key: :cart_retention_seconds,
            kind: :days,
            label: gettext("Retention (days)"),
            hint:
              gettext("A line the buyer has not touched in this long is dropped from their cart.")
          }
        ]
      },
      %{
        key: :accounts,
        title: gettext("Accounts"),
        hint: gettext("What a member may change about their own account, and how often."),
        submit: gettext("Save accounts"),
        fields: [
          %{
            key: :handle_change_cooldown_days,
            kind: :number,
            label: gettext("Handle change cooldown (days)"),
            hint: gettext("How long an account waits between changing its @handle.")
          }
        ]
      }
    ]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_settings() |> assign_forms()}
  end

  defp assign_settings(socket) do
    {:ok, settings} = Accounts.current_settings(authorize?: false, not_found_error?: false)

    assign(socket, :settings, settings)
  end

  # Every form is rebuilt after any save, not only the one that was saved: the
  # first save is what brings the row into being, and the rest of the page has
  # to go on editing that row rather than offering to create a second.
  defp assign_forms(socket) do
    assign(socket, :forms, Map.new(sections(), &{&1.key, form_for(socket, &1)}))
  end

  defp form_for(socket, section) do
    opts = [
      actor: socket.assigns.current_scope.user,
      as: to_string(section.key),
      transform_params: &to_stored/2
    ]

    case socket.assigns.settings do
      nil -> AshPhoenix.Form.for_create(Setting, :create, opts)
      settings -> AshPhoenix.Form.for_update(settings, :update, opts)
    end
    |> to_form()
  end

  # A list is typed as one line of comma-separated values and stored as a list.
  # Done on the way to the changeset so validating and saving both get it, and
  # the form keeps what was typed to render back.
  defp to_stored(params, _kind) do
    params
    |> convert(:list, &to_list/1)
    |> convert(:days, &to_seconds/1)
  end

  defp convert(params, kind, convert) do
    Enum.reduce(keys(kind), params, fn key, params ->
      case Map.fetch(params, to_string(key)) do
        {:ok, typed} when is_binary(typed) -> Map.put(params, to_string(key), convert.(typed))
        _not_typed -> params
      end
    end)
  end

  defp keys(kind) do
    for section <- sections(), %{kind: ^kind, key: key} <- section.fields, do: key
  end

  defp to_list(typed) do
    typed
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @day_in_seconds 24 * 60 * 60

  # A window is set in whole days and held in seconds. What is not a number of
  # days is passed through as typed, so it is refused as the number it is not
  # rather than arriving as a field the operator left blank.
  defp to_seconds(typed) do
    case Integer.parse(String.trim(typed)) do
      {days, ""} -> days * @day_in_seconds
      _not_a_number -> typed
    end
  end

  defp to_days(seconds), do: div(seconds, @day_in_seconds)

  # What a field shows before anybody has typed in it: the value the platform is
  # applying, rather than a blank the operator has to guess at.
  defp value(form, settings, %{key: key, kind: :list}) do
    case Map.get(form.params, to_string(key)) do
      typed when is_binary(typed) -> typed
      _untyped -> key |> current(settings) |> Enum.join(", ")
    end
  end

  defp value(form, settings, %{key: key, kind: :days}) do
    Map.get(form.params, to_string(key)) || key |> current(settings) |> to_days()
  end

  defp value(form, settings, %{key: key}) do
    Map.get(form.params, to_string(key)) || current(key, settings)
  end

  defp current(key, %Setting{} = settings), do: Map.fetch!(settings, key)
  defp current(key, nil), do: Setting.default(key)

  @impl true
  def handle_event("validate", params, socket) do
    {section, typed} = section_params(params)
    form = AshPhoenix.Form.validate(socket.assigns.forms[section.key], typed)

    {:noreply, assign(socket, :forms, Map.put(socket.assigns.forms, section.key, form))}
  end

  def handle_event("save", params, socket) do
    {section, typed} = section_params(params)

    case AshPhoenix.Form.submit(socket.assigns.forms[section.key], params: typed) do
      {:ok, _settings} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{section} settings saved.", section: section.title))
         |> assign_settings()
         |> assign_forms()}

      # The fields carry the detail. The flash is there because the operator
      # pressed something and would otherwise be told nothing by nothing
      # happening.
      {:error, form} ->
        {:noreply,
         socket
         |> assign(:forms, Map.put(socket.assigns.forms, section.key, form))
         |> put_flash(:error, gettext("Those settings could not be saved."))}
    end
  end

  # Each form names itself after its section, so which section a submit came
  # from is read off the params rather than carried in the event name.
  defp section_params(params) do
    section = Enum.find(sections(), &Map.has_key?(params, to_string(&1.key)))

    {section, Map.fetch!(params, to_string(section.key))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      cart_count={@cart_count}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/admin/settings"}
    >
      <div class="flex flex-col gap-6">
        <.breadcrumb items={[%{label: gettext("Admin")}, %{label: gettext("Settings")}]} />

        <.header>
          {gettext("Marketplace settings")}
          <:subtitle>
            {gettext("The values this platform runs on, editable without a deploy.")}
          </:subtitle>
        </.header>
      </div>

      <div class="flex flex-col items-center gap-8 max-w-[560px] mx-auto py-8">
        <.card :for={section <- sections()} class="w-full flex flex-col gap-5">
          <div>
            <h2 class="text-title-lg font-bold text-ink-900">{section.title}</h2>
            <p class="text-caption-lg text-ink-500 mt-0.5">{section.hint}</p>
          </div>
          <.form
            :let={form}
            id={"settings-#{section.key}-form"}
            for={@forms[section.key]}
            phx-change="validate"
            phx-submit="save"
            class="flex flex-col gap-5"
          >
            <div :for={field <- section.fields} class="flex flex-col gap-1">
              <.input
                field={form[field.key]}
                type={if field.kind in [:number, :days], do: "number", else: "text"}
                value={value(@forms[section.key], @settings, field)}
                label={field.label}
              />
              <p class="text-caption-md text-ink-500">{field.hint}</p>
            </div>
            <.button type="submit" variant="primary" full_width phx-disable-with={gettext("Saving…")}>
              {section.submit}
            </.button>
          </.form>
        </.card>
      </div>
    </Layouts.app>
    """
  end
end
