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
