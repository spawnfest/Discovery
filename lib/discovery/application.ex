defmodule Discovery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Discovery.Engine.Builder
  alias Discovery.Engine.Utils

  require Logger

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DiscoveryWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Discovery.PubSub},
      # Start the Endpoint (http/https)
      DiscoveryWeb.Endpoint,
      {Builder, []}
      # Start a worker by calling: Discovery.Worker.start_link(arg)
      # {Discovery.Worker, arg}
    ]

    create_metadata_db()
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Discovery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DiscoveryWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp create_metadata_db do
    :ets.new(Utils.metadata_db(), [:set, :named_table, :public])
    Logger.info("MetadataDB created \n\n")
  end
end
