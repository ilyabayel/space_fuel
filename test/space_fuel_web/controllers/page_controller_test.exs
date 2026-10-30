defmodule SpaceFuelWeb.PageControllerTest do
  use SpaceFuelWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Fuel your next mission"
  end
end
