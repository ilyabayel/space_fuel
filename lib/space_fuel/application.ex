defmodule SpaceFuel.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SpaceFuelWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:space_fuel, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SpaceFuel.PubSub},
      # Start a worker by calling: SpaceFuel.Worker.start_link(arg)
      # {SpaceFuel.Worker, arg},
      # Start to serve requests, typically the last entry
      SpaceFuelWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpaceFuel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpaceFuelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
