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
    major = amount |> div(100) |> Integer.to_string()
    minor = amount |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")

    case Map.fetch(@symbols, currency) do
      {:ok, symbol} -> "#{symbol}#{major}.#{minor}"
      :error -> "#{currency} #{major}.#{minor}"
    end
  end
end
