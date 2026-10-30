defmodule SpaceFuelWeb.MissionLiveTest do
  use SpaceFuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "presets, validation and recovery", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")
    assert has_element?(view, "#fuel-result", "51,898")
    assert has_element?(view, "#visual-stage-1", "Launch Earth")
    assert has_element?(view, "#visual-stage-2", "Land Moon")
    view |> element("#preset-mars") |> render_click()
    assert has_element?(view, "#fuel-result", "33,388")
    assert has_element?(view, "#visual-stage-2", "Land Mars")
    view |> element("#preset-passenger") |> render_click()
    assert has_element?(view, "#fuel-result", "212,161")
    view |> element("#reset-mission") |> render_click()
    assert has_element?(view, "#fuel-result", "51,898")
    view |> form("#mission-form", mission: %{mass: "0"}) |> render_change()
    assert has_element?(view, "#result-unavailable")
    assert has_element?(view, "#visualization-unavailable")
    view |> form("#mission-form", mission: %{mass: "28801"}) |> render_change()
    assert has_element?(view, "#fuel-result", "51,898")
  end

  test "add, edit and remove rows", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")

    route = %{
      "0" => %{"action" => "launch", "planet" => "earth"},
      "1" => %{"action" => "land", "planet" => "moon"},
      "2" => %{"action" => "launch", "planet" => "moon"},
      "3" => %{"action" => "land", "planet" => "earth"}
    }

    render_change(view, "validate", %{
      "mission" => %{"mass" => "28801", "steps" => route, "steps_sort" => ["0", "1", "2", "3", "new"]}
    })

    assert has_element?(view, "#remove-step-4")
    assert has_element?(view, "#visual-stage-5", "Launch Earth")

    render_change(view, "validate", %{
      "mission" => %{"mass" => "28801", "steps" => route, "steps_sort" => ["0", "1", "2", "3"], "steps_drop" => ["1"]}
    })

    assert has_element?(view, "#result-step-2", "Launch Moon")
    refute has_element?(view, "#remove-step-3")

    render_change(view, "validate", %{
      "mission" => %{"mass" => "28801", "steps" => route, "steps_drop" => ["0", "1", "2", "3"]}
    })

    assert has_element?(view, "#empty-route")
    assert has_element?(view, "#visualization-empty")
    assert has_element?(view, "#fuel-result", "0")
  end

  test "editing a stage recalculates and preserves the other stages", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")

    view
    |> form("#mission-form", mission: %{steps: %{"1" => %{action: "launch", planet: "mars"}}})
    |> render_change()

    assert has_element?(view, "#result-step-2", "Launch Mars")
    assert has_element?(view, "#visual-stage-2", "Launch Mars")
    assert has_element?(view, "#result-step-3", "Launch Moon")
    refute has_element?(view, "#fuel-result", "51,898")
  end

  test "unexpected event parameters do not crash the session", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")
    render_hook(view, "preset", %{"name" => "unsupported"})
    render_hook(view, "validate", %{"mission" => "malformed"})
    assert has_element?(view, "#fuel-result", "51,898")
  end
end
