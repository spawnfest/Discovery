defmodule DiscoveryWeb.PageLive do
  @moduledoc false
  use DiscoveryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: %{}, apps: [], selected_app: nil)}
  end

  @impl true
  def handle_event("create-app", %{"app-name" => app_name}, socket) do
    app_name
    |> create_app()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select-app", %{"app" => app_name} = params, socket) do
    socket =
      socket
      |> assign(selected_app: app_name)

    {:noreply, socket}
  end

  @impl true
  def handle_info({"app-created", app_details}, socket) do
    %{app_name: app_name} = app_details

    socket =
      socket
      |> assign(apps: [app_name | socket.assigns.apps])

    {:noreply, socket}
  end

  defp create_app(app_name) do
    # mimics app creation
    Process.send_after(self(), {"app-created", %{app_name: app_name}}, 2000)
  end
end
