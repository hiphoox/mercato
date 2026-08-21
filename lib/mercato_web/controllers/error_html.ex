defmodule MercatoWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use MercatoWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/mercato_web/controllers/error_html/404.html.heex
  #   * lib/mercato_web/controllers/error_html/500.html.heex
  #
  # embed_templates "error_html/*"

  @doc """
  Renders the status message for a template name — `"404.html"` gives `"Not Found"`.
  """
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
