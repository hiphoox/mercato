defmodule MercatoWeb.UI.Avatar do
  @moduledoc """
  Circular user avatar.

  Renders the uploaded image when there is one, and falls back to the user's
  initials otherwise — so a user without a photo still gets a stable, readable
  identity marker rather than an empty circle.

  The component is deliberately unaware of `Mercato.Accounts.User`: callers pass
  a display name and an optional image URL, which keeps it usable for any person
  the UI needs to depict (a seller on a listing, a participant in a thread).

      <.avatar name="Jane Doe" src={@user.avatar_url} size={38} />
  """
  use MercatoWeb, :html

  @doc """
  Renders an avatar.

  Initials use the first letter of the first and last word of `name`, so
  "Jane Amelia Doe" renders as "JD".
  """
  attr :name, :string, default: nil, doc: "display name — drives the initials and the label"
  attr :src, :string, default: nil, doc: "image URL; when absent, initials are rendered"
  attr :size, :integer, default: 40, doc: "rendered width/height in pixels"
  attr :class, :any, default: nil, doc: "extra classes, merged with the base styling"
  attr :rest, :global

  def avatar(assigns) do
    assigns =
      assigns
      |> assign(:box_style, "width:#{assigns.size}px;height:#{assigns.size}px")
      |> assign(:label, label(assigns.name))

    ~H"""
    <img
      :if={@src}
      src={@src}
      alt={@label}
      style={@box_style}
      class={["flex-none rounded-full object-cover", @class]}
      {@rest}
    />
    <span
      :if={!@src}
      role="img"
      aria-label={@label}
      style={"#{@box_style};font-size:#{initials_font_size(@size)}px"}
      class={[
        "flex-none inline-flex items-center justify-center rounded-full",
        "bg-ink-100 text-ink-700 font-semibold select-none",
        @class
      ]}
      {@rest}
    >
      {initials(@name)}
    </span>
    """
  end

  @doc """
  Returns the initials for a display name.

  Falls back to `"?"` rather than an empty string so the circle never renders
  blank, which would read as a broken image.

      iex> MercatoWeb.UI.Avatar.initials("Jane Doe")
      "JD"
  """
  def initials(name) do
    case words(name) do
      [] -> "?"
      [single] -> first_letter(single)
      words -> first_letter(List.first(words)) <> first_letter(List.last(words))
    end
  end

  defp words(nil), do: []

  defp words(name) when is_binary(name) do
    name |> String.split(~r/\s+/, trim: true) |> Enum.reject(&(&1 == ""))
  end

  defp first_letter(word), do: word |> String.first() |> String.upcase()

  defp label(name) do
    case words(name) do
      [] -> "User"
      words -> Enum.join(words, " ")
    end
  end

  # Keeps the initials optically centred at any size — a fixed font size would
  # overflow a 24px avatar and look lost in a 96px one.
  defp initials_font_size(size), do: round(size * 0.4)
end
