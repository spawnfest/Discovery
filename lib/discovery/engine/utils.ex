defmodule Discovery.Engine.Utils do
  @moduledoc """
  Utilities and helpers for engine
  """

  @doc """
  Returns the MetadataDB name.
  """
  @spec metadata_db() :: atom()
  def metadata_db do
    :metadatadb
  end
end
