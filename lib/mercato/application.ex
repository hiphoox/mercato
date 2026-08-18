defmodule Mercato.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MercatoWeb.Telemetry,
      Mercato.Repo,
      {DNSCluster, query: Application.get_env(:mercato, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mercato.PubSub},
      # Start a worker by calling: Mercato.Worker.start_link(arg)
      # {Mercato.Worker, arg},
      # Start to serve requests, typically the last entry
      MercatoWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :mercato]}
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mercato.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MercatoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
