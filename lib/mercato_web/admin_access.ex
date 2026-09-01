defmodule MercatoWeb.AdminAccess do
  @moduledoc """
  Assigns `:current_scope` for controller-rendered pages.

  The LiveView half of this is `MercatoWeb.LiveUserAuth`. Both build the scope
  through `Mercato.Accounts.Scope.for_user/2`, so a page cannot disagree with
  the chrome around it about who is looking.
  """

  @behaviour Plug

  import Plug.Conn, only: [assign: 3]

  alias Mercato.Accounts.Scope
  alias MercatoWeb.GuestToken

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    scope = Scope.for_user(conn.assigns[:current_user], GuestToken.token(conn))

    assign(conn, :current_scope, scope)
  end
end
