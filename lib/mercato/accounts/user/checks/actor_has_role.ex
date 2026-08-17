defmodule Mercato.Accounts.User.Checks.ActorHasRole do
  @moduledoc """
  Policy check: does the actor hold the given role (via `user_roles`)?
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(opts), do: "actor has the #{inspect(opts[:role])} role"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, _context, opts) do
    actor
    |> Ash.load!([user_roles: :role], authorize?: false)
    |> Map.fetch!(:user_roles)
    |> Enum.any?(&(&1.role.name == to_string(opts[:role])))
  end
end
