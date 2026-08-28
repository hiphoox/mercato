defmodule Mercato.Accounts do
  @moduledoc """
  Domain for user accounts, authentication, and the RBAC (roles/permissions) schema.
  """

  use Ash.Domain,
    otp_app: :mercato,
    extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/sellers", Mercato.Accounts.User do
        index :suggest_sellers, route: "/suggest"
      end
    end
  end

  resources do
    resource Mercato.Accounts.Token

    resource Mercato.Accounts.User do
      define :change_status, action: :change_status, args: [:status]
      define :delete_account, action: :delete_account
      define :get_seller, action: :get_seller, args: [:handle]
      define :list_accounts, action: :list_accounts
      define :suggest_sellers, action: :suggest_sellers
      define :sign_in_with_password, action: :sign_in_with_password, args: [:email, :password]
      define :sign_in_with_token, action: :sign_in_with_token, args: [:token]
      define :sign_in_with_magic_link, action: :sign_in_with_magic_link, args: [:token]
      define :update_handle, action: :update_handle, args: [:handle]

      define :update_profile_info,
        action: :update_profile_info,
        args: [:first_name, :last_name]

      define :update_avatar, action: :update_avatar, args: [:avatar, :filename]

      define :change_password,
        action: :change_password,
        args: [:current_password, :password, :password_confirmation]

      define :register_with_password,
        action: :register_with_password,
        args: [:email, :first_name, :password, :password_confirmation]
    end

    resource Mercato.Accounts.Setting do
      define :current_settings, action: :current
    end

    resource Mercato.Accounts.Role do
      define :get_role_by_name, action: :get_by_name, args: [:name]
    end

    resource Mercato.Accounts.Permission
    resource Mercato.Accounts.RolePermission
    resource Mercato.Accounts.UserRole
  end

  @doc """
  The name an account carries, written out in full.

  Returns `nil` when there is no name to write. An account may legitimately
  have none — one made by an OAuth sign-up or a magic link starts without — and
  what to show in its place is the caller's decision rather than this one's.
  Those decisions differ and must keep differing: a page showing someone their
  own account may fall back to their email address, and a public page may not.

      iex> Mercato.Accounts.full_name(%{first_name: "Marta", last_name: "Ribeiro"})
      "Marta Ribeiro"
  """
  def full_name(nil), do: nil

  # Map.get/2 rather than account[:field]: `Mercato.Accounts.User` is a struct
  # and does not implement Access.
  def full_name(account) do
    [Map.get(account, :first_name), Map.get(account, :last_name)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> case do
      [] -> nil
      parts -> Enum.join(parts, " ")
    end
  end
end
