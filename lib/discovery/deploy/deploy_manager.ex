defmodule Discovery.Deploy.DeployManager do
  @moduledoc """
  Manages the deployment communications from controller, orchestrates the k8 deployments.
  """

  use GenServer
  alias Discovery.Deploy.DeployUtils
  alias Discovery.Utils
  ## Client functions
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Creates/updates a deployment
  """
  @spec create(DeplouUtis.t()) :: any()
  def create(deploy_details) do
    GenServer.call(__MODULE__, {:create, deploy_details}, :infinity)
  end

  ## Server callbacks
  @impl true
  def init(_opts) do
    # creates the namespace directory, if not there
    DeployUtils.create_namespace_directory()
    Utils.puts_success("DeployManager initialized successfully!!")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:create, deploy_details}, _from, state) do
    status_data = DeployUtils.create(deploy_details)
    {:reply, status_data, state}
  end
end
