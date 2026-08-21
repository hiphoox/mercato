defmodule Mercato.Accounts.UserStatusEmailTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators
  import Swoosh.TestAssertions

  alias Mercato.Accounts

  # Registering a user sends its own confirmation email. Clearing the mailbox
  # after setup keeps these assertions about the status notice alone.
  defp drain_emails do
    receive do
      {:email, _} -> drain_emails()
    after
      0 -> :ok
    end
  end

  describe "change_status" do
    test "emails the account when it is banned" do
      user = generate(user())
      drain_emails()

      Accounts.change_status!(user, :banned, %{}, authorize?: false)

      assert_email_sent(fn email ->
        assert email.to == [{"", to_string(user.email)}]
        assert email.subject == "Your Mercato account has been suspended"
      end)
    end

    test "emails the account when it is restricted" do
      user = generate(user())
      drain_emails()

      Accounts.change_status!(user, :restricted, %{}, authorize?: false)

      assert_email_sent(fn email ->
        assert email.subject == "Your Mercato account has been restricted"
      end)
    end

    test "emails the account when it is restored to active" do
      user = generate(user())
      restricted = Accounts.change_status!(user, :restricted, %{}, authorize?: false)
      drain_emails()

      Accounts.change_status!(restricted, :active, %{}, authorize?: false)

      assert_email_sent(fn email ->
        assert email.subject == "Your Mercato account has been restored"
      end)
    end

    test "sends nothing when the status does not actually change" do
      user = generate(user())
      drain_emails()
      assert user.status == :active

      Accounts.change_status!(user, :active, %{}, authorize?: false)

      refute_email_sent()
    end
  end

  describe "delete_account" do
    # The address is erased by anonymisation, so the notice has to be built from
    # the row as it stood before the write.
    test "emails the original address, not the placeholder it is replaced with" do
      user = generate(user())
      email = to_string(user.email)
      drain_emails()

      :ok = Accounts.delete_account(user, authorize?: false)

      assert_email_sent(fn sent ->
        assert sent.to == [{"", email}]
        assert sent.subject == "Your Mercato account has been deleted"
      end)
    end

    test "sends on self-service deletion too, since both flows share the action" do
      user = generate(user())
      drain_emails()

      :ok = Accounts.delete_account(user, actor: user)

      assert_email_sent(fn sent ->
        assert sent.subject == "Your Mercato account has been deleted"
      end)
    end
  end
end
