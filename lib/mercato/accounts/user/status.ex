defmodule Mercato.Accounts.User.Status do
  @moduledoc false
  use Ash.Type.Enum, values: [:active, :banned, :deleted]
end
