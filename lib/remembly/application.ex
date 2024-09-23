defmodule Remembly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Remembly.InstallGlobalCommands.register_commands()

    children = [
      RememblyWeb.Telemetry,
      Remembly.Repo,
      {DNSCluster, query: Application.get_env(:remembly, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Remembly.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Remembly.Finch},
      # Start a worker by calling: Remembly.Worker.start_link(arg)
      # {Remembly.Worker, arg},
      # Start to serve requests, typically the last entry
      RememblyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Remembly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RememblyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
