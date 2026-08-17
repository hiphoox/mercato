defmodule Mercato.Accounts do
  @moduledoc """
  Domain for user accounts, authentication, and the RBAC (roles/permissions) schema.
  """

  use Ash.Domain,
    otp_app: :mercato

  resources do
    resource Mercato.Accounts.Token
    resource Mercato.Accounts.User
    resource Mercato.Accounts.Setting
    resource Mercato.Accounts.Role
    resource Mercato.Accounts.Permission
    resource Mercato.Accounts.RolePermission
    resource Mercato.Accounts.UserRole
  end
end
