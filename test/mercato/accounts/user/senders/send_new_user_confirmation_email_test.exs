defmodule Mercato.Accounts.User.Senders.SendNewUserConfirmationEmailTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Mercato.Accounts.User.Senders.SendNewUserConfirmationEmail

  test "sends a Mercato-branded email with a styled confirm button" do
    SendNewUserConfirmationEmail.send(%{email: "jane@example.com"}, "sometoken", %{})

    assert_email_sent(fn email ->
      assert email.subject == "Confirm your email address"
      assert email.html_body =~ "Mercato"
      assert email.html_body =~ "#3B82F6"
      assert email.html_body =~ "/confirm_new_user/sometoken"
    end)
  end

  test "sends identity-link copy naming the provider when linking an OAuth login" do
    SendNewUserConfirmationEmail.send(%{email: "jane@example.com"}, "sometoken", %{
      confirmation_type: :identity_link,
      provider: "Google"
    })

    assert_email_sent(fn email ->
      assert email.subject == "Confirm linking your Google login"
      assert email.html_body =~ "Google"
      assert email.html_body =~ "Mercato"
    end)
  end
end
