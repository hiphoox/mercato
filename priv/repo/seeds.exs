# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mercato.Repo.insert!(%Mercato.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

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

Ash.create!(RolePermission, %{role_id: admin.id, permission_id: user_update.id},
  authorize?: false
)

if Mix.env() == :dev do
  alias Mercato.Accounts.{User, UserRole}

  register_with_role = fn email, first_name, role ->
    case Ash.get(User, [email: email], authorize?: false, not_found_error?: false) do
      {:ok, nil} ->
        user =
          User
          |> Ash.create!(
            %{
              email: email,
              first_name: first_name,
              password: "password1234",
              password_confirmation: "password1234"
            },
            action: :register_with_password,
            authorize?: false
          )
          |> Ash.Changeset.for_update(:bump_last_active_at, %{}, authorize?: false)
          |> Ash.Changeset.force_change_attribute(:confirmed_at, DateTime.utc_now())
          |> Ash.update!()

        Ash.Seed.seed!(UserRole, %{user_id: user.id, role_id: role.id})
        user

      {:ok, user} ->
        user
    end
  end

  register_with_role.("trader@example.com", "Trader", trader)
  register_with_role.("admin@example.com", "Admin", admin)
end
