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
       show_modal: "none",
       can_create_app: true
     )}
  end

  @impl true
  def handle_event("create-app", %{"app-name" => app_name} = _params, socket) do
    if socket.assigns.can_create_app do
      app_name
      |> create_app()
    end

    socket =
      socket
      |> assign(can_create_app: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-app", %{"app" => app_name} = _params, socket) do
    socket =
      socket
      |> assign(selected_app: app_name)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-modal", _params, socket) do
    display =
      case socket.assigns.show_modal do
        "none" -> "block"
        "block" -> "none"
        _ -> "none"
      end

    socket =
      socket
      |> assign(show_modal: display, can_create_app: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hide-modal", _params, socket) do
    socket =
      socket
      |> assign(show_modal: "none", can_create_app: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info({"app-created", app_details}, socket) do
    %{app_name: app_name} = app_details

    socket =
      socket
      |> assign(apps: [app_name | socket.assigns.apps], show_modal: "none")

    {:noreply, socket}
  end

  defp get_apps do
    # sample app names
    [
      "T3",
      "Watchex",
      "Nightwatch",
      "WSGO"
    ]
  end

  defp create_app(app_name) do
    # mimics app creation
    Process.send_after(self(), {"app-created", %{app_name: app_name}}, 2000)
  end
end
