defmodule Discovery.DeploymentTest do
  @moduledoc """
  Tests for `Discovery.Manager.Deployment`
  """
  use ExUnit.Case

  alias Discovery.Manager.Deployment

  @tag :skip
  test "create/1 (new app, with valid path)" do
    deployment = %Deployment{
      app_name: "t11",
      app_image: "madclaws/t11:latest"
    }

    assert Deployment.create(deployment) === :ok
  end

  @tag :skip
  test "create/1 (new app, with existing path)" do
    deployment = %Deployment{
      app_name: "t11",
      app_image: "madclaws/t11:latest"
    }

    File.mkdir!("minikube/discovery/" <> deployment.app_name)
    refute Deployment.create(deployment) === :ok
  end
end
