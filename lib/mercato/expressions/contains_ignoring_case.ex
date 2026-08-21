defmodule Mercato.Expressions.ContainsIgnoringCase do
  @moduledoc """
  `icontains(haystack, needle)` — a case-insensitive substring match usable in
  any Ash expression, with one implementation per data layer.

  This exists so a search filter reads as `icontains(handle, ^arg(:query))`
  everywhere, and the one backend that needs a workaround keeps it here instead
  of spreading it across every resource that searches text.

  On SQLite the match is `instr` over two downcased operands. The obvious
  `contains/2` is unusable there: `ash_sql` compiles it against a literal to
  `LIKE` with `_` and `%` backslash-escaped and no `ESCAPE` clause, which SQLite
  ignores — so any needle containing an underscore silently matches nothing.
  SQLite also has no `ILIKE`, and `instr` is case-sensitive, hence the explicit
  downcasing.

  On Postgres neither problem exists, so the match is a plain `ILIKE` through
  `contains/2` with a case-insensitive needle.

  A nil operand yields nil, which is falsy in SQL — an account with no last name
  simply doesn't match rather than raising.
  """

  use Ash.CustomExpression,
    name: :icontains,
    arguments: [[:string, :string]],
    predicate?: true

  @impl Ash.CustomExpression
  def expression(AshSqlite.DataLayer, [haystack, needle]) do
    {:ok, expr(string_position(string_downcase(^haystack), string_downcase(^needle)) > 0)}
  end

  def expression(AshPostgres.DataLayer, [haystack, needle]) do
    {:ok, expr(contains(^haystack, type(^needle, :ci_string)))}
  end

  def expression(data_layer, [haystack, needle])
      when data_layer in [Ash.DataLayer.Ets, Ash.DataLayer.Simple] do
    {:ok, expr(fragment(&__MODULE__.icontains/2, ^haystack, ^needle))}
  end

  def expression(_data_layer, _arguments), do: :unknown

  @doc "Whether `needle` appears in `haystack`, ignoring case. Nil-safe."
  def icontains(nil, _needle), do: nil
  def icontains(_haystack, nil), do: nil

  def icontains(haystack, needle) do
    String.contains?(String.downcase(to_string(haystack)), String.downcase(to_string(needle)))
  end
end
