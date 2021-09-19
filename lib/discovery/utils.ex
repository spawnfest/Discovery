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

  @doc """
  Returns the MetadataDB name.
  """
  @spec metadata_db() :: atom()
  def metadata_db do
    :metadatadb
  end

  @doc """
  Returns the BridgeDB name.
  """
  @spec bridge_db() :: atom()
  def bridge_db do
    :bridgedb
  end
end
