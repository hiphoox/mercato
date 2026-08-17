defmodule Mercato.Accounts.User.Validations.HandleCooldown do
  @moduledoc """
  Rejects a handle change made before the configurable cooldown
  (`Mercato.Accounts.Setting.handle_change_cooldown_days/0`) has elapsed
  since the previous one. A user who has never manually changed their
  handle (`handle_changed_at` is nil) is always allowed to.
  """

  use Ash.Resource.Validation

  alias Mercato.Accounts.Setting

  @impl true
  def validate(changeset, _opts, _context) do
    case Ash.Changeset.get_data(changeset, :handle_changed_at) do
      nil ->
        :ok

      last_changed_at ->
        cooldown_ends_at =
          DateTime.add(last_changed_at, Setting.handle_change_cooldown_days(), :day)

        if DateTime.compare(DateTime.utc_now(), cooldown_ends_at) == :lt do
          {:error, field: :handle, message: "must wait before changing handle again"}
        else
          :ok
        end
    end
  end
end
