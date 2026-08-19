defmodule Mercato.Accounts.User.Senders.SendMagicLinkEmailTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Mercato.Accounts.User.Senders.SendMagicLinkEmail

  test "sends a Mercato-branded email with a styled sign-in button" do
    SendMagicLinkEmail.send("jane@example.com", "sometoken", %{})

    assert_email_sent(fn email ->
      assert email.subject == "Your login link"
      assert email.html_body =~ "Mercato"
      assert email.html_body =~ "#3B82F6"
      assert email.html_body =~ "/magic_link/sometoken"
    end)
  end
end
