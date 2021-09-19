defmodule Discovery.Controller.DeploymentController do
  @moduledoc """
  Controller manager handles communications between FE(Bridge) and BE(Deployment Manager & Engine)
  """

  use GenServer

  alias Discovery.Utils

  ### CLIENT FUNCTIONS ###
  @spec start_link(any()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_deployment_data(app_name) do
    GenServer.call(__MODULE__, {"deployment_data", app_name})
  end

  def get_apps() do
    GenServer.call(__MODULE__, "get_apps")
  end

  def insert_app(app_name) do
    GenServer.call(__MODULE__, {"insert_app", app_name})
  end

  ### SERVER CALLBACKS ###
  def init(_args) do
    Process.send_after(self(), "populate_bridgedb", 5_000)
    {:ok, %{}}
  end

  def handle_call({"deployment_data", app_name}, _from, state) do
    data = lookup_deployments app_name
    {:reply, data, state}
  end

  def handle_call({"insert_app", app_name}, _from, state) do
    data = insert_app_to_bridgedb app_name
    {:reply, data, state}
  end

  def handle_call("get_apps", _from, state) do
    data =
      Utils.bridge_db
      |> :ets.tab2list()
      |> Enum.map(fn {app_name, _details} -> app_name end)
    {:reply, data, state}
  end

  def handle_info("populate_bridgedb", state) do
    populate_bridgedb()
    {:noreply, state}
  end

  ### HELPER FUNCTIONS ###
  defp lookup_deployments(app_name) do
    case :ets.lookup(Utils.metadata_db(), app_name) do
      [] -> %{}
      [{_app_name, deployment_map}] -> deployment_map
    end
  end

  defp insert_app_to_bridgedb(app_name) do
    case app_name |> lookup_app() do
      nil ->
        :ets.insert(Utils.bridge_db, {app_name, true})
        {:ok, :app_inserted}
      _ ->
        {:error, :app_present}
    end
  end

  defp lookup_app(app_name) do
    case :ets.lookup(Utils.bridge_db(), app_name) do
      [] -> nil
      [{_app_name, app_details}] -> app_details
    end
  end

  defp populate_bridgedb() do
    :ets.tab2list(Utils.metadata_db)
    |> Enum.each(fn {app_name, _details} -> :ets.insert(Utils.bridge_db, {app_name, true}) end)
  end

end
