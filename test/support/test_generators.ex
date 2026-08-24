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

  def listing(opts \\ []) do
    changeset_generator(
      Mercato.Listings.Listing,
      :create,
      authorize?: false,
      defaults: [
        title: sequence(:listing_title, &"Listing #{&1}"),
        price: 1000
      ],
      overrides: opts
    )
  end

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
