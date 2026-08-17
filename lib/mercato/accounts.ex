defmodule Mercato.Accounts do
  @moduledoc """
  Domain for user accounts, authentication, and the RBAC (roles/permissions) schema.
  """

  use Ash.Domain,
    otp_app: :mercato

  resources do
    resource Mercato.Accounts.Token

    resource Mercato.Accounts.User do
      define :change_status, action: :change_status, args: [:status]
      define :sign_in_with_password, action: :sign_in_with_password, args: [:email, :password]
      define :sign_in_with_token, action: :sign_in_with_token, args: [:token]
      define :sign_in_with_magic_link, action: :sign_in_with_magic_link, args: [:token]
      define :update_handle, action: :update_handle, args: [:handle]
    end

    resource Mercato.Accounts.Setting

    resource Mercato.Accounts.Role do
      define :get_role_by_name, action: :get_by_name, args: [:name]
    end

    resource Mercato.Accounts.Permission
    resource Mercato.Accounts.RolePermission
    resource Mercato.Accounts.UserRole
  end
end
