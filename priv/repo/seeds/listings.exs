# Listings seeds: the category catalog a seller files a listing under. Loaded
# by `priv/repo/seeds.exs`.
#
# Deliberately broad and generic — Mercato ships marketplace-agnostic, so a
# deployment replaces this list with the categories it actually sells. Re-running
# is safe: a category upserts on its slug, so an edited name renames the existing
# row instead of adding a second one.

alias Mercato.Listings

for {slug, name} <- [
      {"home-garden", "Home & Garden"},
      {"electronics", "Electronics"},
      {"fashion", "Fashion"},
      {"sports-outdoors", "Sports & Outdoors"},
      {"toys-games", "Toys & Games"},
      {"books-media", "Books & Media"},
      {"vehicles", "Vehicles"},
      {"services", "Services"},
      {"other", "Other"}
    ] do
  Listings.create_category!(%{name: name, slug: slug}, authorize?: false)
end

if Mix.env() == :dev do
  alias Mercato.Accounts.User

  # Placeholder photography, drawn rather than shipped: a listing needs a real
  # image before it can go on offer, and generating one keeps binary files out
  # of the repo while still putting a file through the storage adapter the app
  # uploads with. A flat colour is enough to tell one photo from the next in a
  # gallery, which is all a seeded listing has to do.
  chunk = fn type, data ->
    <<byte_size(data)::32>> <> type <> data <> <<:erlang.crc32(type <> data)::32>>
  end

  swatch = fn {r, g, b} ->
    size = 600
    row = <<0>> <> :binary.copy(<<r, g, b>>, size)

    <<137, 80, 78, 71, 13, 10, 26, 10>> <>
      chunk.("IHDR", <<size::32, size::32, 8, 2, 0, 0, 0>>) <>
      chunk.("IDAT", :zlib.compress(:binary.copy(row, size))) <>
      chunk.("IEND", "")
  end

  palette = [
    {0x8A, 0x6B, 0x4F},
    {0x4F, 0x6B, 0x8A},
    {0x6B, 0x8A, 0x4F},
    {0x8A, 0x4F, 0x6B},
    {0x4F, 0x8A, 0x8A},
    {0x8A, 0x84, 0x4F}
  ]

  categories = Map.new(Listings.list_categories!(authorize?: false), &{&1.slug, &1.id})
  seller = fn email -> Ash.get!(User, [email: email], authorize?: false) end

  # Every listing carries two photos, so the gallery has something to move
  # between and the cover is a choice rather than the only picture there is.
  photograph = fn listing, index, owner ->
    for offset <- 0..1 do
      colour = Enum.at(palette, rem(index + offset, length(palette)))

      Listings.add_listing_image!(
        %{listing_id: listing.id, image: swatch.(colour), filename: "photo-#{offset + 1}.png"},
        actor: owner
      )
    end

    listing
  end

  # The state each listing ends in is reached the way a seller would reach it,
  # so a paused listing here has genuinely been published and paused.
  settle = fn
    listing, :draft, _owner ->
      listing

    listing, :active, owner ->
      Listings.publish_listing!(listing, actor: owner)

    listing, :unavailable, owner ->
      listing |> Listings.publish_listing!(actor: owner) |> Listings.pause_listing!(actor: owner)

    listing, :sold, owner ->
      listing
      |> Listings.publish_listing!(actor: owner)
      |> Listings.mark_listing_sold!(actor: nil)
  end

  stock = [
    {"trader@example.com",
     [
       {"Reclaimed oak dining table", "Seats six. Some marks on the top, all solid.", 42_000, 1,
        "good", "home-garden", :active},
       {"Cast iron skillet, 12 inch", "Seasoned and ready to cook on.", 4_500, 2, "like_new",
        "home-garden", :active},
       {"Rattan armchair", "Frame is sound, cushion needs recovering.", 18_000, 1, "fair",
        "home-garden", :draft}
     ]},
    {"marta@example.com",
     [
       {"Mid-century teak sideboard", "Danish teak, three drawers and a sliding door.", 34_750, 1,
        "good", "home-garden", :active},
       {"Danish floor lamp", "Rewired last year, original shade.", 12_500, 1, "good",
        "home-garden", :active},
       {"Wool kilim rug, 2x3m", "Faded on one side from a sunny window.", 9_800, 1, "fair",
        "home-garden", :unavailable},
       {"Set of six bentwood chairs", "Matching set, all six sound.", 52_000, 6, "good",
        "home-garden", :sold},
       {"Brass reading lamp", "Barely used, still boxed.", 6_400, 1, "like_new", "home-garden",
        :active}
     ]},
    {"tom@example.com",
     [
       {"Film camera with 50mm lens", "Meter works, shutter accurate at every speed.", 28_000, 1,
        "good", "electronics", :active},
       {"Bluetooth turntable", "Belt replaced, new stylus fitted.", 21_500, 1, "like_new",
        "electronics", :active},
       {"Noise-cancelling headphones", "Case and cable included.", 14_000, 1, "good",
        "electronics", :active},
       {"Mechanical keyboard, 65%", "Never typed on. Wrong layout for me.", 11_000, 1, "new",
        "electronics", :draft}
     ]},
    {"aisha@example.com",
     [
       {"Wool overcoat, camel", "Worn one winter. No moth damage.", 16_500, 1, "like_new",
        "fashion", :active},
       {"Leather weekend bag", "Softened nicely with use.", 24_000, 1, "good", "fashion",
        :active},
       {"Silk scarf, hand-rolled", "Unworn, tags still on.", 5_500, 3, "new", "fashion", :active},
       {"First edition paperback set", "Reading copies rather than collectors'.", 7_200, 1,
        "fair", "books-media", :unavailable}
     ]},
    {"diego@example.com",
     [
       {"Steel-frame road bike, 56cm", "Recently serviced, new bar tape.", 45_000, 1, "good",
        "sports-outdoors", :active},
       {"Two-person tent", "Pitched twice. Dry and clean.", 13_500, 1, "like_new",
        "sports-outdoors", :active},
       {"Wooden train set", "Outgrown. Every piece accounted for.", 4_800, 1, "good",
        "toys-games", :sold},
       {"Bike servicing, full tune-up", "Gears, brakes and bearings. Parts extra.", 6_000, 1, nil,
        "services", :active}
     ]}
  ]

  for {email, items} <- stock do
    owner = seller.(email)

    # Skipped rather than added to, so re-running the seeds leaves a database
    # that already has these alone instead of stocking every seller twice.
    if Listings.list_my_listings!(actor: owner) == [] do
      for {{title, description, price, quantity, condition, category, state}, index} <-
            Enum.with_index(items) do
        %{
          title: title,
          description: description,
          price: price,
          quantity: quantity,
          condition: condition,
          category_id: Map.fetch!(categories, category)
        }
        |> Listings.create_listing!(actor: owner)
        |> then(&photograph.(&1, index, owner))
        |> settle.(state, owner)
      end
    end
  end

  # Bulk, so the browse grid runs past a single page and the pager under it has
  # something to page. Numbered rather than described: the stock above is what
  # a page is read against when the copy matters, and fifty more hand-written
  # listings would be fifty more things to keep plausible for no gain. Every
  # one is active — a draft or a paused listing never reaches the grid, so it
  # would add length here without adding any.
  filler = 300
  numbered = fn index -> "Listing #{index}" end

  owners = Enum.map(stock, fn {email, _items} -> seller.(email) end)
  slugs = categories |> Map.keys() |> Enum.sort()
  conditions = Listings.conditions()

  stocked? =
    Enum.any?(
      Listings.list_listings!(authorize?: false),
      &String.starts_with?(&1.title, "Listing ")
    )

  # Spread round-robin rather than heaped on one seller or one category, so
  # narrowing the grid still leaves more than a page to walk.
  unless stocked? do
    for index <- 1..filler do
      owner = Enum.at(owners, rem(index, length(owners)))
      colour = Enum.at(palette, rem(index, length(palette)))

      listing =
        Listings.create_listing!(
          %{
            title: numbered.(index),
            description: "Filler stock, so the grid has more than one page of it.",
            # Random rather than stepped, so ordering by price shuffles the grid
            # against the order it was written in instead of agreeing with it.
            price: :rand.uniform(50_000) + 500,
            quantity: 1,
            condition: Enum.at(conditions, rem(index, max(length(conditions), 1))),
            category_id: Map.fetch!(categories, Enum.at(slugs, rem(index, length(slugs))))
          },
          actor: owner
        )

      # One photo rather than the two the stock above carries: this is length,
      # not a gallery to move through, and fifty second uploads cost the seed
      # run more than they show.
      Listings.add_listing_image!(
        %{listing_id: listing.id, image: swatch.(colour), filename: "photo-1.png"},
        actor: owner
      )

      Listings.publish_listing!(listing, actor: owner)
    end
  end
end
