defmodule MercatoWeb.PageController do
  use MercatoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
