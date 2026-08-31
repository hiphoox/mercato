defmodule Mercato.Accounts.ScopeTest do
  use Mercato.DataCase, async: true

  import Mercato.TestGenerators

  alias Mercato.Accounts.Scope

  describe "for_user" do
    test "carries the user it was built for" do
      user = generate(user())

      assert %Scope{user: ^user} = Scope.for_user(user)
    end

    test "answers no to admin access for an ordinary account" do
      refute Scope.for_user(generate(user())).admin?
    end

    test "answers yes for an account holding the admin permission" do
      assert Scope.for_user(admin_user()).admin?
    end

    test "stands for a signed-out visitor rather than being absent" do
      assert %Scope{user: nil, admin?: false} = Scope.for_user(nil)
    end
  end
end
