defmodule Mercato.Accounts.User.Senders.SendPasswordResetEmailTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Mercato.Accounts.User.Senders.SendPasswordResetEmail

  test "sends a Mercato-branded email with a styled reset button" do
    SendPasswordResetEmail.send(%{email: "jane@example.com"}, "sometoken", %{})

    assert_email_sent(fn email ->
      assert email.subject == "Reset your password"
      assert email.html_body =~ "Mercato"
      assert email.html_body =~ "#3B82F6"
      assert email.html_body =~ "/password-reset/sometoken"
    end)
  end
end
