defmodule MercatoWeb.Listings.PhotoGallery do
  @moduledoc """
  The gallery editor on the listing form: the photos a listing holds, which one
  is the cover, and the tile that adds more.

  Colocated with `MercatoWeb.Listings.ListingFormLive` because it is the only
  thing that composes it — a gallery is the seller's own view of a listing's
  photos, not a shape anything else renders.

  Adding, removing and promoting a photo are the owner's events: the gallery
  renders the controls and names them, and the page that owns the listing is
  what actually changes it.
  """
  use MercatoWeb, :html

  @doc """
  Renders the gallery section.

  `images` are the listing's images in gallery order, each carrying a `:url`
  and an `:is_cover`. An `error` puts the whole section in the error state —
  a publish refused for want of a photo, or a photo the gallery would not take.

  `upload` is what the add tile offers a file to, and carries the entries still
  waiting: a photo offered before the listing exists is held rather than
  stored, and shown beside the stored ones until there is something to attach
  it to.
  """
  attr :id, :string, default: "listing-photos"
  attr :images, :list, required: true, doc: "the listing's images, in gallery order"
  attr :min, :integer, required: true, doc: "how few images the listing may go on offer with"
  attr :max, :integer, required: true, doc: "how many the gallery holds at most"
  attr :error, :string, default: nil, doc: "why the gallery is refusing, if it is"

  attr :upload, Phoenix.LiveView.UploadConfig,
    required: true,
    doc: "what a photo is offered to, and the ones still waiting to be stored"

  attr :rest, :global

  def photo_gallery(assigns) do
    assigns =
      assigns
      |> assign(:waiting, assigns.upload.entries)
      |> assign(:open?, open?(assigns))

    ~H"""
    <.card
      id={@id}
      class={[
        "flex flex-col gap-3.5",
        @error && "border-[1.5px] border-error"
      ]}
      {@rest}
    >
      <section aria-labelledby={"#{@id}-heading"} class="flex flex-col gap-3.5">
        <div class="flex items-baseline justify-between gap-3 flex-wrap">
          <h2
            id={"#{@id}-heading"}
            class="text-title-lg font-bold text-ink-900 dark:text-white"
          >
            {gettext("Photos")}
          </h2>
          <span class="text-caption-lg text-ink-500">{count(@images, @waiting, @max)}</span>
        </div>

        <p class="text-body-sm text-ink-500 text-pretty">
          {advice(@min)}
        </p>

        <div
          :if={@error}
          role="alert"
          class="flex items-start gap-2.5 px-3.5 py-3 rounded-md bg-error-bg text-error-text"
        >
          <.icon name="hero-exclamation-circle" aria-hidden="true" class="size-4.5 flex-none mt-px" />
          <div class="text-body-sm font-bold">{@error}</div>
        </div>

        <p
          :for={{_ref, refusal} <- @upload.errors}
          role="alert"
          class="flex items-center gap-2 text-body-sm text-error"
        >
          <.icon name="hero-exclamation-circle" aria-hidden="true" class="size-4.5 flex-none" />
          {refused(refusal, @max)}
        </p>

        <div class="grid grid-cols-[repeat(auto-fill,minmax(8.25rem,1fr))] gap-3 md:grid-cols-[repeat(auto-fill,minmax(9.75rem,1fr))]">
          <figure
            :for={image <- @images}
            id={"photo-#{image.id}"}
            class={
              [
                "m-0 flex flex-col overflow-hidden rounded-md bg-white dark:bg-ink-900",
                # The cover is outlined rather than labelled alone, so which photo
                # stands for the listing survives a glance at the grid.
                image.is_cover && "border-[1.5px] border-primary-500",
                !image.is_cover && "border border-ink-100 dark:border-ink-700"
              ]
            }
          >
            <div class="relative flex aspect-square items-center justify-center bg-ink-100 dark:bg-ink-700">
              <img src={image.url} alt="" class="size-full object-cover" />
              <span
                :if={image.is_cover}
                class="absolute top-2 left-2 px-2.5 py-0.5 rounded-full bg-ink-900 text-white text-caption-sm font-bold uppercase tracking-wide"
              >
                {gettext("Cover")}
              </span>
            </div>

            <figcaption class="flex items-center justify-between gap-1.5 py-2 pl-2.5 pr-2">
              <button
                :if={!image.is_cover}
                type="button"
                id={"make-cover-#{image.id}"}
                phx-click="make_cover"
                phx-value-id={image.id}
                class="px-0.5 py-1 text-caption-md font-bold text-primary-700 cursor-pointer hover:text-primary-600"
              >
                {gettext("Make cover")}
              </button>
              <span :if={image.is_cover} class="text-caption-md text-ink-500">{gettext("Cover photo")}</span>

              <button
                type="button"
                id={"remove-photo-#{image.id}"}
                phx-click="remove_photo"
                phx-value-id={image.id}
                aria-label={gettext("Remove this photo")}
                class={[
                  "flex flex-none items-center justify-center size-8 cursor-pointer",
                  "rounded-sm border border-ink-100 dark:border-ink-700 text-ink-500",
                  "transition-colors hover:bg-error-bg hover:text-error-text hover:border-error-bg",
                  "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
                ]}
              >
                <.icon name="hero-trash" aria-hidden="true" class="size-3.5" />
              </button>
            </figcaption>
          </figure>

          <%!-- Held, not stored: there is nothing to attach it to yet, so it
                is shown from the browser's own copy until there is. --%>
          <figure
            :for={entry <- @waiting}
            id={"waiting-photo-#{entry.ref}"}
            data-role="waiting"
            class="m-0 flex flex-col overflow-hidden rounded-md bg-white dark:bg-ink-900 border border-dashed border-ink-300"
          >
            <div class="relative flex aspect-square items-center justify-center bg-ink-100 dark:bg-ink-700">
              <.live_img_preview entry={entry} class="size-full object-cover" />
            </div>

            <figcaption class="flex items-center justify-between gap-1.5 py-2 pl-2.5 pr-2">
              <span class="text-caption-md text-ink-500">{gettext("Waiting")}</span>

              <button
                type="button"
                phx-click="cancel_photo"
                phx-value-ref={entry.ref}
                aria-label={gettext("Take back %{name}", name: entry.client_name)}
                class={[
                  "flex flex-none items-center justify-center size-8 cursor-pointer",
                  "rounded-sm border border-ink-100 dark:border-ink-700 text-ink-500",
                  "transition-colors hover:bg-error-bg hover:text-error-text hover:border-error-bg",
                  "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
                ]}
              >
                <.icon name="hero-x-mark" aria-hidden="true" class="size-3.5" />
              </button>
            </figcaption>
          </figure>

          <%!-- A label rather than a button: the file input it carries is what
                opens the picker, and wrapping it means no id has to be kept in
                step between the two. --%>
          <label
            id="add-photos"
            class={[
              "flex flex-col items-center justify-center gap-1.5 text-center",
              "min-h-43 md:min-h-49 p-4 rounded-md",
              "border-[1.5px] border-dashed transition-colors",
              @open? && "cursor-pointer text-ink-700 dark:text-ink-100",
              @open? && @error && "border-error",
              @open? && !@error && "border-ink-300 hover:border-primary-500 hover:text-primary-700",
              !@open? && "cursor-not-allowed border-ink-100 text-ink-300"
            ]}
          >
            <.live_file_input :if={@open?} upload={@upload} class="sr-only" />
            <.icon name="hero-camera" aria-hidden="true" class="size-6" />
            <span class="text-body-sm font-bold">{gettext("Add photos")}</span>
            <%!-- What the gallery takes is named whether or not it can take one
                  now, so the tile still answers the question it is asked. --%>
            <span class={["text-caption-md", @open? && "text-ink-500", !@open? && "text-ink-300"]}>
              {accepted(@max)}
            </span>
            <span :if={!@open?} class="text-caption-md font-bold">
              {gettext("That is all %{max} of them", max: @max)}
            </span>
          </label>
        </div>
      </section>
    </.card>
    """
  end

  # A waiting photo is counted with the stored ones: to the seller they are all
  # simply photos on the listing, whatever the gallery has managed to keep.
  defp count(images, waiting, max) do
    case length(images) + length(waiting) do
      0 -> gettext("None yet")
      held -> gettext("%{held} of %{max} added", held: held, max: max)
    end
  end

  # A marketplace of services or digital goods sets the minimum to none, and
  # telling those sellers a photo is required would simply be wrong.
  defp advice(0) do
    gettext(
      "Optional here, but a photo is the first thing a buyer looks at. " <>
        "The first one is the cover shown everywhere else."
    )
  end

  defp advice(_min) do
    gettext(
      "The first photo is the cover buyers see everywhere. " <>
        "Daylight and a plain background sell faster."
    )
  end

  # Types come from the same config the upload checks against, so the promise
  # on the tile cannot drift from what the gallery actually accepts.
  defp accepted(max) do
    types =
      Enum.map_join(Mercato.Listings.image_types(), ", ", fn type ->
        type |> String.split("/") |> List.last() |> String.upcase()
      end)

    gettext("%{types}, up to %{max}", types: types, max: max)
  end

  # Nowhere to put another once the gallery is full, counting the ones waiting.
  defp open?(%{images: images, upload: upload, max: max}) do
    length(images) + length(upload.entries) < max
  end

  # The upload refuses a file before the gallery ever sees it, so these are the
  # limits restated for the person rather than the ones the resource enforces.
  defp refused(:too_large, _max), do: gettext("That file is too large.")

  defp refused(:not_accepted, _max),
    do: gettext("That file is not one of the types accepted here.")

  defp refused(:too_many_files, max),
    do:
      ngettext("No more than 1 photo at a time.", "No more than %{count} photos at a time.", max)

  defp refused(_refusal, _max), do: gettext("That file could not be added.")
end
