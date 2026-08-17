defmodule Mercato.Accounts do
  use Ash.Domain,
    otp_app: :mercato

  resources do
    resource Mercato.Accounts.Token
    resource Mercato.Accounts.User
    resource Mercato.Accounts.Setting
  end
end
