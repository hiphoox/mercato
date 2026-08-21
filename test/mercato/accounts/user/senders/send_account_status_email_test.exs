defmodule Mercato.Accounts.User.Senders.SendAccountStatusEmailTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Mercato.Accounts.User.Senders.SendAccountStatusEmail

  test "tells a banned account it can no longer sign in" do
    SendAccountStatusEmail.send("jane@example.com", :banned)

    assert_email_sent(fn email ->
      assert email.to == [{"", "jane@example.com"}]
      assert email.subject == "Your Mercato account has been suspended"
      assert email.html_body =~ "Mercato"
      assert email.html_body =~ "#3B82F6"
    end)
  end

  test "tells a restricted account what it may still do" do
    SendAccountStatusEmail.send("jane@example.com", :restricted)

    assert_email_sent(fn email ->
      assert email.subject == "Your Mercato account has been restricted"
      assert email.html_body =~ "sign in"
    end)
  end

  test "tells a reinstated account the limits are lifted" do
    SendAccountStatusEmail.send("jane@example.com", :active)

    assert_email_sent(fn email ->
      assert email.subject == "Your Mercato account has been restored"
    end)
  end

  test "tells a deleted account what was erased" do
    SendAccountStatusEmail.send("jane@example.com", :deleted)

    assert_email_sent(fn email ->
      assert email.subject == "Your Mercato account has been deleted"
      assert email.html_body =~ "erased"
    end)
  end

  # The layout takes a required CTA, so every one of these carries a button.
  test "every status carries a button back to Mercato" do
    for status <- [:banned, :restricted, :active, :deleted] do
      SendAccountStatusEmail.send("jane@example.com", status)
      assert_email_sent(fn email -> assert email.html_body =~ "Go to Mercato" end)
    end
  end
end
