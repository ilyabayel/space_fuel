defmodule SpaceFuelWeb.MissionE2ETest do
  use PhoenixTest.Playwright.Case

  @moduletag :e2e

  test "calculator responds to edits, presets, stages, and Enter", %{conn: conn} do
    conn =
      conn
      |> visit("/")
      |> assert_has("body .phx-connected")
      |> assert_has("#fuel-result", text: "51,898")
      |> press("#preset-mars", "Enter")
      |> assert_has("#fuel-result", text: "33,388")
      |> press("#preset-passenger", "Enter")
      |> assert_has("#fuel-result", text: "212,161")
      |> press("#reset-mission", "Enter")
      |> assert_has("#fuel-result", text: "51,898")
      |> fill_in("SPACECRAFT MASS", with: "0")
      |> assert_has("#mission_mass[aria-invalid=true][aria-describedby=mission_mass-errors]")
      |> assert_has("#mission_mass-errors", text: "must be greater than 0")
      |> fill_in("SPACECRAFT MASS", with: "28801")
      |> assert_has("#fuel-result", text: "51,898")
      |> press("#add-step", "Enter")
      |> assert_has("#remove-step-4")
      |> press("#remove-step-4", "Enter")
      |> refute_has("#remove-step-4")

    conn =
      Enum.reduce(3..0//-1, conn, fn index, session ->
        session |> press("#remove-step-#{index}", "Enter") |> refute_has("#remove-step-#{index}")
      end)

    conn
    |> assert_has("#empty-route")
    |> press("#add-step", "Enter")
    |> assert_has("#remove-step-0")
    |> fill_in("SPACECRAFT MASS", with: "1000")
    |> press("#mission_mass", "Enter")
    |> assert_has("#result-step-1", text: "Launch Earth")
    |> assert_has("#fuel-result", text: "517")
    |> evaluate("window.location.pathname", &assert(&1 == "/"))
    |> evaluate("document.querySelector('#mission_mass').value", &assert(&1 == "1000"))
  end

  test "recovers an edited form after reconnecting", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("body .phx-connected")
    |> press("#preset-mars", "Enter")
    |> assert_has("#fuel-result", text: "33,388")
    |> evaluate("window.liveSocket.disconnect()")
    |> fill_in("SPACECRAFT MASS", with: "1000")
    |> evaluate("window.liveSocket.connect()")
    |> assert_has("#fuel-result", text: "1,583")
    |> evaluate("document.querySelector('#mission_mass').value", &assert(&1 == "1000"))
  end
end
