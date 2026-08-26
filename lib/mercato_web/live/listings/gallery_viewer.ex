defmodule MercatoWeb.Listings.GalleryViewer do
  @moduledoc """
  A listing's photos as a buyer looks through them: one hero plate, and a strip
  to move between the rest.

  The read-only twin of `MercatoWeb.Listings.PhotoGallery`, which is the same
  photos as the seller edits them. Colocated with
  `MercatoWeb.Listings.ListingDetailLive` for the same reason that one is
  colocated with the form — a gallery is a page's own way of showing a listing,
  not a shape anything else renders.

  Choosing a photo and opening the overflow are the page's events: the viewer
  renders the controls and names them, and the page holds which photo is shown.
  """
  use MercatoWeb, :html

  # Enough to read the strip at a glance, and a fixed row keeps the panel beside
  # it at the same height however many photos the marketplace allows.
  @visible 5

  @doc """
  Renders the gallery.

  `images` are the listing's images in gallery order, each carrying a `:url`.
  `active` is the index of the photo on the hero plate, and `expanded?` says
  whether the overflow tile has been opened.

  An empty gallery renders a stated placeholder rather than an empty box: where
  the marketplace sets no minimum, a listing without photos is legal, and a
  broken-looking frame would read as a fault instead.
  """
  attr :id, :string, default: "listing-gallery"
  attr :images, :list, required: true, doc: "the listing's images, in gallery order"
  attr :alt, :string, required: true, doc: "what the photos are of"
  attr :active, :integer, default: 0, doc: "index of the photo on the hero plate"
  attr :expanded?, :boolean, default: false, doc: "whether the overflow tile has been opened"
  attr :rest, :global

  slot :badges, doc: "a state badge laid over the top-left of the hero plate"

  def gallery_viewer(assigns) do
    count = length(assigns.images)

    assigns =
      assigns
      |> assign(:count, count)
      |> assign(:hero, Enum.at(assigns.images, assigns.active))
      |> assign(:thumbs, thumbs(assigns, count))

    ~H"""
    <section id={@id} aria-label="Photos" class="flex flex-col gap-3" {@rest}>
      <div
        :if={@hero}
        id="gallery-hero"
        class={
          [
            "relative flex items-center justify-center overflow-hidden p-2",
            # The plate takes its height from the photo rather than imposing one, so
            # nothing is cropped. A floor keeps a small photo from collapsing it, and
            # a ceiling keeps a tall one from pushing the description off the screen.
            "min-h-70 max-h-[34rem] rounded-lg bg-ink-100 dark:bg-ink-700"
          ]
        }
      >
        <%!-- Width and height are left to the file: capped at the column and at the
              plate's ceiling, and never scaled up past its own size, which is what
              stretches a small photo out of shape. --%>
        <img src={@hero.url} alt={@alt} class="max-w-full max-h-[32rem] w-auto h-auto" />

        <span :if={@badges != []} class="absolute top-3.5 left-3.5">
          {render_slot(@badges)}
        </span>

        <%!-- Stepping is what a buyer reaches for while looking at the photo; the
              strip below is for jumping to a particular one. Both wrap, so neither
              ever presents a dead control at an edge. --%>
        <button
          :for={arrow <- arrows()}
          :if={@count > 1}
          type="button"
          id={arrow.id}
          phx-click={arrow.event}
          aria-label={arrow.label}
          class={[
            "absolute top-1/2 -translate-y-1/2 flex items-center justify-center size-11",
            arrow.side,
            "rounded-full bg-bg/90 dark:bg-ink-900/90 text-ink-700 dark:text-ink-100 shadow-sm",
            "cursor-pointer transition-[filter] hover:brightness-95",
            "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100"
          ]}
        >
          <.icon name={arrow.icon} aria-hidden="true" class="size-5" />
        </button>

        <%!-- The total is a trust signal of its own, so it is stated on the hero
              rather than left for the strip to imply. --%>
        <span
          :if={@count > 1}
          id="gallery-counter"
          class={[
            "absolute bottom-3.5 right-3.5 inline-flex items-center h-6.5 px-2.5 rounded-full",
            "bg-ink-900/70 text-white text-caption-md font-semibold"
          ]}
        >
          {@active + 1} / {@count}
        </span>
      </div>

      <%!-- Controls for navigating one photo are noise, and an empty strip reads
            as a missing photo. --%>
      <div
        :if={@count > 1}
        id="gallery-thumbs"
        role="group"
        aria-label="Photo thumbnails"
        class="flex gap-2.5 flex-wrap"
      >
        <button
          :for={thumb <- @thumbs}
          type="button"
          id={"gallery-thumb-#{thumb.index}"}
          phx-click={thumb.event}
          phx-value-index={thumb.index}
          aria-label={thumb.aria}
          aria-current={thumb.current? && "true"}
          class={[
            "flex-none flex items-center justify-center overflow-hidden cursor-pointer",
            "w-17 h-13 md:w-21.5 md:h-16 rounded-sm bg-ink-100 dark:bg-ink-700",
            "transition-[filter,border-color] hover:brightness-95",
            "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-primary-100",
            thumb.current? && "border-[1.5px] border-primary-500",
            !thumb.current? && "border border-ink-100 dark:border-ink-700"
          ]}
        >
          <img :if={thumb.url} src={thumb.url} alt="" class="size-full object-cover" />
          <span :if={!thumb.url} class="text-caption-md font-bold text-ink-700 dark:text-ink-100">
            {thumb.label}
          </span>
        </button>
      </div>

      <div
        :if={@count == 0}
        id="gallery-no-photos"
        class={
          [
            "flex flex-col items-center justify-center gap-2 text-center",
            "min-h-55 p-6 rounded-lg bg-bg-2 dark:bg-ink-700",
            # Dashed and untinted: a photoless listing is permitted here, and the
            # error palette would accuse the seller of something the marketplace allows.
            "border border-dashed border-ink-300"
          ]
        }
      >
        <.icon name="hero-photo" aria-hidden="true" class="size-6.5 text-ink-500" />
        <p class="text-body-md font-bold text-ink-700 dark:text-ink-100">
          No photos on this listing
        </p>
        <p class="max-w-[42ch] text-body-sm text-ink-500 text-pretty">
          This marketplace does not require them. Everything the seller wrote is below — ask for a photo before you buy if you need one.
        </p>
      </div>
    </section>
    """
  end

  defp arrows do
    [
      %{
        id: "gallery-previous",
        event: "previous_photo",
        label: "Previous photo",
        icon: "hero-chevron-left",
        side: "left-3.5"
      },
      %{
        id: "gallery-next",
        event: "next_photo",
        label: "Next photo",
        icon: "hero-chevron-right",
        side: "right-3.5"
      }
    ]
  end

  # Every thumbnail when the strip fits or has been opened; otherwise a full row
  # followed by a tile standing for the rest, which is sized like a thumbnail so
  # the row's rhythm survives.
  defp thumbs(%{images: images, active: active, expanded?: expanded?}, count) do
    if expanded? or count <= @visible + 1 do
      Enum.map(Enum.with_index(images), &thumb(&1, active))
    else
      images
      |> Enum.take(@visible)
      |> Enum.with_index()
      |> Enum.map(&thumb(&1, active))
      |> Kernel.++([overflow(count - @visible)])
    end
  end

  defp thumb({image, index}, active) do
    %{
      index: index,
      url: image.url,
      label: "#{index + 1}",
      aria: "Photo #{index + 1}",
      current?: index == active,
      event: "choose_photo"
    }
  end

  defp overflow(remaining) do
    %{
      index: @visible,
      url: nil,
      label: "+#{remaining}",
      aria: "Show #{remaining} more photos",
      current?: false,
      event: "expand_gallery"
    }
  end
end
