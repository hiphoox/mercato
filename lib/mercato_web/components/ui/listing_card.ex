defmodule MercatoWeb.UI.ListingCard do
  @moduledoc """
  One listing, as it appears in any grid of listings.

  Photo, badges and price, title, meta, actions. Managing a listing fills the
  slots with a state badge and pause/edit controls; browsing one fills them
  with a sale badge and who is selling it.

      <.listing_card id="listing-1" title="Eames-style lounge chair" price="$420.00">
        <:badges><.badge kind="verified">Live</.badge></:badges>
        <:meta>412 views · listed 6 days ago</:meta>
        <:actions><.button size="sm" variant="neutral">Edit</.button></:actions>
      </.listing_card>
  """
  use MercatoWeb, :html

  @doc """
  Renders a listing card.

  A row with a thumbnail below `md`, a tile with the photo on top from `md` up.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :price, :string, required: true, doc: "already formatted for display"
  attr :navigate, :string, default: nil, doc: "makes the title a link to the listing"
  attr :image_src, :string, default: nil, doc: "the cover image; a placeholder shows without one"
  attr :image_alt, :string, default: ""
  attr :placeholder_icon, :string, default: "hero-photo"
  attr :dimmed, :boolean, default: false, doc: "for a listing no longer on offer"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :badges, doc: "state, sale, or featured badges, shown beside the price"
  slot :meta, doc: "one caption line under the title"
  slot :actions, doc: "the card's footer controls"

  def listing_card(assigns) do
    ~H"""
    <%!-- One markup tree for both shapes: the switch is CSS, so a resize costs
          no re-render. --%>
    <article
      id={@id}
      class={[
        "grid grid-cols-[4rem_1fr] gap-3 p-3.5",
        "md:grid-cols-1 md:grid-rows-[auto_1fr_auto] md:gap-0 md:p-0 md:h-full md:overflow-hidden",
        "rounded-lg border border-ink-100 dark:border-ink-700",
        "bg-bg dark:bg-ink-900 shadow-sm",
        @dimmed && "opacity-80",
        @class
      ]}
      {@rest}
    >
      <%!-- The photo is the biggest thing on the card and the part a browser aims
            at, so it opens the listing wherever the title does. --%>
      <div
        data-role="photo"
        class={[
          "flex items-center justify-center overflow-hidden",
          "size-16 rounded-md md:size-auto md:w-full md:aspect-[4/3] md:rounded-none",
          "bg-ink-100 dark:bg-ink-700"
        ]}
      >
        <.link
          :if={@navigate}
          navigate={@navigate}
          tabindex="-1"
          aria-hidden="true"
          class="size-full flex items-center justify-center"
        >
          <.photo src={@image_src} alt={@image_alt} placeholder_icon={@placeholder_icon} />
        </.link>
        <.photo
          :if={!@navigate}
          src={@image_src}
          alt={@image_alt}
          placeholder_icon={@placeholder_icon}
        />
      </div>

      <div class="flex flex-col gap-1.5 min-w-0 md:px-3.5 md:pt-3.5">
        <div class="flex items-center gap-2 flex-wrap">
          <span :if={@badges != []} data-role="badges" class="flex items-center gap-2 flex-wrap">
            {render_slot(@badges)}
          </span>
          <span
            data-role="price"
            class="text-body-md md:text-title-lg font-bold text-ink-900 dark:text-white"
          >
            {@price}
          </span>
        </div>

        <h3
          data-role="title"
          class="text-body-md font-semibold text-ink-900 dark:text-white text-pretty"
        >
          <.link
            :if={@navigate}
            navigate={@navigate}
            class="no-underline hover:underline text-inherit"
          >
            {@title}
          </.link>
          <span :if={!@navigate}>{@title}</span>
        </h3>

        <div :if={@meta != []} data-role="meta" class="text-caption-lg text-ink-500 text-pretty">
          {render_slot(@meta)}
        </div>
      </div>

      <%!-- `col-span-full` rather than a fixed span: it is the whole row below md,
            where the grid has two columns, and the whole row from md, where it has one. --%>
      <div
        :if={@actions != []}
        data-role="actions"
        class="col-span-full flex items-center gap-2 flex-wrap md:p-3.5"
      >
        {render_slot(@actions)}
      </div>
    </article>
    """
  end

  # The cover or the stand-in for one. Split out so linking the photo does not
  # mean writing the image and its placeholder twice.
  attr :src, :string, default: nil
  attr :alt, :string, default: ""
  attr :placeholder_icon, :string, required: true

  defp photo(assigns) do
    ~H"""
    <img :if={@src} src={@src} alt={@alt} class="size-full object-cover" />
    <.icon
      :if={!@src}
      name={@placeholder_icon}
      data-role="placeholder"
      aria-hidden="true"
      class="size-5.5 text-ink-300"
    />
    """
  end
end
