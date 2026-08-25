defmodule Mercato.Money do
  @moduledoc """
  Rendering an amount of money for a person to read.

  The one place minor units are converted back, so no caller knows the factor.
  """

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
    major = amount |> div(100) |> Integer.to_string()
    minor = amount |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")

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
end
