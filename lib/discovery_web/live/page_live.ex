defmodule DiscoveryWeb.PageLive do
  @moduledoc false
  use DiscoveryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       query: "",
       results: %{},
       apps: get_apps(),
       selected_app: nil,
       create_modal_display: "none",
       deploy_modal_display: "none",
       create_app_warning: "none",
       modal_input?: true,
       selected_app_details: %{}
     )}
  end

  @impl true
  def handle_event("create-app", %{"app-name" => app_name} = _params, socket) do
    # if socket.assigns.modal_input? do
    #   app_name
    #   |> create_app()
    # end

    # socket =
    #   socket
    #   |> assign(modal_input?: false)

    socket =
      if socket.assigns.modal_input? do
        case app_name |> create_app() do
          {:ok, app_name} ->
            socket |> assign(
              modal_input?: false,
              apps: [app_name | socket.assigns.apps],
              create_modal_display: "none")
          {:error, :app_present} ->
            socket |> assign(create_app_warning: "block")
        end
      else
        socket
      end


    {:noreply, socket}
  end

  @impl true
  def handle_event("create-deployment", %{"app-image" => app_image} = _params, socket) do
    if socket.assigns.modal_input? do
      %{
        app_name: socket.assigns.selected_app,
        app_image: app_image
      }
      |> create_deployment()
    end

    socket =
      socket
      |> assign(modal_input?: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-app", %{"app" => app_name} = _params, socket) do

    # %{
    #   "t3-2d5aea38" => %{"last_updated" => ~U[2021-09-19 08:27:58Z], "url" => ""},
    #   "t3-35aaaa48" => %{"last_updated" => ~U[2021-09-19 08:55:58Z], "url" => ""}
    # }

    selected_app_details =
      Discovery.Controller.DeploymentController.get_deployment_data(app_name)
      |> Enum.map(fn {name, value} -> Map.put(value, "name", name) end)
      |>IO.inspect()



      socket =
      socket
      |> assign(selected_app: app_name, selected_app_details: selected_app_details)


    {:noreply, socket}
  end

  @impl true
  def handle_event("show-create-modal", _params, socket) do
    display =
      case socket.assigns.create_modal_display do
        "none" -> "block"
        "block" -> "none"
        _ -> "none"
      end

    socket =
      socket
      |> assign(create_modal_display: display, modal_input?: true, create_app_warning: "none")

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-deploy-modal", _params, socket) do
    display =
      case socket.assigns.deploy_modal_display do
        "none" -> "block"
        "block" -> "none"
        _ -> "none"
      end

    socket =
      socket
      |> assign(deploy_modal_display: display, modal_input?: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide-modal", _params, socket) do
    socket =
      socket
      |> assign(create_modal_display: "none", deploy_modal_display: "none",  modal_input?: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("back", _params, socket) do
    socket =
      socket
      |> assign(selected_app: nil)

    {:noreply, socket}
  end

  # @impl true
  # def handle_info({"app-created", app_details}, socket) do
  #   %{app_name: app_name} = app_details

  #   socket =
  #     socket
  #     |> assign(apps: [app_name | socket.assigns.apps], create_modal_display: "none")

  #   {:noreply, socket}
  # end

  @impl true
  def handle_info({"deployment-created", deployment_details}, socket) do
    %{
      app_name: _app_name,
      app_image: _app_image,
      } = deployment_details

    socket =
      socket
      |> assign(deploy_modal_display: "none")

    {:noreply, socket}
  end

  defp get_apps do
    # # sample app names
    # [
    #   "t3",
    #   "watchex",
    #   "nightwatch",
    #   "wsgo"
    # ]

    Discovery.Controller.DeploymentController.get_apps()
  end

  defp create_app(app_name) do
    case Discovery.Controller.DeploymentController.insert_app(app_name) do
      {:ok, :app_inserted} ->
        {:ok, app_name}
      {:error, :app_present} ->
        {:error, :app_present}
    end
  end

  defp create_deployment(deployment_details) do
    %{app_name: app_name, app_image: app_image} = deployment_details

    Discovery.Deploy.DeployUtils.create(deployment_details)

    Process.send_after(self(), {"deployment-created", %{app_name: app_name, app_image: app_image}}, 2000)
  end
end
