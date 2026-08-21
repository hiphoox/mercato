defmodule Mercato.Accounts.UserStatusEmailFailureTest do
  # Swaps the mailer adapter process-wide, so it cannot share the suite's
  # async run.
  use Mercato.DataCase, async: false

  import Mercato.TestGenerators

  alias Mercato.Accounts

  defmodule FailingAdapter do
    @moduledoc false
    @behaviour Swoosh.Adapter

    @impl true
    def deliver(_email, _config), do: {:error, :smtp_unavailable}

    @impl true
    def validate_config(_config), do: :ok
  end

  # Swapped inside the test rather than in setup: registering the user sends a
  # confirmation email through a sender that still raises on failure, so the
  # account has to exist before the mail server "goes down".
  defp break_the_mailer do
    original = Application.get_env(:mercato, Mercato.Mailer)
    Application.put_env(:mercato, Mercato.Mailer, adapter: FailingAdapter)
    on_exit(fn -> Application.put_env(:mercato, Mercato.Mailer, original) end)
  end

  # The row is already written by the time the notice goes out, and SQLite has
  # no transaction to roll back — a dead mail server must not report a failure
  # for something that did happen.
  test "a ban still succeeds when the email cannot be delivered" do
    user = generate(user())
    break_the_mailer()

    banned = Accounts.change_status!(user, :banned, %{}, authorize?: false)

    assert banned.status == :banned
  end

  test "deletion still succeeds when the email cannot be delivered" do
    user = generate(user())
    break_the_mailer()

    assert :ok == Accounts.delete_account(user, authorize?: false)
  end
end
