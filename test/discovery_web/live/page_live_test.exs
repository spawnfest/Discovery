defmodule DiscoveryWeb.PageLiveTest do
  use DiscoveryWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    # assert disconnected_html =~ "Discovery!"
    # assert render(page_live) =~ "Discovery!"
  end
end
