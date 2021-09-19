defmodule Discovery.Utils do
  @moduledoc """
  Common utility functions across contexts
  """
  @spec get_uid :: String.t()
  def get_uid do
    UUID.uuid1()
    |> String.split("-")
    |> List.first()
  end
end
