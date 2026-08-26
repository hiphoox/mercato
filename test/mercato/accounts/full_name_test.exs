defmodule Mercato.Accounts.FullNameTest do
  use ExUnit.Case, async: true

  alias Mercato.Accounts

  describe "full_name/1" do
    test "joins the two parts of a name" do
      assert Accounts.full_name(%{first_name: "Marta", last_name: "Ribeiro"}) == "Marta Ribeiro"
    end

    test "gives back the part there is when only one is set" do
      assert Accounts.full_name(%{first_name: "Marta", last_name: nil}) == "Marta"
      assert Accounts.full_name(%{first_name: nil, last_name: "Ribeiro"}) == "Ribeiro"
    end

    # An account may legitimately have no name yet — an OAuth sign-up or a magic
    # link creates one — so this reports the absence rather than inventing a
    # stand-in. What to show instead is the caller's to decide, and they differ:
    # a public page must not fall back to an email address.
    test "reports no name rather than choosing a stand-in" do
      assert Accounts.full_name(%{first_name: nil, last_name: nil}) == nil
    end

    test "treats a blank part as no part at all" do
      assert Accounts.full_name(%{first_name: "", last_name: ""}) == nil
      assert Accounts.full_name(%{first_name: "Marta", last_name: ""}) == "Marta"
    end

    test "reads an account that carries no name fields at all" do
      assert Accounts.full_name(%{}) == nil
    end

    test "has nothing to say about nobody" do
      assert Accounts.full_name(nil) == nil
    end
  end
end
