defmodule MercatoWeb.SearchScope do
  @moduledoc """
  Assigns the catalog the header's search scope selector offers.
  """

  import Phoenix.Component

  alias Mercato.Listings

  def on_mount(:categories, _params, _session, socket) do
    {:cont,
     assign_new(socket, :search_categories, fn ->
       Listings.list_categories!(query: [sort: :name])
     end)}
  end
end
