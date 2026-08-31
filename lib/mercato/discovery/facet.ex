defmodule Mercato.Discovery.Facet do
  @moduledoc """
  One way the browse grid can be narrowed, declared rather than written out.

  A facet states what it narrows and how, and that one statement is enough for
  both halves of the job: the read builds the filter from it, and the bar draws
  the control from it. Adding a way to narrow the grid is a line in a list
  rather than an edit to the read, the bar, the sheet, the chips and the
  address, which is what lets a marketplace ship the facets its catalog
  actually has — mileage and year for vehicles, size and brand for clothes.

  The kinds are the two a marketplace narrows by: one value chosen from a list,
  or a numeric range with either end left open. A third kind is a clause added
  here, not a change to the two above it.

  What a facet narrows may sit on the listing itself or across a relationship,
  which is why `field` takes a path as readily as a name.

  The label is data, not copy: a marketplace declaring a facet this codebase
  has never heard of is stating what its own buyers read, and translating it
  would overwrite the operator's own words. The stock facets are worded in the
  web layer instead, so they stay translatable — see the copy boundary in
  `docs/architecture/i18n-copy.md`.

  What a buyer types is rarely what the column stores. A facet may state how to
  read a typed value and how to write it back, which is what lets a price be
  typed in the units on the tag and compared in the units it is stored in,
  without the code that reads addresses knowing anything about money.
  """

  @kinds [:select, :range]
  @placements [:bar, :sheet]

  @enforce_keys [:key, :kind, :field, :label]
  defstruct [:key, :kind, :field, :label, :options, :parse, :format, placement: :bar]

  @type field :: atom() | {[atom()], atom()}

  @type t :: %__MODULE__{
          key: atom(),
          kind: :select | :range,
          field: field(),
          label: String.t(),
          options: mfa() | nil,
          parse: mfa() | nil,
          format: mfa() | nil,
          placement: :bar | :sheet
        }

  @doc """
  Builds a facet from its declaration, refusing one the grid cannot honour.

  A declaration is checked when it is read rather than when it is used, so a
  marketplace naming a kind that does not exist learns at startup instead of
  from an empty grid.
  """
  @spec new(keyword()) :: t()
  def new(declaration) do
    %__MODULE__{
      key: fetch!(declaration, :key),
      kind: validate!(fetch!(declaration, :kind), @kinds, :kind),
      field: fetch!(declaration, :field),
      label: fetch!(declaration, :label),
      options: Keyword.get(declaration, :options),
      parse: Keyword.get(declaration, :parse),
      format: Keyword.get(declaration, :format),
      placement: validate!(Keyword.get(declaration, :placement, :bar), @placements, :placement)
    }
  end

  defp fetch!(declaration, key) do
    case Keyword.fetch(declaration, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "a facet declaration needs a #{key}"
    end
  end

  defp validate!(value, allowed, key) do
    if value in allowed do
      value
    else
      raise ArgumentError,
            "#{inspect(value)} is not a facet #{key}; expected one of #{inspect(allowed)}"
    end
  end

  @doc """
  The query-string parameters a facet is stated by.

  A range takes two, because either end can be stated on its own and a buyer
  who names only a floor has still narrowed the grid.
  """
  @spec params(t()) :: [String.t()]
  def params(%__MODULE__{} = facet), do: Enum.map(param_keys(facet), &to_string/1)

  @doc """
  The same parameters, named the way an address is built rather than the way it
  is read.

  Minted from the facet's own key, since the facets are a marketplace's own
  finite declaration rather than anything a visitor can name.
  """
  @spec param_keys(t()) :: [atom()]
  def param_keys(%__MODULE__{kind: :range, key: key}), do: [:"#{key}_min", :"#{key}_max"]
  def param_keys(%__MODULE__{key: key}), do: [key]

  @doc "The kinds of narrowing a facet may declare."
  @spec kinds() :: [atom()]
  def kinds, do: @kinds
end
