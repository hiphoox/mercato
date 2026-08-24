# Accounts seeds: the roles and permissions the authorization model is built on,
# plus sample users in dev. Loaded by `priv/repo/seeds.exs`.

alias Mercato.Accounts.{Permission, Role, RolePermission}

trader =
  Ash.create!(Role, %{name: "trader", description: "Buy + sell"}, authorize?: false)

admin =
  Ash.create!(Role, %{name: "admin", description: "Platform staff, full access"},
    authorize?: false
  )

user_update =
  Ash.create!(
    Permission,
    %{name: "user:update", description: "Update or change status on any user's record"},
    authorize?: false
  )

user_delete =
  Ash.create!(
    Permission,
    %{name: "user:delete", description: "Delete any user's account"},
    authorize?: false
  )

admin_access =
  Ash.create!(
    Permission,
    %{name: "admin:access", description: "Reach the admin area"},
    authorize?: false
  )

listing_delete =
  Ash.create!(
    Permission,
    %{name: "listing:delete", description: "Take any listing down, keeping it as a backup"},
    authorize?: false
  )

for permission <- [user_update, user_delete, admin_access, listing_delete] do
  Ash.create!(RolePermission, %{role_id: admin.id, permission_id: permission.id},
    authorize?: false
  )
end

if Mix.env() == :dev do
  alias Mercato.Accounts
  alias Mercato.Accounts.{User, UserRole}

  register_with_role = fn email, first_name, role ->
    case Ash.get(User, [email: email], authorize?: false, not_found_error?: false) do
      {:ok, nil} ->
        user =
          Accounts.register_with_password!(email, first_name, "password1234", "password1234",
            authorize?: false
          )
          |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
          |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
          |> Ash.update!()

        # register_with_password already assigns the default `trader` role;
        # the admin seed user still needs `admin` assigned on top of it.
        if role.id != trader.id do
          Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
        end

        user

      {:ok, user} ->
        user
    end
  end

  register_with_role.("trader@example.com", "Trader", trader)
  register_with_role.("admin@example.com", "Admin", admin)
end
