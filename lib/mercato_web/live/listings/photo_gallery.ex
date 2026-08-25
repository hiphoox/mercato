defmodule MercatoWeb.Listings.PhotoGallery do
  @moduledoc """
  The gallery editor on the listing form: the photos a listing holds, which one
  is the cover, and the tile that adds more.

  Colocated with `MercatoWeb.Listings.ListingFormLive` because it is the only
  thing that composes it — a gallery is the seller's own view of a listing's
  photos, not a shape anything else renders.

  The controls render but are not yet wired; adding, removing and promoting a
  photo land with the form's write actions.
  """
  use MercatoWeb, :html

  @doc """
  Renders the gallery section.

  `images` are the listing's images in gallery order, each carrying a `:url`
  and an `:is_cover`. An `error` puts the whole section in the error state,
  which is what a publish refused for want of a photo looks like.
  """
  attr :id, :string, default: "listing-photos"
  attr :images, :list, required: true, doc: "the listing's images, in gallery order"
  attr :min, :integer, required: true, doc: "how few images the listing may go on offer with"
  attr :max, :integer, required: true, doc: "how many the gallery holds at most"
  attr :error, :string, default: nil, doc: "why the gallery is refusing, if it is"
  attr :rest, :global

  def photo_gallery(assigns) do
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
            Photos
          </h2>
          <span class="text-caption-lg text-ink-500">{count(@images, @max)}</span>
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
          <div>
            <div class="text-body-sm font-bold">{@error}</div>
            <div class="mt-0.5 text-caption-lg">Nothing you have written was lost.</div>
          </div>
        </div>

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
                Cover
              </span>
            </div>

            <figcaption class="flex items-center justify-between gap-1.5 py-2 pl-2.5 pr-2">
              <button
                :if={!image.is_cover}
                type="button"
                id={"make-cover-#{image.id}"}
                class="px-0.5 py-1 text-caption-md font-bold text-primary-700 cursor-pointer hover:text-primary-600"
              >
                Make cover
              </button>
              <span :if={image.is_cover} class="text-caption-md text-ink-500">Cover photo</span>

              <button
                type="button"
                id={"remove-photo-#{image.id}"}
                aria-label="Remove this photo"
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

          <button
            type="button"
            id="add-photos"
            disabled={length(@images) >= @max}
            class={[
              "flex flex-col items-center justify-center gap-1.5 text-center",
              "min-h-43 md:min-h-49 p-4 rounded-md cursor-pointer",
              "border-[1.5px] border-dashed transition-colors",
              "text-ink-700 dark:text-ink-100",
              @error && "border-error",
              !@error && "border-ink-300 hover:border-primary-500 hover:text-primary-700",
              "disabled:cursor-not-allowed disabled:border-ink-100 disabled:text-ink-300"
            ]}
          >
            <.icon name="hero-camera" aria-hidden="true" class="size-6" />
            <span class="text-body-sm font-bold">Add photos</span>
            <span class="text-caption-md text-ink-500">{accepted(@max)}</span>
          </button>
        </div>
      </section>
    </.card>
    """
  end

  defp count([], _max), do: "None yet"
  defp count(images, max), do: "#{length(images)} of #{max} added"

  # A marketplace of services or digital goods sets the minimum to none, and
  # telling those sellers a photo is required would simply be wrong.
  defp advice(0) do
    "Optional here, but a photo is the first thing a buyer looks at. " <>
      "The first one is the cover shown everywhere else."
  end

  defp advice(_min) do
    "The first photo is the cover buyers see everywhere. " <>
      "Daylight and a plain background sell faster."
  end

  # Types come from the same config the upload checks against, so the promise
  # on the tile cannot drift from what the gallery actually accepts.
  defp accepted(max) do
    types =
      Mercato.Listings.image_types()
      |> Enum.map(&(&1 |> String.split("/") |> List.last() |> String.upcase()))
      |> Enum.join(", ")

    "#{types}, up to #{max}"
  end
end
