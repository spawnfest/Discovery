defmodule DiscoveryWeb.PageLive do
  @moduledoc false
  use DiscoveryWeb, :live_view
  alias Discovery.Bridge.BridgeUtils
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
       deploy_app_warning: "none",
       modal_input?: true,
       selected_app_details: %{}
     )}
  end

  @impl true
  def handle_event("create-app", %{"app-name" => app_name} = _params, socket) do
    socket =
      if socket.assigns.modal_input? do
        case app_name |> create_app() do
          {:ok, :app_inserted} ->
            new_app = %{
              app_name: app_name,
              deployments: 0
            }

            socket
            |> assign(
              modal_input?: false,
              apps: [new_app | socket.assigns.apps],
              create_modal_display: "none"
            )

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
    selected_app_details =
      app_name
      |> BridgeUtils.get_deployment_data()

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
      |> assign(
        create_modal_display: "none",
        deploy_modal_display: "none",
        deploy_app_warning: "none",
        modal_input?: true
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("back", _params, socket) do
    socket =
      socket
      |> assign(selected_app: nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {"deployment-created", %{status: deployment_status, app_name: app_name}},
        socket
      ) do
    socket =
      case deployment_status do
        {:ok, _app_id} ->
          selected_app_details =
            app_name
            |> BridgeUtils.get_deployment_data()

          assign(
            socket,
            deploy_modal_display: "none",
            deploy_app_warning: "none",
            selected_app_details: selected_app_details,
            apps: get_apps()
          )

        {:error, _reason} ->
          socket |> assign(deploy_app_warning: "block")
      end

    {:noreply, socket}
  end

  ## HELPER FUNCTIONS ##
  defp get_apps do
    BridgeUtils.get_apps()
  end

  defp create_app(app_name) do
    app_name
    |> BridgeUtils.create_app()
  end

  defp create_deployment(%{app_name: app_name} = deployment_details) do
    deployment_status = BridgeUtils.create_deployment(deployment_details)

    Process.send_after(
      self(),
      {"deployment-created", %{status: deployment_status, app_name: app_name}},
      2000
    )
  end
end
