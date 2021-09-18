defmodule DiscoveryWeb.EndpointController do
  use DiscoveryWeb, :controller
  alias Discovery.Engine.Reader

  def get_endpoint(conn, params) do
    IO.puts("params => #{inspect(params)}")
    endpoint = Reader.get_endpoint(params["app_name"])
    json(conn, %{"endpoint" => endpoint})
  end
end
