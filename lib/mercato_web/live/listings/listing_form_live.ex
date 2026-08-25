defmodule MercatoWeb.Listings.ListingFormLive do
  @moduledoc """
  The one page a seller composes a listing on, whether it is new or already
  theirs.

  New and edit are the same page rather than two: a listing is the same set of
  fields either way, and only the wording, the state badge and what the primary
  action does differ. Behaviour is specified in
  `docs/features/listings/listing-form.md`.

  The form validates as the seller types, so a refusal lands on the field that
  caused it, and saving does what the primary action says: a draft goes on
  offer, anything published before is only saved. Pausing and the gallery's
  controls are not yet wired.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Listings.PhotoGallery
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.ChoiceChips
  import MercatoWeb.UI.ListingStatusBadge

  alias Mercato.Listings
  alias Mercato.Money

  on_mount {MercatoWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:categories, categories())
     |> assign(:conditions, conditions())
     |> assign(:gallery_error, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, load_listing(socket, params)}
  end

  # The page changes its own address once it has made a listing, so the one
  # already on screen is left as it stands. Loading it afresh here would throw
  # away the form and whatever the save had to say about it.
  defp load_listing(%{assigns: %{listing: %{id: id}}} = socket, %{"id" => id}), do: socket

  # A listing the seller does not own reads as one that is not there: the form
  # could not save it either way, and saying which of the two it was would
  # confirm the existence of someone else's draft.
  defp load_listing(%{assigns: %{live_action: :new}} = socket, _params) do
    socket
    |> assign(:listing, nil)
    |> assign_form()
  end

  defp load_listing(socket, %{"id" => id}) do
    case Listings.get_my_listing(id, actor: socket.assigns.current_user) do
      # Sold is terminal, so there is nothing here to compose: the listing is
      # the record of a sale rather than something still being offered.
      {:ok, %{status: :sold}} ->
        socket
        |> put_flash(:info, "That listing has sold, so it can no longer be changed.")
        |> push_navigate(to: ~p"/my-listings")

      {:ok, listing} ->
        socket
        |> assign(:listing, listing)
        |> assign_form()

      {:error, _reason} ->
        socket
        |> put_flash(:error, "That listing is not one of yours.")
        |> push_navigate(to: ~p"/my-listings")
    end
  end

  defp assign_form(socket) do
    opts = [actor: socket.assigns.current_user, as: "listing", transform_params: &to_minor/2]

    form =
      case socket.assigns.listing do
        nil -> AshPhoenix.Form.for_create(Listings.Listing, :create, opts)
        listing -> AshPhoenix.Form.for_update(listing, :update, opts)
      end

    assign(socket, :form, to_form(form))
  end

  # The seller types major units and the listing stores minor ones. Converted
  # on the way to the changeset rather than in each handler, so validating and
  # saving both get it, and the form keeps the typed string to render back.
  defp to_minor(%{"price" => price} = params, _kind) when is_binary(price) do
    case Money.to_minor(price) do
      {:ok, minor} -> %{params | "price" => minor}
      # Passed through as typed, so an amount that is not one is refused as
      # such rather than arriving as a field the seller left blank.
      :error -> params
    end
  end

  defp to_minor(params, _kind), do: params

  # Names to show and ids to submit. The catalog is the marketplace's, so a
  # seller picks from it rather than adding to it.
  defp categories do
    Listings.list_categories!(authorize?: false)
    |> Enum.sort_by(& &1.name)
    |> Enum.map(&{&1.name, &1.id})
  end

  # Read from config rather than fixed here: a marketplace replaces the list,
  # and one selling services or digital goods empties it, which renders no
  # condition control at all.
  defp conditions do
    Enum.map(Listings.conditions(), &{humanize_condition(&1), &1})
  end

  defp humanize_condition(value) do
    value |> String.replace("_", " ") |> String.capitalize()
  end

  @impl true
  def handle_event("validate", %{"listing" => params}, socket) do
    {:noreply, assign(socket, :form, AshPhoenix.Form.validate(socket.assigns.form, params))}
  end

  def handle_event("save", %{"listing" => listing_params} = params, socket) do
    # Read before the save, so the action taken is the one the button was named
    # for rather than the one the saved listing happens to warrant afterwards.
    # Finishing later is the same save minus the offering.
    offering? = params["intent"] != "draft" and offering?(socket.assigns.listing)

    case AshPhoenix.Form.submit(socket.assigns.form, params: listing_params) do
      {:ok, listing} -> {:noreply, saved(socket, listing, offering?)}
      {:error, form} -> {:noreply, assign(socket, :form, form)}
    end
  end

  # Nothing was written, so nothing is undone — the stored listing is simply
  # read again, and the form is built afresh from it.
  def handle_event("discard", _params, socket) do
    {:noreply,
     socket
     |> reload(socket.assigns.listing)
     |> put_flash(:info, "Changes discarded.")}
  end

  # A draft goes on offer when it is saved, whether it was opened fresh or
  # picked up again. Anything published before is only saved, even while
  # paused — the same rule the primary action is labelled by.
  defp offering?(nil), do: true
  defp offering?(%{status: :draft}), do: true
  defp offering?(_listing), do: false

  defp saved(socket, listing, false) do
    socket
    |> reload(listing)
    |> put_flash(:info, kept(listing))
    |> at_its_own_address(listing)
  end

  defp saved(socket, listing, true) do
    case Listings.publish_listing(listing, actor: socket.assigns.current_user) do
      {:ok, published} ->
        socket
        |> reload(published)
        |> put_flash(:info, "Your listing is on offer.")
        |> at_its_own_address(published)

      {:error, error} ->
        socket
        |> reload(listing)
        |> put_flash(:info, kept(listing))
        |> refused(error)
        |> at_its_own_address(listing)
    end
  end

  # A draft is worth saying was saved, since nothing else on the page shows it
  # happened; an edit to a listing already on offer is just a change.
  defp kept(%{status: :draft}), do: "Draft saved."
  defp kept(_listing), do: "Changes saved."

  # The listing is saved either way, so what was written is never lost — only
  # the offering of it is refused, and the gallery is where that is said.
  defp refused(socket, error) do
    case gallery_error(error) do
      nil -> put_flash(socket, :error, "That listing could not go on offer.")
      message -> assign(socket, :gallery_error, message)
    end
  end

  defp gallery_error(%Ash.Error.Invalid{errors: errors}) do
    if Enum.any?(errors, &about_the_gallery?/1) do
      photos_wanted(Listings.min_images())
    end
  end

  defp gallery_error(_error), do: nil

  # Both spellings, because which one an error carries depends on whether it
  # was raised against a single attribute or against the change as a whole.
  defp about_the_gallery?(error) do
    :images in (List.wrap(Map.get(error, :field)) ++ Map.get(error, :fields, []))
  end

  defp photos_wanted(1), do: wanted("1 photo")
  defp photos_wanted(min), do: wanted("#{min} photos")

  defp wanted(photos) do
    "Add at least #{photos} to put this on offer. Everything else you wrote is saved."
  end

  # Read back rather than kept as the action returned it, so the gallery and
  # the price are loaded as every other way into this page has them.
  defp reload(socket, listing) do
    listing =
      case Listings.get_my_listing(listing.id, actor: socket.assigns.current_user) do
        {:ok, reloaded} -> reloaded
        {:error, _reason} -> listing
      end

    socket
    |> assign(:listing, listing)
    |> assign(:gallery_error, nil)
    |> assign_form()
  end

  # Only a listing just made needs its address changed. Patched rather than
  # navigated, so the page stays and keeps what the save had to say.
  defp at_its_own_address(%{assigns: %{live_action: :new}} = socket, listing) do
    push_patch(socket, to: ~p"/listings/#{listing.id}/edit")
  end

  defp at_its_own_address(socket, _listing), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={assigns[:current_scope]}
      current_user={@current_user}
      admin?={@admin?}
      current_path={~p"/my-listings"}
    >
      <div id="listing-form-page" class="flex flex-col gap-6">
        <.breadcrumb items={[
          %{label: "Home", navigate: ~p"/"},
          %{label: "Selling", navigate: ~p"/my-listings"},
          %{label: page_title(@listing)}
        ]} />

        <.header>
          <span class="inline-flex items-center gap-2.5 flex-wrap">
            {page_title(@listing)}
            <.listing_status_badge :if={@listing} id="listing-status" status={@listing.status} />
          </span>
          <:subtitle>{page_subtitle(@listing)}</:subtitle>
        </.header>

        <%!-- One markup tree, switched in CSS: the side column becomes a third
              column from lg up and stacks below it, without a re-render. --%>
        <.form
          for={@form}
          id="listing-form"
          phx-change="validate"
          phx-submit="save"
          class="grid grid-cols-1 items-start gap-5 lg:grid-cols-[minmax(0,1fr)_21rem]"
        >
          <div class="flex flex-col gap-5 min-w-0">
            <.photo_gallery
              images={images(@listing)}
              min={Listings.min_images()}
              max={Listings.max_images()}
              error={@gallery_error}
            />

            <.card class="flex flex-col gap-3.5">
              <section aria-labelledby="about-heading" class="flex flex-col gap-3.5">
                <h2 id="about-heading" class="text-title-lg font-bold text-ink-900 dark:text-white">
                  About the item
                </h2>

                <.input
                  field={@form[:title]}
                  type="text"
                  label="Title"
                  required
                  placeholder="e.g. Eames-style lounge chair, walnut"
                />
                <p class="-mt-1 text-caption-md text-ink-500">
                  Say what it is first, then the detail that matters most.
                </p>

                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Description"
                  rows="6"
                  placeholder="Age, materials, dimensions, any marks or repairs."
                />
                <p class="-mt-1 text-caption-md text-ink-500">
                  Optional, but buyers ask fewer questions when this is thorough.
                </p>
              </section>
            </.card>
          </div>

          <div class="flex flex-col gap-5 min-w-0 lg:sticky lg:top-6">
            <.card class="flex flex-col gap-3.5">
              <section aria-labelledby="price-heading" class="flex flex-col gap-3.5">
                <h2 id="price-heading" class="text-title-lg font-bold text-ink-900 dark:text-white">
                  Price and stock
                </h2>

                <div id="listing-price-field" class="flex flex-col">
                  <span class="text-body-sm font-medium text-ink-700 mb-1">
                    Price ({Money.symbol(Listings.currency())})
                  </span>
                  <%!-- Shown in major units because that is how a seller
                        thinks of a price; the listing stores minor units. --%>
                  <.input
                    field={@form[:price]}
                    type="text"
                    inputmode="decimal"
                    value={price(@form, @listing)}
                    placeholder="0.00"
                    required
                  />
                </div>

                <.input field={@form[:quantity]} type="number" label="Quantity" min="0" />
                <p class="-mt-1 text-caption-md text-ink-500">
                  Most sellers list one of a kind.
                </p>

                <.input
                  field={@form[:category_id]}
                  type="select"
                  label="Category"
                  prompt="Choose a category"
                  options={@categories}
                />

                <.choice_chips
                  field={@form[:condition]}
                  label="Condition"
                  options={@conditions}
                  clear_label="Not stated"
                />
              </section>
            </.card>

            <.card class="flex flex-col gap-3 bg-bg-2 dark:bg-ink-900">
              <section aria-label="Save or publish" class="flex flex-col gap-3">
                <.button id="publish-listing" type="submit" name="intent" value="offer" full_width>
                  {primary_label(@listing)}
                </.button>

                <%!-- A listing not yet on offer can be put down and picked up
                      again. One already on offer has nothing to hold back, so
                      the same slot offers throwing away what was typed. --%>
                <.button
                  :if={offering?(@listing)}
                  id="save-draft"
                  type="submit"
                  name="intent"
                  value="draft"
                  variant="neutral"
                  full_width
                >
                  Save and finish later
                </.button>
                <.button
                  :if={!offering?(@listing)}
                  id="save-draft"
                  type="button"
                  phx-click="discard"
                  data-confirm="Throw away everything you have changed here?"
                  variant="neutral"
                  full_width
                >
                  Discard changes
                </.button>

                <p class="text-caption-lg text-ink-500 text-pretty">{action_help(@listing)}</p>

                <%!-- Offered only where it can be taken: pausing is reachable
                      from `active` alone, so a draft gets no such control. --%>
                <button
                  :if={@listing && @listing.status == :active}
                  type="button"
                  id="pause-listing"
                  class="py-0.5 text-left text-body-sm font-semibold text-primary-700 cursor-pointer hover:text-primary-600"
                >
                  Pause this listing instead
                </button>
              </section>
            </.card>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # What the seller typed wins over what is stored, so the re-render that
  # validates a keystroke does not undo it. Read from the untransformed params,
  # since the transformed ones hold the minor units nobody types.
  defp price(%{source: %{raw_params: %{"price" => typed}}}, _listing), do: typed
  defp price(_form, listing), do: Money.amount(listing && listing.price)

  defp images(nil), do: []
  defp images(%{images: images}) when is_list(images), do: images
  defp images(_listing), do: []

  defp page_title(nil), do: "New listing"
  defp page_title(_listing), do: "Edit listing"

  defp page_subtitle(nil) do
    "Everything on one page. Leave whenever you like — a draft keeps your place."
  end

  defp page_subtitle(%{status: :active}) do
    "This listing is on offer, so saved changes are visible to buyers immediately."
  end

  defp page_subtitle(%{status: :unavailable}) do
    "This listing is paused. Changes are saved, and buyers see them when you relist."
  end

  defp page_subtitle(_listing), do: "Only you can see this listing until you publish it."

  # Publishing is the draft's action alone, whether the draft was opened fresh
  # or picked up again. A listing that has been published before saves changes,
  # even while paused — the button names what happens, not which page it is on.
  defp primary_label(%{status: :draft}), do: "Publish listing"
  defp primary_label(nil), do: "Publish listing"
  defp primary_label(_listing), do: "Save changes"

  defp action_help(%{status: :active}) do
    "Buyers who saved this listing are not notified of a change."
  end

  defp action_help(%{status: :unavailable}) do
    "This listing stays hidden from buyers until you relist it."
  end

  defp action_help(_listing) do
    help =
      case Listings.min_images() do
        0 -> "a title and a price"
        1 -> "at least one photo, a title, and a price"
        min -> "at least #{min} photos, a title, and a price"
      end

    "Publishing needs #{help}."
  end
end
