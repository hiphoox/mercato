defmodule Mercato.Money do
  @moduledoc """
  Reading an amount of money the way a person writes it.

  The one place the minor-unit factor lives, in both directions: rendering a
  stored amount for a person, and reading back what one typed.
  """

  # Hundredths, so a zero-decimal currency such as JPY is mis-handled — the
  # trade for carrying no currency database.
  @minor_units 100

  # Only the currencies a default install is likely to price in. An unlisted
  # currency reads as its ISO code rather than a wrong symbol.
  @symbols %{"USD" => "$", "EUR" => "€", "GBP" => "£", "JPY" => "¥"}

  @doc """
  Renders `amount` minor units of `currency`.

  Always two decimal places, so a zero-decimal currency such as JPY is
  mis-rendered — the trade for carrying no currency database.

      iex> Mercato.Money.format(42_000, "USD")
      "$420.00"
  """
  def format(amount, currency) when is_integer(amount) do
    case Map.fetch(@symbols, currency) do
      {:ok, symbol} -> "#{symbol}#{amount(amount)}"
      # Spaced, because a bare code run against the digits reads as one word.
      :error -> "#{currency} #{amount(amount)}"
    end
  end

  @doc """
  Renders `amount` minor units with no currency in front of it.

  For a field a person types into, where the currency is already shown beside
  the box rather than inside the value. `nil` reads back as `nil`, which is an
  amount not yet set rather than a free one.

      iex> Mercato.Money.amount(42_000)
      "420.00"
  """
  def amount(nil), do: nil

  def amount(amount) when is_integer(amount) do
    major = amount |> div(@minor_units) |> Integer.to_string()
    minor = amount |> rem(@minor_units) |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{major}.#{minor}"
  end

  @doc """
  The symbol `currency` is written with, or the code itself when there is none.

      iex> Mercato.Money.symbol("USD")
      "$"
  """
  def symbol(currency) do
    case Map.fetch(@symbols, currency) do
      {:ok, symbol} -> symbol
      :error -> currency
    end
  end

  # Anchored, so trailing rubbish is refused rather than silently dropped, and
  # capped at two decimals, which is all the minor unit can hold.
  @typed ~r/^(\d+)(?:\.(\d{1,2}))?$/

  @doc """
  Reads a typed major-unit amount as the minor units a listing stores.

  Refuses anything it cannot read exactly, rather than rounding: a price is
  money, and a silently altered one is worse than a rejected one. A negative
  amount is refused too, since no listing may hold one.

      iex> Mercato.Money.to_minor("420.50")
      {:ok, 42_050}

      iex> Mercato.Money.to_minor("420.567")
      :error
  """
  def to_minor(typed) when is_binary(typed) do
    case Regex.run(@typed, String.trim(typed)) do
      [_, major] ->
        {:ok, String.to_integer(major) * @minor_units}

      [_, major, minor] ->
        # Padded, not parsed as-is: "420.5" is five tenths, not five hundredths.
        minor = minor |> String.pad_trailing(2, "0") |> String.to_integer()
        {:ok, String.to_integer(major) * @minor_units + minor}

      nil ->
        :error
    end
  end
end
