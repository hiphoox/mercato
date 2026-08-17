defmodule Mercato.TestGenerators do
  @moduledoc false

  use Ash.Generator

  def user(opts \\ []) do
    changeset_generator(
      Mercato.Accounts.User,
      :register_with_password,
      authorize?: false,
      defaults: [
        email: sequence(:user_email, &"user-#{&1}@example.com"),
        first_name: "Jane",
        password: "password1234",
        password_confirmation: "password1234"
      ],
      overrides: opts
    )
  end
end
