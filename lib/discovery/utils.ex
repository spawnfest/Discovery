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

  @spec metadata_db() :: atom()
  def metadata_db do
    :metadatadb
  end

  @spec puts_success(any) :: :ok
  def puts_success(term) do
    IO.puts(IO.ANSI.format([:green_background, :black, inspect(term)]))
  end

  @spec puts_warn(any) :: :ok
  def puts_warn(term) do
    IO.puts(IO.ANSI.format([:yellow_background, :black, inspect(term)]))
  end

  @spec puts_error(any) :: :ok
  def puts_error(term) do
    IO.puts(IO.ANSI.format([:red_background, :black, inspect(term)]))
  end
end
