defmodule Discovery.Deploy.DeployUtils do
  @moduledoc """
  Deployment manager handles CRUD operations of app deployments
  """
  alias Discovery.Deploy.DeployUtils
  alias Discovery.Utils

  @root_dir "minikube/discovery/"

  @type t :: %DeployUtils{
          app_name: String.t(),
          app_image: String.t()
        }

  @type app :: %{
          app_name: String.t(),
          app_image: String.t(),
          uid: String.t()
        }

  defstruct(
    app_name: "",
    app_image: ""
  )

  @doc """
  Creates or updates an app deployment

  Returns :ok | {:error, reason}
  """
  @spec create(DeployUtils.t()) :: :ok | {:error, term()}
  def create(deployment_details) do
    uid = Utils.get_uid()

    app_details = %{
      app_name: deployment_details.app_name,
      app_image: deployment_details.app_image,
      uid: uid
    }

    case File.dir?(@root_dir <> app_details.app_name) do
      true ->
        create_ingress(:ok, app_details)
        |> create_app_version_folder(app_details)

      _ ->
        create_app_folder(app_details.app_name)
        |> create_ingress(app_details)
        |> create_app_version_folder(app_details)
    end
  end

  @spec create_app_folder(String.t()) :: :ok | {:error, term()}
  defp create_app_folder(app_name) do
    File.mkdir("minikube/discovery/#{app_name}")
  end

  @spec create_ingress(status :: :ok | {:error, term()}, app()) :: :ok | {:error, term()}
  defp create_ingress(:ok, app) do
    ingress_file = get_ingress_file_path(app)

    with {:ok, ingress_template} <- File.read(ingress_file),
         :ok <- write_to_ingress(ingress_template, app),
         do: :ok
  end

  defp create_ingress(error, _app), do: error

  @spec write_to_ingress(binary(), app()) :: :ok | {:error, term()}
  defp write_to_ingress(ingress_template, app) do
    ingress_out =
      String.replace(ingress_template, "APP_NAME", app.app_name)
      |> String.replace("UID", app.uid)

    case File.open("minikube/discovery/#{app.app_name}/ingress.yml", [:write, :utf8]) do
      {:ok, ingress_io} ->
        IO.write(ingress_io, ingress_out)
        File.close(ingress_io)
        update_ingress_paths(app)

      error ->
        error
    end
  end

  @spec update_ingress_paths(app()) :: :ok | {:error, term()}
  defp update_ingress_paths(app) do
    ingress_append_string = create_dynamic_ingress_path(app)

    case File.open("minikube/discovery/#{app.app_name}/ingress.yml", [:write, :utf8, :append]) do
      {:ok, ingress_io} ->
        IO.write(ingress_io, ingress_append_string)
        File.close(ingress_io)

      error ->
        error
    end
  end

  @spec create_dynamic_ingress_path(app()) :: String.t()
  defp create_dynamic_ingress_path(app) do
    """
    \s\s\s- path: /#{app.uid}(/|$)(.*)
    \s\s\s\sbackend:
    \s\s\s\s\sserviceName: #{app.app_name}-#{app.uid}
    \s\s\s\s\sservicePort: 80
    """
  end

  @spec get_ingress_file_path(app()) :: String.t()
  defp get_ingress_file_path(app) do
    case File.exists?("minikube/discovery/#{app.app_name}/ingress.yml") do
      true -> "minikube/discovery/#{app.app_name}/ingress.yml"
      _ -> "priv/templates/ingress.yml.eex"
    end
  end

  @spec create_app_version_folder(status :: :ok | {:error, term()}, app()) ::
          :ok | {:error, term()}
  defp create_app_version_folder(:ok, app) do
    with :ok <- File.mkdir("minikube/discovery/#{app.app_name}/#{app.app_name}-#{app.uid}"),
         :ok <- create_configmap(app),
         :ok <- create_deploy_yml(app),
         :ok <- create_service(app),
         do: :ok
  end

  @spec create_configmap(app()) :: :ok | {:error, term()}
  defp create_configmap(app) do
    with {:ok, config_template} <- File.read("priv/templates/configmap.yml.eex"),
         :ok <- write_to_configmap(config_template, app),
         do: :ok
  end

  @spec write_to_configmap(String.t(), app()) :: :ok | {:error, term()}
  defp write_to_configmap(config_template, app) do
    configmap_out =
      String.replace(config_template, "APP_NAME", app.app_name)
      |> String.replace("UID", app.uid)

    case File.open(
           "minikube/discovery/#{app.app_name}/#{app.app_name}-#{app.uid}/configmap.yml",
           [:write, :utf8]
         ) do
      {:ok, configmap_io} ->
        IO.write(configmap_io, configmap_out)
        File.close(configmap_io)

      error ->
        error
    end
  end

  @spec create_deploy_yml(app()) :: :ok | {:error, term()}
  defp create_deploy_yml(app) do
    with {:ok, deploy_template} <- File.read("priv/templates/deploy.yml.eex"),
         :ok <- write_to_deploy_yml(deploy_template, app),
         do: :ok
  end

  @spec write_to_deploy_yml(String.t(), app()) :: :ok | {:error, term()}
  defp write_to_deploy_yml(deploy_template, app) do
    deploy_out =
      String.replace(deploy_template, "APP_NAME", app.app_name)
      |> String.replace("UID", app.uid)
      |> String.replace("APP_IMAGE", app.app_image)

    case File.open("minikube/discovery/#{app.app_name}/#{app.app_name}-#{app.uid}/deploy.yml", [
           :write,
           :utf8
         ]) do
      {:ok, deploy_io} ->
        IO.write(deploy_io, deploy_out)
        File.close(deploy_io)

      error ->
        error
    end
  end

  @spec create_service(app()) :: :ok | {:error, term()}
  defp create_service(app) do
    with {:ok, service_template} <- File.read("priv/templates/service.yml.eex"),
         :ok <- write_to_service(service_template, app),
         do: :ok
  end

  @spec write_to_service(String.t(), app()) :: :ok | {:error, term()}
  defp write_to_service(service_template, app) do
    service_out =
      String.replace(service_template, "APP_NAME", app.app_name)
      |> String.replace("UID", app.uid)

    case File.open("minikube/discovery/#{app.app_name}/#{app.app_name}-#{app.uid}/service.yml", [
           :write,
           :utf8
         ]) do
      {:ok, service_io} ->
        IO.write(service_io, service_out)
        File.close(service_io)

      error ->
        error
    end
  end
end
