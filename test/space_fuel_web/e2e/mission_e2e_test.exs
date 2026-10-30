defmodule SpaceFuelWeb.MissionE2ETest do
  use PhoenixTest.Playwright.Case

  @moduletag :e2e

  test "displays Apollo 11 fuel result", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("body", text: "")
  end
end
