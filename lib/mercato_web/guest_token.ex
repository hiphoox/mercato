defmodule MercatoWeb.GuestToken do
  @moduledoc """
  Gives every browser something to be told apart by before it has an account.

  A visitor may gather a cart without signing up, so a cart that is nobody's
  yet still has to be somebody's. The token is minted into the session on the
  first request and read back on every one after it.

  Minted for every visitor rather than at the moment something is first
  gathered, because gathering happens over a LiveView's socket and a socket
  cannot write the session cookie the token has to live in.
  """

  @behaviour Plug

  import Plug.Conn, only: [get_session: 2, put_session: 3]

  alias Mercato.Carts

  @session_key "guest_token"

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case get_session(conn, @session_key) do
      nil -> put_session(conn, @session_key, Carts.new_guest_token())
      _held -> conn
    end
  end

  @doc """
  The token to hand a LiveView at mount.

  AshAuthentication builds a live session from scratch rather than passing the
  whole session through, so what a LiveView is to see has to be named here.
  """
  def live_session(conn), do: %{@session_key => get_session(conn, @session_key)}

  @doc "The token this request or this mount is carrying, if there is one."
  def token(%Plug.Conn{} = conn), do: get_session(conn, @session_key)
  def token(session) when is_map(session), do: session[@session_key]
end
