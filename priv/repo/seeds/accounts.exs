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

  register_with_role = fn email, first_name, last_name, role ->
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

        # Registration takes only a first name, so the surname is a second step.
        # Handles are minted at registration and left alone by it, which is why
        # these accounts are addressed by first name alone.
        Accounts.update_profile_info!(user, first_name, last_name, actor: user)

      {:ok, user} ->
        user
    end
  end

  register_with_role.("trader@example.com", "Trader", "Example", trader)
  operator = register_with_role.("admin@example.com", "Admin", "Example", admin)

  # A marketplace with one seller in it cannot be browsed, so dev gets several,
  # each of whom stocks their own listings in `listings.exs`.
  register_with_role.("marta@example.com", "Marta", "Ribeiro", trader)
  register_with_role.("tom@example.com", "Tom", "Whitfield", trader)
  register_with_role.("aisha@example.com", "Aisha", "Khan", trader)
  register_with_role.("diego@example.com", "Diego", "Ferreira", trader)

  # Bulk, so the admin listing runs past a single page and the pager under it
  # has something to page. Numbered rather than named: the accounts above are
  # who the seeded listings belong to and who a dev signs in as, while these
  # only have to be rows.
  filler = 50

  # Not all active, so the status filter and the counts beside it have
  # something to separate. Deletion is left out: it is terminal and erases the
  # account's details, which makes a poor row to look at.
  standing = fn
    index when rem(index, 10) == 0 -> :banned
    index when rem(index, 7) == 0 -> :restricted
    _index -> :active
  end

  for index <- 1..filler do
    account = register_with_role.("person#{index}@example.com", "Person", "#{index}", trader)
    status = standing.(index)

    # Only where it differs, so re-running the seeds leaves these alone rather
    # than writing every account's standing back over itself.
    if account.status != status do
      Accounts.change_status!(account, status, actor: operator)
    end
  end
end
