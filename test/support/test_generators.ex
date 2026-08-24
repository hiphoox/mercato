defmodule Mercato.TestGenerators do
  @moduledoc false

  use Ash.Generator

  alias Mercato.Accounts.{Permission, Role, RolePermission, UserRole}

  @doc """
  Puts `user` in a fresh role granted `permission_name`.

  Seeded rather than built through actions: `Role`/`Permission` have no
  public-facing grant action, and a test that needs an admin cares about the
  permission it ends up with, not how the grant was made.
  """
  def grant_permission(user, permission_name) do
    role = Ash.Seed.seed!(Role, %{name: "role_#{System.unique_integer([:positive])}"})

    # Created rather than seeded: `Permission.create` upserts on the unique
    # name, so two users can be granted the same permission in one test without
    # the second grant colliding.
    permission = Ash.create!(Permission, %{name: permission_name}, authorize?: false)
    Ash.Seed.seed!(RolePermission, %{role_id: role.id, permission_id: permission.id})
    Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})

    user
  end

  @doc "A user granted `admin:access`, i.e. one who can reach the admin area."
  def admin_user(opts \\ []) do
    generate(user(opts)) |> grant_permission("admin:access")
  end

  def category(opts \\ []) do
    changeset_generator(
      Mercato.Listings.Category,
      :create,
      authorize?: false,
      defaults: [
        name: sequence(:category_name, &"Category #{&1}"),
        slug: sequence(:category_slug, &"category-#{&1}")
      ],
      overrides: opts
    )
  end

  @doc """
  A listing owned by `opts[:actor]`, or by a seller generated for the purpose.

  The seller is an option rather than an attribute: a listing takes its owner
  from whoever is acting, never from supplied content.
  """
  def listing(opts \\ []) do
    {seller, opts} = Keyword.pop_lazy(opts, :actor, fn -> generate(user()) end)

    changeset_generator(
      Mercato.Listings.Listing,
      :create,
      actor: seller,
      authorize?: false,
      defaults: [
        title: sequence(:listing_title, &"Listing #{&1}"),
        price: 1000,
        # One category per test process rather than one per listing: every
        # listing needs a category, but few tests care which.
        category_id: once(:listing_category, fn -> generate(category()).id end)
      ],
      overrides: opts
    )
  end

  @doc """
  An image in `opts[:listing]`'s gallery, or in one generated for the purpose.

  The listing is an option rather than an attribute so a caller can add several
  images to the same gallery and watch them order themselves.
  """
  def listing_image(opts \\ []) do
    {listing, opts} = Keyword.pop_lazy(opts, :listing, fn -> generate(listing()) end)

    changeset_generator(
      Mercato.Listings.ListingImage,
      :create,
      authorize?: false,
      defaults: [
        listing_id: listing.id,
        image: png_bytes(),
        filename: sequence(:listing_image_filename, &"image-#{&1}.png")
      ],
      overrides: opts
    )
  end

  @doc """
  The smallest bytes that a type check will accept as a PNG.

  A real signature rather than arbitrary content, because an upload is
  identified by the bytes it starts with.
  """
  def png_bytes, do: <<0x89, "PNG\r\n", 0x1A, 0x0A, "test image">>

  def user(opts \\ []) do
    changeset_generator(
      Mercato.Accounts.User,
      :register_with_password,
      authorize?: false,
      defaults: [
        email: sequence(:user_email, &"user-#{&1}@example.com"),
        first_name: "Jane",
        password: "password1234",
        password_confirmation: "password1234"
      ],
      overrides: opts
    )
  end
end
