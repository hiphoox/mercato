defmodule MercatoWeb.AdminAccess do
  @moduledoc """
  Answers "may this user reach the admin area?" for the web layer, and assigns
  the answer as `:admin?`.

  Used as a plug in the browser pipeline so controller-rendered pages carry the
  assign, and called by `MercatoWeb.LiveUserAuth` for LiveViews. Both go through
  `admin?/1` rather than each asking in their own way, so a page can't disagree
  with the sidebar about whether the Admin section belongs there.

  The answer comes from the policy on the admin listing itself, so the sidebar
  and the data behind it are governed by one declaration.
  """

  @behaviour Plug

  import Plug.Conn, only: [assign: 3]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts), do: assign(conn, :admin?, admin?(conn.assigns[:current_user]))

  @doc "Whether `user` may reach the admin area."
  def admin?(nil), do: false
  def admin?(user), do: Mercato.Accounts.can_list_accounts?(user)
end
