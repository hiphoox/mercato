defmodule Mercato.Accounts.User do
  @moduledoc """
  A marketplace account: authentication (email/password, magic link),
  profile fields, account status, and RBAC role membership via `user_roles`.
  """

  use Ash.Resource,
    otp_app: :mercato,
    domain: Mercato.Accounts,
    data_layer: AshSqlite.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshArchival.Resource]

  alias Mercato.Accounts.User.Status

  sqlite do
    table "users"
    repo Mercato.Repo
  end

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end

      confirmation :confirm_new_user do
        monitor_fields [:email]
        confirm_on_create? true
        confirm_on_update? false
        require_interaction? true
        confirmed_at_field :confirmed_at
        auto_confirm_actions [:sign_in_with_magic_link, :reset_password_with_token]
        sender Mercato.Accounts.User.Senders.SendNewUserConfirmationEmail
      end
    end

    tokens do
      enabled? true
      token_resource Mercato.Accounts.Token
      signing_secret Mercato.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      magic_link do
        identity_field :email
        registration_enabled? true
        require_interaction? true

        sender Mercato.Accounts.User.Senders.SendMagicLinkEmail
      end

      remember_me :remember_me

      password :password do
        identity_field :email
        hash_provider AshAuthentication.BcryptProvider

        resettable do
          sender Mercato.Accounts.User.Senders.SendPasswordResetEmail
          # these configurations will be the default in a future release
          password_reset_action_name :reset_password_with_token
          request_password_reset_action_name :request_password_reset_token
        end
      end
    end
  end

  archive do
    # Every read filters archived accounts out on its own, so a read added later
    # is excluded by default rather than by remembering to say so. Not a
    # `base_filter`: that applies to every read with no per-action opt-out, and
    # the admin listing has to keep showing a deleted account's row.
    exclude_read_actions [:list_accounts]
  end

  actions do
    defaults [:read]

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true

      prepare AshAuthentication.Preparations.FilterBySubject
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get_by :email
    end

    read :list_accounts do
      description "Admin listing of every account, searchable and filterable by status."

      argument :query, :string do
        description "Free-text search over name, handle, and email."
        constraints allow_empty?: true
        allow_nil? false
        default ""
      end

      argument :status, Status do
        description "Restricts the listing to a single account status."
        allow_nil? true
      end

      pagination offset?: true, default_limit: 20, countable: true

      filter expr(is_nil(^arg(:status)) or status == ^arg(:status))

      # Case-insensitive substring match; see the expression module for why
      # SQLite can't use contains/2 here.
      filter expr(
               icontains(first_name, ^arg(:query)) or
                 icontains(last_name, ^arg(:query)) or
                 icontains(handle, ^arg(:query)) or
                 icontains(type(email, :string), ^arg(:query))
             )

      # `id` breaks the tie so offset paging can't repeat or skip a row when
      # several accounts share a last_active_at (or are all nil).
      prepare build(
                sort: [last_active_at: :desc_nils_last, id: :asc],
                load: [:roles, :admin?]
              )
    end

    create :sign_in_with_magic_link do
      description "Sign in or register a user with magic link."

      # first_name/last_name are optional, for a brand-new account. Unlike
      # password registration, a magic link click carries only the token, so
      # a returning user never supplies them — upsert_fields below keeps
      # their stored name untouched either way.
      accept [:first_name, :last_name]

      argument :token, :string do
        description "The token from the magic link that was sent to the user"
        allow_nil? false
      end

      argument :remember_me, :boolean do
        description "Whether to generate a remember me token"
        allow_nil? true
      end

      upsert? true
      upsert_identity :unique_email
      upsert_fields [:email]

      # Uses the information from the token to create or sign in the user
      change AshAuthentication.Strategy.MagicLink.SignInChange

      change {AshAuthentication.Strategy.RememberMe.MaybeGenerateTokenChange,
              strategy_name: :remember_me}

      change set_attribute(:last_active_at, &DateTime.utc_now/0)

      validate Mercato.Accounts.User.Validations.AccountCanSignIn

      metadata :token, :string do
        allow_nil? false
      end
    end

    action :request_magic_link do
      argument :email, :ci_string do
        allow_nil? false
      end

      run AshAuthentication.Strategy.MagicLink.Request
    end

    update :change_password do
      # Use this action to allow users to change their password by providing
      # their current password and a new password.

      require_atomic? false
      accept []
      argument :current_password, :string, sensitive?: true, allow_nil?: false

      argument :password, :string,
        sensitive?: true,
        allow_nil?: false,
        constraints: [min_length: 8]

      argument :password_confirmation, :string, sensitive?: true, allow_nil?: false

      validate confirm(:password, :password_confirmation)

      validate {AshAuthentication.Strategy.Password.PasswordValidation,
                strategy_name: :password, password_argument: :current_password}

      change {AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password}
    end

    update :bump_last_active_at do
      description "Stamps last_active_at with the current time."
      accept []
      change set_attribute(:last_active_at, &DateTime.utc_now/0)
    end

    update :change_status do
      description "Admin action to move a user between account statuses."
      accept [:status]

      # Notifying hangs work off after_action, which an atomic update can't
      # express.
      require_atomic? false

      change Mercato.Accounts.User.Changes.NotifyStatusChange
    end

    destroy :delete_account do
      description "Terminal account deletion: archives the row and erases its personal data."

      # Anonymization hangs work off after_action (storage, tokens), which an
      # atomic destroy can't express.
      require_atomic? false

      # Hard-deleted rather than archived: a role grant is a capability, not
      # personal history, and a deleted admin must carry no permissions.
      change cascade_destroy(:user_roles)

      # Declared before anonymisation so the intent reads in order: tell them,
      # then erase them. Both hooks read the address off the pre-action row, so
      # neither depends on running first.
      change Mercato.Accounts.User.Changes.NotifyAccountDeleted

      change Mercato.Accounts.User.Changes.AnonymizeAccount
    end

    update :update_profile_info do
      description "Self-service update of a user's first and last name."
      accept [:first_name, :last_name]

      # first_name/last_name stay nilable on the attribute (a magic-link
      # signup has neither), but this profile-edit action must not let a
      # user clear their own name to blank.
      validate present([:first_name, :last_name])
    end

    update :update_handle do
      description "Self-service handle change, subject to the reserved-word and cooldown rules."
      accept [:handle]
      require_atomic? false

      validate Mercato.Accounts.User.Validations.HandleNotReserved
      validate Mercato.Accounts.User.Validations.HandleCooldown
      change set_attribute(:handle_changed_at, &DateTime.utc_now/0)
    end

    update :update_avatar do
      description "Uploads a new avatar image via the storage port and sets avatar_url."
      accept []
      require_atomic? false

      argument :avatar, :binary do
        allow_nil? false
      end

      argument :filename, :string do
        allow_nil? false
      end

      change Mercato.Accounts.User.Changes.UploadAvatar
    end

    read :sign_in_with_password do
      description "Attempt to sign in using a email and password."
      get? true

      argument :email, :ci_string do
        description "The email to use for retrieving the user."
        allow_nil? false
      end

      argument :password, :string do
        description "The password to check for the matching user."
        allow_nil? false
        sensitive? true
      end

      # Not `status: :active` — a restricted account is limited inside the app,
      # not locked out of it. Only banned and deleted are refused a session.
      filter expr(status in ^Status.can_sign_in())

      # validates the provided email and password and generates a token
      prepare AshAuthentication.Strategy.Password.SignInPreparation
      prepare Mercato.Accounts.User.Preparations.StampLastActiveAt

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    read :sign_in_with_token do
      # In the generated sign in components, we validate the
      # email and password directly in the LiveView
      # and generate a short-lived token that can be used to sign in over
      # a standard controller action, exchanging it for a standard token.
      # This action performs that exchange. If you do not use the generated
      # liveviews, you may remove this action, and set
      # `sign_in_tokens_enabled? false` in the password strategy.

      description "Attempt to sign in using a short-lived sign in token."
      get? true

      argument :token, :string do
        description "The short-lived sign in token."
        allow_nil? false
        sensitive? true
      end

      # Not `status: :active` — a restricted account is limited inside the app,
      # not locked out of it. Only banned and deleted are refused a session.
      filter expr(status in ^Status.can_sign_in())

      # validates the provided sign in token and generates a token
      prepare AshAuthentication.Strategy.Password.SignInWithTokenPreparation
      prepare Mercato.Accounts.User.Preparations.StampLastActiveAt

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    create :register_with_password do
      description "Register a new user with a email and password."

      accept [:email, :last_name]

      # first_name is required at password registration, unlike the
      # attribute itself (which stays nilable for magic-link accounts) — so
      # it needs its own argument rather than accept, which would inherit
      # the attribute's allow_nil?: true.
      argument :first_name, :string do
        allow_nil? false
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      change set_attribute(:first_name, arg(:first_name))

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      metadata :token, :string do
        description "A JWT that can be used to authenticate the user."
        allow_nil? false
      end
    end

    action :request_password_reset_token do
      description "Send password reset instructions to a user if they exist."

      argument :email, :ci_string do
        allow_nil? false
      end

      # creates a reset token and invokes the relevant senders
      run {AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email}
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil? false
        sensitive? true
      end

      argument :password, :string do
        description "The proposed password for the user, in plain text."
        allow_nil? false
        constraints min_length: 8
        sensitive? true
      end

      argument :password_confirmation, :string do
        description "The proposed password for the user (again), in plain text."
        allow_nil? false
        sensitive? true
      end

      # validates the provided reset token
      validate AshAuthentication.Strategy.Password.ResetTokenValidation

      # validates that the password matches the confirmation
      validate AshAuthentication.Strategy.Password.PasswordConfirmationValidation

      # Hashes the provided password
      change AshAuthentication.Strategy.Password.HashPasswordChange

      # Generates an authentication token for the user
      change AshAuthentication.GenerateTokenChange
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:update) do
      authorize_if expr(id == ^actor(:id))
      authorize_if {Mercato.Accounts.User.Checks.ActorHasPermission, permission: "user:update"}
    end

    # Self-service deletion from the profile page, or an admin deleting
    # someone else's account from the users dashboard. Deletion is terminal, so
    # it gets its own permission rather than riding on `user:update`.
    policy action(:delete_account) do
      authorize_if expr(id == ^actor(:id))
      authorize_if {Mercato.Accounts.User.Checks.ActorHasPermission, permission: "user:delete"}
    end

    policy action(:change_status) do
      authorize_if {Mercato.Accounts.User.Checks.ActorHasPermission, permission: "user:update"}
    end

    # Strict, not the default :filter — a caller without admin:access must be
    # refused outright rather than handed an empty page, so that
    # `Accounts.can_list_accounts?/1` is a usable admin gate for the route and
    # the sidebar.
    policy action(:list_accounts) do
      access_type :strict
      authorize_if {Mercato.Accounts.User.Checks.ActorHasPermission, permission: "admin:access"}
    end
  end

  changes do
    # Both create actions need these, so they're declared once here rather than
    # repeated per action. `on: [:create]` covers `register_with_password` and
    # `sign_in_with_magic_link` — the only creates on this resource.
    change Mercato.Accounts.User.Changes.GenerateHandle, on: [:create]
    change Mercato.Accounts.User.Changes.AssignDefaultRole, on: [:create]
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :first_name, :string do
      allow_nil? true
      public? true
      constraints min_length: 1
    end

    attribute :last_name, :string do
      public? true
      constraints min_length: 1
    end

    attribute :handle, :string do
      allow_nil? true
      public? true
      constraints min_length: 3, max_length: 30, match: ~r/^[a-z0-9_]+$/
    end

    attribute :handle_changed_at, :utc_datetime_usec

    attribute :avatar_url, :string do
      public? true
    end

    # The storage key behind avatar_url. Kept separately because a URL can't be
    # turned back into a key without knowing the adapter that built it, and
    # deleting the blob on account deletion needs the key.
    attribute :avatar_key, :string

    attribute :hashed_password, :string do
      sensitive? true
    end

    attribute :status, Mercato.Accounts.User.Status do
      allow_nil? false
      default :active
      public? true
    end

    attribute :confirmed_at, :utc_datetime_usec

    attribute :last_active_at, :utc_datetime_usec
  end

  relationships do
    has_many :user_roles, Mercato.Accounts.UserRole

    has_many :listings, Mercato.Listings.Listing do
      destination_attribute :seller_id
    end

    many_to_many :roles, Mercato.Accounts.Role do
      through Mercato.Accounts.UserRole
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :role_id
    end
  end

  calculations do
    # Whether the account can reach the admin area. A calculation rather than a
    # loaded role->permission chain, so the admin listing can ask the question
    # per row inside the query it already runs.
    calculate :admin?,
              :boolean,
              expr(exists(user_roles.role.role_permissions.permission, name == "admin:access"))
  end

  identities do
    identity :unique_email, [:email]
    identity :unique_handle, [:handle]
  end
end
