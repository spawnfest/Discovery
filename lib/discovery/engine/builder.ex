defmodule Discovery.Engine.Builder do
  @moduledoc """
  Polls k8 and process the deployment data from k8s and push to ETS, as a kv pair,
  where key will be the app id and value will be the metadata of app.
  """

  require Logger
  alias Discovery.Engine.Utils
  use GenServer

  @type t :: %__MODULE__{
          conn_ref: nil | map(),
          deployment_info: nil | map()
        }

  defstruct(
    conn_ref: nil,
    deployment_info: %{}
  )

  @k8_fetch_interval 5_000

  ## Client functions ##
  @spec start_link(any()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## Server callbacks ##
  @impl true
  def init(_init_arg) do
    Logger.info("Engine builder started.")
    # create a k8 connection
    # Then start polling and building
    k8_conn_ref = connect_to_k8()
    state = __MODULE__.__struct__(conn_ref: k8_conn_ref)
    Logger.info("Initial Builder state => #{inspect(state)}")
    Process.send_after(self(), "fetch_deployment_data", @k8_fetch_interval - 2_000)
    {:ok, state}
  end

  @impl true
  def handle_info("fetch_deployment_data", state) do
    updated_state = build_metadata(state)
    Process.send_after(self(), "fetch_deployment_data", @k8_fetch_interval)
    {:noreply, updated_state}
  end

  ## Utilities functions ##

  # Connects to Kubernetes
  @spec connect_to_k8() :: any()
  defp connect_to_k8 do
    case K8s.Conn.from_file("~/.kube/config", context: "minikube") do
      {:ok, conn_ref} ->
        Logger.info("K8 connection success")
        conn_ref

      {:error, reason} ->
        Logger.info("Error while K8 conneciton due to #{inspect(reason)}")
        # V2: Add connection retry for prod case
        nil
    end
  end

  # By the end, metadata of apps will be updated in metadata_db (ETS).
  @spec build_metadata(__MODULE__.t()) :: any()
  defp build_metadata(%{conn_ref: nil} = state), do: state

  defp build_metadata(state) do
    fetch_deployment_list(state)
    |> update_metadata_db(state)
  end

  # Fetching the entire deployment data as a list for the namespace
  # [{Deployment_A, Deployment_B...., Deployment_N}]

  @spec fetch_deployment_list(__MODULE__.t()) :: list(map())
  defp fetch_deployment_list(state) do
    # V2: namespace should discovery, i guess, as not only games are deployed.
    response =
      K8s.Client.list("apps/v1", "Deployment", namespace: "games")
      |> then(&K8s.Client.run(state.conn_ref, &1))

    case response do
      {:ok, data} ->
        data["items"]

      {:error, reason} ->
        IO.puts("Error on fetching deployment, due to #{inspect(reason)}")
        nil
    end
  end

  # @docp """
  # Iterate through each deployment, and update the metadata for each app in metadata_db.
  # """

  @spec update_metadata_db(list(map()), __MODULE__.t()) :: __MODULE__.t()
  defp update_metadata_db([], state), do: state

  defp update_metadata_db([deployment | t], state) do
    app_id = deployment["metadata"]["annotations"]["app_id"]
    # Logger.info("APP_ID: #{app_id}")

    update_app_metadata(app_id, deployment, state)
    |> then(&update_metadata_db(t, &1))
  end

  # @docp """
  # Update an apps deployment info in state.deployment_info[app_id]
  # %{
  #   "app_id" => %{
  #     "app-a" => %{"last_updated" => "timestamp", "url" => "deployment url"}
  #   }
  #  }
  # """

  @spec update_app_metadata(String.t(), map(), __MODULE__.t()) :: __MODULE__.t()
  defp update_app_metadata(app_id, app_k8_data, state) do
    app_deployment_name = app_k8_data["metadata"]["name"]

    app_info =
      Map.get(state.deployment_info, app_id, %{})
      |> Map.put(
        app_deployment_name,
        %{
          "last_updated" => get_last_updated_time(app_k8_data["status"]),
          "url" => get_deployment_url(app_deployment_name, state.conn_ref)
        }
      )

    :ets.insert(Utils.metadata_db(), {app_id, app_info})
    state = put_in(state.deployment_info[app_id], app_info)
    # Logger.info(inspect(state.deployment_info))
    state
  end

  # @docp """
  # Returns the latest updated time of pod
  # """
  @spec get_last_updated_time(map()) :: any()
  defp get_last_updated_time(status) do
    status["conditions"]
    |> Enum.map(fn condition -> DateTime.from_iso8601(condition["lastUpdateTime"]) end)
    |> Enum.map(fn {:ok, date, _offset} -> date end)
    |> Enum.sort({:desc, DateTime})
    |> List.first()
  end

  @spec get_deployment_url(String.t(), K8s.Conn.t()) :: String.t()
  defp get_deployment_url(app_deployment_name, connection) do
    # app deployment names are always in a format [app_id]-[serial-id]
    [app_id, path] = app_deployment_name |> String.split("-")

    ingress_response =
      K8s.Client.get("extensions/v1beta1", "ingress",
        namespace: "games",
        name: app_id
      )
      |> then(&K8s.Client.run(connection, &1))

    case ingress_response do
      {:ok, ingress_data} ->
        [rule | _rules] = ingress_data["spec"]["rules"]
        "#{rule["host"]}/#{path}"

      {:error, reason} ->
        IO.puts("Error on fetching ingress, due to #{inspect(reason)}")
        ""
    end
  end
end
