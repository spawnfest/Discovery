defmodule Discovery.Manager.Deployment do

  alias Discovery.Utils

  def make(deployment_details) do

    %{
      app_name: app_name,
      app_image: app_image,
    } = deployment_details

    uid = Utils.get_uid()

    app_details = %{
      app_name: app_name,
      app_image: app_image,
      uid: uid
    }

    cond do
      File.dir?("minikube/discovery"<>app_name) ->
        # update ingress
        create_ingress(app_details)
        # create app version folder
        create_app_version_folder(app_details)
      true ->
        # create main app folder
        create_app_folder(app_name)
        # create ingress
        create_ingress(app_details)
        # create app version folder
        create_app_version_folder(app_details)
    end

    # config_map =
    #   File.read!("priv/templates/configmap.yml.eex")
    #   |> String.replace("APP_NAME", app_name)
    # config_map_yml = File.open!("test-configmap.yml", [:write, :utf8])

    # deploy =
    #   File.read!("priv/templates/deploy.yml.eex")
    #   |> String.replace("APP_NAME", app_name)
    #   |> String.replace("UID", uid)
    #   |> String.replace("APP_IMAGE", app_image)
    # deploy_yml = File.open!("test-deploy.yml", [:write, :utf8])

    # service =
    #   File.read!("priv/templates/service.yml.eex")
    #   |> String.replace("APP_NAME", app_name)
    #   |> String.replace("UID", uid)
    # service_yml = File.open!("test-service.yml", [:write, :utf8])

    # ingress =
    #   File.read!("priv/templates/ingress.yml.eex")
    #   |> String.replace("APP_NAME", app_name)
    #   |> String.replace("UID", uid)
    # ingress_yml = File.open!("test-ingress.yml", [:write, :utf8])

    # IO.write(config_map_yml, config_map)
    # IO.write(deploy_yml, deploy)
    # IO.write(service_yml, service)
    # IO.write(ingress_yml, ingress)

  end

  defp create_app_folder(app_name) do
    File.mkdir("minikube/discovery/#{app_name}")
  end

  defp create_ingress(app_details) do
    %{
      app_name: app_name,
      uid: uid
    } = app_details

    ingress =
      File.read!("priv/templates/ingress.yml.eex")
      |> String.replace("APP_NAME", app_name)
      |> String.replace("UID", uid)
    ingress_yml = File.open!("minikube/discovery/#{app_name}/ingress.yml", [:write, :utf8])
    IO.write(ingress_yml, ingress)

  end

  defp create_app_version_folder(app_details) do

    %{
      app_name: app_name,
      app_image: app_image,
      uid: uid
    } = app_details

    File.mkdir("minikube/discovery/#{app_name}/#{app_name}-#{uid}")

    config_map =
      File.read!("priv/templates/configmap.yml.eex")
      |> String.replace("APP_NAME", app_name)
    config_map_yml = File.open!("minikube/discovery/#{app_name}/#{app_name}-#{uid}/configmap.yml", [:write, :utf8])

    deploy =
      File.read!("priv/templates/deploy.yml.eex")
      |> String.replace("APP_NAME", app_name)
      |> String.replace("UID", uid)
      |> String.replace("APP_IMAGE", app_image)
    deploy_yml = File.open!("minikube/discovery/#{app_name}/#{app_name}-#{uid}/deploy.yml", [:write, :utf8])

    service =
      File.read!("priv/templates/service.yml.eex")
      |> String.replace("APP_NAME", app_name)
      |> String.replace("UID", uid)
    service_yml = File.open!("minikube/discovery/#{app_name}/#{app_name}-#{uid}/service.yml", [:write, :utf8])

    IO.write(config_map_yml, config_map)
    IO.write(deploy_yml, deploy)
    IO.write(service_yml, service)
  end

end
