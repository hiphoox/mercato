defmodule Mercato.Money do
  @moduledoc """
  Reading an amount of money, and a rate taken off one, the way a person writes
  them.

  The one place the hundredths factor lives, in both directions and for both
  readings: cents to the major unit, basis points to the percent. An amount and
  a rate are the same integer arithmetic wearing different words, so they are
  read and written here rather than in two modules that would drift apart.
  """

  # Hundredths, so a zero-decimal currency such as JPY is mis-handled — the
  # trade for carrying no currency database.
  @hundredths 100

  # A rate is hundredths of a percent, and a percent is hundredths of the
  # amount, so a rate divides by the factor twice over.
  @whole @hundredths * @hundredths

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
    {major, minor} = split(amount)

    "#{major}.#{minor}"
  end

  @doc """
  Renders `rate` basis points as the percentage it is.

      iex> Mercato.Money.percent(250)
      "2.5%"
  """
  def percent(nil), do: nil

  def percent(rate) when is_integer(rate), do: "#{rate(rate)}%"

  @doc """
  Renders `rate` basis points with no percent sign on the end.

  For a field a person types into, where the sign is shown beside the box
  rather than inside the value. Trailing zeros are dropped, unlike an amount's:
  a rate is written as short as it reads, and `2.50%` is a rate nobody types.

      iex> Mercato.Money.rate(250)
      "2.5"
  """
  def rate(nil), do: nil

  def rate(rate) when is_integer(rate) do
    case split(rate) do
      {whole, "00"} -> whole
      {whole, fraction} -> "#{whole}.#{String.trim_trailing(fraction, "0")}"
    end
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

  @doc """
  Reads a typed major-unit amount as the minor units a listing stores.

      iex> Mercato.Money.to_minor("420.50")
      {:ok, 42_050}

      iex> Mercato.Money.to_minor("420.567")
      :error
  """
  def to_minor(typed) when is_binary(typed), do: to_hundredths(typed)

  @doc """
  Reads a typed percentage as the basis points a rate stores.

      iex> Mercato.Money.to_basis_points("2.5")
      {:ok, 250}

      iex> Mercato.Money.to_basis_points("2.555")
      :error
  """
  def to_basis_points(typed) when is_binary(typed), do: to_hundredths(typed)

  @doc """
  Takes `rate` basis points of `amount` minor units.

  Rounds a half unit up rather than away, so a marketplace taking a rate of a
  small sale is not silently taking nothing.

      iex> Mercato.Money.apply_rate(10_000, 250)
      250
  """
  def apply_rate(amount, rate) when is_integer(amount) and is_integer(rate) do
    div(amount * rate + div(@whole, 2), @whole)
  end

  defp split(value) do
    major = value |> div(@hundredths) |> Integer.to_string()
    minor = value |> rem(@hundredths) |> Integer.to_string() |> String.pad_leading(2, "0")

    {major, minor}
  end

  # Anchored, so trailing rubbish is refused rather than silently dropped, and
  # capped at two decimals, which is all a hundredth can hold.
  @typed ~r/^(\d+)(?:\.(\d{1,2}))?$/

  # Refuses anything it cannot read exactly, rather than rounding: a price is
  # money and a rate is a share of it, and a silently altered one is worse than
  # a rejected one. A negative is refused too, since neither may hold one.
  defp to_hundredths(typed) do
    case Regex.run(@typed, String.trim(typed)) do
      [_, whole] ->
        {:ok, String.to_integer(whole) * @hundredths}

      [_, whole, fraction] ->
        # Padded, not parsed as-is: "420.5" is five tenths, not five hundredths.
        fraction = fraction |> String.pad_trailing(2, "0") |> String.to_integer()
        {:ok, String.to_integer(whole) * @hundredths + fraction}

      nil ->
        :error
    end
  end
end
