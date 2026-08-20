defmodule Mercato.Expressions.ContainsIgnoringCaseTest do
  use ExUnit.Case, async: true

  alias Mercato.Expressions.ContainsIgnoringCase

  # The SQL implementations are covered through the actions that use them
  # (see UserListAccountsTest). This covers the Elixir clause, which Ash falls
  # back to when it evaluates a filter in memory rather than in the database.
  describe "icontains/2" do
    test "matches regardless of case on either side" do
      assert ContainsIgnoringCase.icontains("Marta Ribeiro", "RIBE")
      assert ContainsIgnoringCase.icontains("MARTA RIBEIRO", "ribe")
    end

    test "matches a needle containing an underscore" do
      assert ContainsIgnoringCase.icontains("marta_ribeiro", "a_r")
    end

    test "does not match an absent needle" do
      refute ContainsIgnoringCase.icontains("marta", "nobody")
    end

    test "an empty needle matches anything" do
      assert ContainsIgnoringCase.icontains("marta", "")
    end

    # nil rather than false, mirroring SQL's three-valued logic: a nil operand
    # makes the whole comparison nil, which is falsy in a WHERE clause.
    test "a nil operand yields nil" do
      assert ContainsIgnoringCase.icontains(nil, "marta") == nil
      assert ContainsIgnoringCase.icontains("marta", nil) == nil
    end
  end
end
