defmodule MercatoWeb.Router do
  use MercatoWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MercatoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug MercatoWeb.AdminAccess
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", MercatoWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes,
      on_mount: [{MercatoWeb.SearchScope, :categories}] do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {MercatoWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {MercatoWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {MercatoWeb.LiveUserAuth, :live_no_user}

      # The marketplace's front door, and the only page not about one resource
      # in particular — it is addressed as the site root rather than under a
      # prefix, so it sits above the grouping below rather than inside it.
      live "/", Listings.BrowseLive

      # Grouped by the resource the page is about, so a new page for one of them
      # can only land inside its own prefix.
      scope "/users" do
        # The signed-in user's own pages. "me" never shadows a handle: these are
        # three segments deep and the public profile below is two.
        live "/me/profile", ProfileLive
        live "/me/listings", Listings.MyListingsLive

        # Public, like the listing page below: a buyer weighing a stranger
        # reaches it without an account. Addressed by the account's handle,
        # which is the only public name it has — the account, not the selling
        # role, since everyone here both buys and sells.
        live "/:handle", Sellers.SellerProfileLive
      end

      scope "/listings" do
        live "/new", Listings.ListingFormLive, :new
        live "/:id/edit", Listings.ListingFormLive, :edit

        # Last, so ":slug" never swallows "new".
        live "/:slug", Listings.ListingDetailLive
      end

      scope "/admin" do
        live "/users", Admin.UsersLive
      end
    end
  end

  scope "/", MercatoWeb do
    pipe_through :browser

    auth_routes AuthController, Mercato.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{MercatoWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    MercatoWeb.AuthOverrides,
                    Elixir.AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  MercatoWeb.AuthOverrides,
                  Elixir.AshAuthentication.Phoenix.Overrides.Default
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Mercato.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [MercatoWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.Default]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Mercato.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [MercatoWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.Default]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", MercatoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mercato, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MercatoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
