defmodule MercatoWeb.Listings.ListingFormLive do
  @moduledoc """
  The one page a seller composes a listing on, whether it is new or already
  theirs.

  New and edit are the same page rather than two: a listing is the same set of
  fields either way, and only the wording, the state badge and what the primary
  action does differ.

  The form validates as the seller types, so a refusal lands on the field that
  caused it, and saving does what the primary action says: a draft goes on
  offer, anything published before is only saved. A photo can be added,
  removed and promoted to cover, though only once the listing exists to attach
  one to, a listing can be taken off offer and put back on it, and one the
  seller is done with can be removed outright. Photos can be offered before
  there is a listing to hold them: they wait until one exists. A listing
  becomes a draft as soon as it holds what a listing needs, and writes itself
  down from then on, so leaving the page costs nothing.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.Listings.PhotoGallery
  import MercatoWeb.UI.Breadcrumb
  import MercatoWeb.UI.ChoiceChips
  import MercatoWeb.UI.ListingStatusBadge
  import MercatoWeb.UI.MoneyBreakdown

  alias Mercato.Listings
  alias Mercato.Money
  alias Mercato.Payments.Deduction
  alias Mercato.Payments.SellerDeduction

  on_mount {MercatoWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:categories, categories())
     |> assign(:conditions, conditions())
     |> assign(:gallery_error, nil)
     |> allow_upload(:photos,
       # Every limit is the marketplace's, so the upload refuses on the same
       # terms the gallery does rather than on a second set written here.
       accept: Listings.image_types(),
       max_entries: Listings.max_images(),
       max_file_size: Listings.image_max_bytes(),
       auto_upload: true,
       progress: &stored/3
     )}
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
    |> assign_deductions()
    |> assign_form()
  end

  defp load_listing(socket, %{"id" => id}) do
    case Listings.get_my_listing(id, actor: socket.assigns.current_scope.user) do
      # Sold is terminal, so there is nothing here to compose: the listing is
      # the record of a sale rather than something still being offered.
      {:ok, %{status: :sold}} ->
        socket
        |> put_flash(:info, gettext("That listing has sold, so it can no longer be changed."))
        |> push_navigate(to: ~p"/users/me/listings")

      {:ok, listing} ->
        socket
        |> assign(:listing, listing)
        |> assign_deductions()
        |> assign_form()

      {:error, _reason} ->
        socket
        |> put_flash(:error, gettext("That listing is not one of yours."))
        |> push_navigate(to: ~p"/users/me/listings")
    end
  end

  defp assign_form(socket) do
    opts = [
      actor: socket.assigns.current_scope.user,
      as: "listing",
      transform_params: &to_minor/2,
      transform_errors: &readable/2
    ]

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

  # A price that could not be read never reaches the attribute as a number, so
  # Ash refuses it as the wrong sort of thing and says only that it is invalid.
  # The seller typed an amount, so they are shown one instead.
  defp readable(_changeset, %{field: :price, message: "is invalid"}) do
    [{:price, "must be an amount, like 24.99", []}]
  end

  # Everything else stands, including the marketplace's own floor: a price it
  # could read but will not take is a different complaint.
  defp readable(_changeset, error), do: error

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
    Enum.map(Listings.conditions(), &{Listings.condition_label(&1), &1})
  end

  @impl true
  def handle_event("validate", %{"listing" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form, params)

    {:noreply, socket |> assign(:form, form) |> keeps_itself()}
  end

  def handle_event("save", %{"listing" => listing_params} = params, socket) do
    # Read before the save, so the action taken is the one the button was named
    # for rather than the one the saved listing happens to warrant afterwards.
    # Finishing later is the same save minus the offering.
    offering? = params["intent"] != "draft" and offering?(socket.assigns.listing)

    case AshPhoenix.Form.submit(socket.assigns.form, params: listing_params) do
      {:ok, listing} ->
        {:noreply, saved(socket, listing, offering?)}

      # The fields carry the detail. The flash is there because the seller
      # pressed something and would otherwise be told nothing happened by
      # nothing happening.
      {:error, form} ->
        {:noreply,
         socket
         |> assign(:form, form)
         |> put_flash(
           :error,
           gettext("This listing is not ready yet — see what is marked below.")
         )}
    end
  end

  def handle_event("cancel_photo", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("make_cover", %{"id" => id}, socket) do
    with %{} = image <- photo(socket, id),
         {:ok, _promoted} <-
           Listings.set_listing_image_cover(image, actor: socket.assigns.current_scope.user) do
      {:noreply, still_writing(socket, socket.assigns.listing)}
    else
      _refused ->
        {:noreply, put_flash(socket, :error, gettext("That photo could not be made the cover."))}
    end
  end

  def handle_event("remove_photo", %{"id" => id}, socket) do
    with %{} = image <- photo(socket, id),
         :ok <- Listings.delete_listing_image(image, actor: socket.assigns.current_scope.user) do
      {:noreply, still_writing(socket, socket.assigns.listing)}
    else
      # Refusing a removal is the gallery's own business — most often a listing
      # on offer that would be left with too few photos to stay there.
      {:error, error} -> {:noreply, assign(socket, :gallery_error, about_the_photo(error))}
      _missing -> {:noreply, socket}
    end
  end

  def handle_event("delete", _params, socket) do
    listing = socket.assigns.listing

    case Listings.delete_listing(listing, actor: socket.assigns.current_scope.user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("“%{title}” was removed.", title: listing.title))
         |> push_navigate(to: ~p"/users/me/listings")}

      # Almost always a listing sold since the page was opened: a sale outlives
      # the seller's wish to be rid of it, so the listing stays as its record.
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("That listing could not be removed."))}
    end
  end

  def handle_event("resume", _params, socket) do
    case Listings.resume_listing(socket.assigns.listing, actor: socket.assigns.current_scope.user) do
      {:ok, resumed} ->
        {:noreply,
         socket
         |> still_writing(resumed)
         |> put_flash(:info, gettext("This listing is back on offer."))}

      # Most often a gallery stripped below the minimum while the listing was
      # off offer, which is the gallery's refusal to make rather than the page's.
      {:error, error} ->
        {:noreply, relist_refused(socket, error)}
    end
  end

  def handle_event("pause", _params, socket) do
    case Listings.pause_listing(socket.assigns.listing, actor: socket.assigns.current_scope.user) do
      {:ok, paused} ->
        {:noreply,
         socket
         |> still_writing(paused)
         |> put_flash(
           :info,
           gettext("This listing is paused. Buyers cannot see it until you relist it.")
         )}

      # Almost always a listing that moved on elsewhere between the page being
      # opened and the control being pressed, so what is on screen is stale.
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("That listing could not be paused."))}
    end
  end

  # Nothing was written, so nothing is undone — the stored listing is simply
  # read again, and the form is built afresh from it.
  def handle_event("discard", _params, socket) do
    {:noreply,
     socket
     |> reload(socket.assigns.listing)
     |> put_flash(:info, gettext("Changes discarded."))}
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
    case Listings.publish_listing(listing, actor: socket.assigns.current_scope.user) do
      {:ok, published} ->
        socket
        |> reload(published)
        |> put_flash(:info, gettext("Your listing is on offer."))
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
  defp kept(%{status: :draft}), do: gettext("Draft saved.")
  defp kept(_listing), do: gettext("Changes saved.")

  defp relist_refused(socket, error) do
    case gallery_error(error) do
      nil -> put_flash(socket, :error, gettext("That listing could not go back on offer."))
      message -> assign(socket, :gallery_error, message)
    end
  end

  # The listing is saved either way, so what was written is never lost — only
  # the offering of it is refused, and the gallery is where that is said.
  defp refused(socket, error) do
    case gallery_error(error) do
      nil -> put_flash(socket, :error, gettext("That listing could not go on offer."))
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
    "Add at least #{photos} to put this on offer. Nothing else you wrote was lost."
  end

  # A draft is the seller's own workspace, so it writes itself down as they go
  # and leaving the page costs them nothing. Anything that has been on offer is
  # saved only when asked: what buyers are looking at should not follow a
  # half-finished thought.
  defp keeps_itself(%{assigns: %{listing: %{status: :draft}, form: form}} = socket) do
    if form.source.valid?, do: save_quietly(form)

    socket
  end

  # Nothing has been written yet, so the first save is the one that makes the
  # listing. It happens the moment there is a listing to make — which is also
  # the moment the gallery has something to attach a photo to.
  defp keeps_itself(%{assigns: %{listing: nil, form: form}} = socket) do
    with true <- form.source.valid?,
         {:ok, draft} <- save_quietly(form) do
      refused = attach_waiting(socket, draft)

      socket
      |> still_writing(draft)
      |> waiting_refused(refused)
      |> at_its_own_address(draft)
    else
      _not_yet -> socket
    end
  end

  defp keeps_itself(socket), do: socket

  # Nothing is reported either way. What the seller typed is already judged on
  # the page, and a refusal from the database is not theirs to answer for — the
  # save they ask for is where anything wrong with the listing is said.
  defp save_quietly(form), do: AshPhoenix.Form.submit(form, params: form.source.raw_params)

  # The photos offered while there was nowhere to put them, stored now in the
  # order they were offered, so the first one the seller chose is the cover.
  defp attach_waiting(socket, listing) do
    socket
    |> consume_uploaded_entries(:photos, fn %{path: path}, entry ->
      {:ok,
       attach(listing, File.read!(path), entry.client_name, socket.assigns.current_scope.user)}
    end)
    |> Enum.find_value(&(&1 != :ok && &1))
  end

  defp attach(listing, bytes, filename, actor) do
    case Listings.add_listing_image(
           %{listing_id: listing.id, image: bytes, filename: filename},
           actor: actor
         ) do
      {:ok, _image} -> :ok
      {:error, error} -> about_the_photo(error)
    end
  end

  # Applied after the listing is read back, since reading it back is what clears
  # whatever the gallery was last complaining about.
  defp waiting_refused(socket, nil), do: socket
  defp waiting_refused(socket, message), do: assign(socket, :gallery_error, message)

  # Consumed only once the whole file has arrived; a part-uploaded photo is
  # nothing the gallery can be given.
  defp stored(:photos, %{done?: false}, socket), do: {:noreply, socket}

  # Nothing to attach it to yet, so it is left where it is. LiveView keeps the
  # file until the listing exists or the seller closes the page, and neither
  # storage nor the gallery hears about it in the meantime.
  defp stored(:photos, _entry, %{assigns: %{listing: nil}} = socket), do: {:noreply, socket}

  defp stored(:photos, entry, socket) do
    listing = socket.assigns.listing
    bytes = consume_uploaded_entry(socket, entry, &{:ok, File.read!(&1.path)})

    case attach(listing, bytes, entry.client_name, socket.assigns.current_scope.user) do
      :ok -> {:noreply, still_writing(socket, listing)}
      message -> {:noreply, assign(socket, :gallery_error, message)}
    end
  end

  defp photo(%{assigns: %{listing: %{images: images}}}, id) when is_list(images) do
    Enum.find(images, &(&1.id == id))
  end

  defp photo(_socket, _id), do: nil

  # The domain writes these to follow a field name, so they are given a subject
  # rather than restated here: a sentence invented at this layer would drift
  # from what the gallery actually refuses. Translating first fills in whatever
  # value the refusal names, which the message carries separately.
  defp about_the_photo(%Ash.Error.Invalid{errors: [%{message: message} = error | _]})
       when is_binary(message) do
    gettext("That photo %{problem}.",
      problem: translate_error({message, Map.get(error, :vars, [])})
    )
  end

  defp about_the_photo(_error), do: gettext("That photo could not be added.")

  # Pausing changes what the listing is, not what the seller is part-way through
  # writing. Reading it back rebuilds the form, so whatever was typed is put
  # over the top of the fresh one rather than quietly thrown away.
  defp still_writing(socket, listing) do
    typed = socket.assigns.form.source.raw_params
    socket = reload(socket, listing)

    case typed do
      nil -> socket
      typed -> assign(socket, :form, AshPhoenix.Form.validate(socket.assigns.form, typed))
    end
  end

  # Read back rather than kept as the action returned it, so the gallery and
  # the price are loaded as every other way into this page has them.
  defp reload(socket, listing) do
    listing =
      case Listings.get_my_listing(listing.id, actor: socket.assigns.current_scope.user) do
        {:ok, reloaded} -> reloaded
        {:error, _reason} -> listing
      end

    socket
    |> assign(:listing, listing)
    |> assign(:gallery_error, nil)
    |> assign_deductions()
    |> assign_form()
  end

  # What this listing owes: the copy it took when it was made, so an operator
  # raising the commission since then leaves what is on screen alone. A listing
  # that does not exist yet owes what the marketplace deducts today, which is
  # the copy it will take the moment it becomes a draft.
  defp assign_deductions(socket) do
    assign(socket, :deductions, deductions(socket.assigns.listing))
  end

  defp deductions(nil), do: SellerDeduction.snapshot()
  defp deductions(%{deductions: deductions}), do: deductions

  # Only a listing just made needs its address changed. Patched rather than
  # navigated, so the page stays and keeps what the save had to say.
  defp at_its_own_address(%{assigns: %{live_action: :new}} = socket, listing) do
    push_patch(socket, to: ~p"/listings/#{listing.id}/edit")
  end

  defp at_its_own_address(socket, _listing), do: socket

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :payout, payout(assigns))

    ~H"""
    <Layouts.app
      categories={@search_categories}
      cart_count={@cart_count}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/users/me/listings"}
    >
      <div id="listing-form-page" class="flex flex-col gap-6">
        <.breadcrumb items={trail(@listing)} />

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
          phx-debounce="600"
          class="grid grid-cols-1 items-start gap-5 lg:grid-cols-[minmax(0,1fr)_21rem]"
        >
          <div class="flex flex-col gap-5 min-w-0">
            <.photo_gallery
              images={images(@listing)}
              min={Listings.min_images()}
              max={Listings.max_images()}
              error={@gallery_error}
              upload={@uploads.photos}
            />

            <.card class="flex flex-col gap-3.5">
              <section aria-labelledby="about-heading" class="flex flex-col gap-3.5">
                <h2 id="about-heading" class="text-title-lg font-bold text-ink-900 dark:text-white">
                  {gettext("About the item")}
                </h2>

                <.input
                  field={@form[:title]}
                  type="text"
                  label={gettext("Title")}
                  required
                  placeholder={gettext("e.g. Eames-style lounge chair, walnut")}
                />
                <p class="-mt-1 text-caption-md text-ink-500">
                  {gettext("Say what it is first, then the detail that matters most.")}
                </p>

                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  rows="6"
                  placeholder={gettext("Age, materials, dimensions, any marks or repairs.")}
                />
                <p class="-mt-1 text-caption-md text-ink-500">
                  {gettext("Optional, but buyers ask fewer questions when this is thorough.")}
                </p>
              </section>
            </.card>
          </div>

          <div class="flex flex-col gap-5 min-w-0 lg:sticky lg:top-6">
            <.card class="flex flex-col gap-3.5">
              <section aria-labelledby="price-heading" class="flex flex-col gap-3.5">
                <h2 id="price-heading" class="text-title-lg font-bold text-ink-900 dark:text-white">
                  {gettext("Price and stock")}
                </h2>

                <div id="listing-price-field" class="flex flex-col">
                  <span class="text-body-sm font-medium text-ink-700 mb-1">
                    {gettext("Price (%{symbol})", symbol: Money.symbol(Listings.currency()))}
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

                <%!-- Under the price rather than beside the publish button:
                      it is the consequence of the number just typed, and a
                      seller settles on a price by reading it. --%>
                <.money_breakdown
                  :if={@payout}
                  id="listing-payout"
                  lines={@payout.lines}
                  currency={Listings.currency()}
                  total={@payout.net}
                  total_label={gettext("You keep")}
                  sign="−"
                  class="-mt-1 pt-3.5 border-t border-ink-100 dark:border-ink-700"
                >
                  <:note>
                    {gettext(
                      "Held from the moment you listed this, so a later change to what the marketplace charges leaves it alone."
                    )}
                  </:note>
                </.money_breakdown>

                <.input field={@form[:quantity]} type="number" label={gettext("Quantity")} min="0" />
                <p class="-mt-1 text-caption-md text-ink-500">
                  {gettext("Most sellers list one of a kind.")}
                </p>

                <.input
                  field={@form[:category_id]}
                  type="select"
                  label={gettext("Category")}
                  prompt="Choose a category"
                  options={@categories}
                />

                <.choice_chips
                  field={@form[:condition]}
                  label={gettext("Condition")}
                  options={@conditions}
                  clear_label={gettext("Not stated")}
                />
              </section>
            </.card>

            <.card class="flex flex-col gap-3 bg-bg-2 dark:bg-ink-900">
              <section aria-label={gettext("Save or publish")} class="flex flex-col gap-3">
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
                  {gettext("Save and finish later")}
                </.button>
                <.button
                  :if={!offering?(@listing)}
                  id="save-draft"
                  type="button"
                  phx-click="discard"
                  data-confirm={gettext("Throw away everything you have changed here?")}
                  variant="neutral"
                  full_width
                >
                  {gettext("Discard changes")}
                </.button>

                <p class="text-caption-lg text-ink-500 text-pretty">{action_help(@listing)}</p>

                <p :if={draft?(@listing)} class="text-caption-lg text-ink-500 text-pretty">
                  {gettext("Saved automatically as you type, so you can leave whenever you like.")}
                </p>

                <%!-- Offered only where it can be taken: relisting is
                      reachable from `unavailable` alone. --%>
                <.button
                  :if={@listing && @listing.status == :unavailable}
                  id="resume-listing"
                  type="button"
                  variant="tertiary"
                  size="md"
                  full_width
                  phx-click="resume"
                >
                  <.icon name="hero-arrow-path" aria-hidden="true" class="size-4" />
                  {gettext("Relist this listing")}
                </.button>

                <%!-- Offered only where it can be taken: pausing is reachable
                      from `active` alone, so a draft gets no such control. --%>
                <.button
                  :if={@listing && @listing.status == :active}
                  id="pause-listing"
                  type="button"
                  variant="tertiary"
                  size="md"
                  full_width
                  phx-click="pause"
                >
                  <.icon name="hero-pause" aria-hidden="true" class="size-4" /> {gettext(
                    "Pause this listing"
                  )}
                </.button>

                <%!-- Set apart by a rule, because everything above it keeps the
                      listing and this is the one control that does not. --%>
                <div :if={@listing} class="mt-1 pt-3.5 border-t border-ink-100 dark:border-ink-700">
                  <.button
                    id="delete-listing"
                    type="button"
                    variant="danger"
                    size="sm"
                    full_width
                    phx-click="delete"
                    data-confirm={
                      gettext(
                        "“%{title}” will be taken off Mercato, along with its photos. " <>
                          "This cannot be undone.",
                        title: @listing.title
                      )
                    }
                  >
                    {gettext("Delete this listing")}
                  </.button>
                </div>
              </section>
            </.card>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  # What the sale would leave the seller at the price as it currently reads.
  # Nothing where the marketplace deducts nothing, and nothing where there is
  # no price yet to work from — neither has anything to explain, and a price
  # the form is already refusing is not one to do arithmetic on.
  defp payout(%{deductions: []}), do: nil

  defp payout(%{deductions: deductions, form: form, listing: listing}) do
    with typed when is_binary(typed) <- price(form, listing),
         {:ok, price} when price > 0 <- Money.to_minor(typed) do
      Deduction.breakdown(deductions, price)
    else
      _no_price -> nil
    end
  end

  # What the seller typed wins over what is stored, so the re-render that
  # validates a keystroke does not undo it. Read from the untransformed params,
  # since the transformed ones hold the minor units nobody types.
  defp price(%{source: %{raw_params: %{"price" => typed}}}, _listing), do: typed
  defp price(_form, listing), do: Money.amount(listing && listing.price)

  defp draft?(%{status: :draft}), do: true
  defp draft?(_listing), do: false

  defp images(nil), do: []
  defp images(%{images: images}) when is_list(images), do: images
  defp images(_listing), do: []

  # A listing the seller already has is a level of its own in the trail, named
  # and linked, so they can read which one they are changing and step back to it
  # without saving. A listing that does not exist yet has no name to give and
  # nowhere to step back to, so the trail ends at what the page is for.
  defp trail(nil), do: selling() ++ [%{label: page_title(nil)}]

  defp trail(listing) do
    selling() ++
      [%{label: listing.title, navigate: ~p"/listings/#{listing}"}, %{label: gettext("Edit")}]
  end

  defp selling do
    [
      %{label: gettext("Home"), navigate: ~p"/"},
      %{label: gettext("Selling"), navigate: ~p"/users/me/listings"}
    ]
  end

  defp page_title(nil), do: gettext("New listing")
  defp page_title(_listing), do: gettext("Edit listing")

  defp page_subtitle(nil) do
    gettext("Everything on one page. Leave whenever you like — a draft keeps your place.")
  end

  defp page_subtitle(%{status: :active}) do
    gettext("This listing is on offer, so saved changes are visible to buyers immediately.")
  end

  defp page_subtitle(%{status: :unavailable}) do
    gettext("This listing is paused. Changes are saved, and buyers see them when you relist.")
  end

  defp page_subtitle(_listing), do: gettext("Only you can see this listing until you publish it.")

  # Publishing is the draft's action alone, whether the draft was opened fresh
  # or picked up again. A listing that has been published before saves changes,
  # even while paused — the button names what happens, not which page it is on.
  defp primary_label(%{status: :draft}), do: gettext("Publish listing")
  defp primary_label(nil), do: gettext("Publish listing")
  defp primary_label(_listing), do: gettext("Save changes")

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
