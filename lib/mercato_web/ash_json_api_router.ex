defmodule MercatoWeb.AshJsonApiRouter do
  @moduledoc """
  The JSON:API surface, mounted under `/api/json`.

  Only the routes a domain declares are served, and only the fields a resource
  lists in `show_fields` are rendered — the default is every public field,
  which on an account would include the email address.
  """

  use AshJsonApi.Router,
    domains: [Mercato.Listings, Mercato.Accounts],
    open_api: "/open_api",
    open_api_title: "Mercato API",
    open_api_version: to_string(Application.spec(:mercato, :vsn))
end
