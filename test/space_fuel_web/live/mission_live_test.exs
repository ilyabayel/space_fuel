defmodule SpaceFuelWeb.MissionLiveTest do
  use SpaceFuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SpaceFuel.Missions

  test "flight step dropdowns expose the domain options", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")

    for {label, action} <- Missions.maneuver_options() do
      assert has_element?(
               view,
               "#mission-form #flight-steps select[name$='[action]'] option[value='#{action}']",
               label
             )
    end

    for {label, planet} <- Missions.planet_options() do
      assert has_element?(
               view,
               "#mission-form #flight-steps select[name$='[planet]'] option[value='#{planet}']",
               label
             )
    end
  end

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
    assert has_element?(view, "#fuel-result", "61,668")
  end

  test "unexpected event parameters do not crash the session", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")
    render_hook(view, "preset", %{"name" => "unsupported"})
    render_hook(view, "validate", %{"mission" => "malformed"})
    assert has_element?(view, "#mission-rejection", "malformed")
    assert has_element?(view, "#result-unavailable")
    view |> form("#mission-form", mission: %{mass: "28801"}) |> render_change()
    assert has_element?(view, "#fuel-result", "51,898")
  end

  test "malformed nested events are rejected and the session remains usable", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")

    for params <- [
          nil,
          %{"mass" => %{}},
          %{"mass" => "1000", "steps" => [["bad"]]},
          %{"mass" => "1000", "steps" => [%{"action" => %{}, "planet" => "earth"}]},
          %{"mass" => "1000", "steps" => "bad"},
          %{"mass" => "1000", "steps_sort" => List.duplicate("new", 51)}
        ] do
      render_hook(view, "validate", %{"mission" => params})
      assert has_element?(view, "#mission-rejection")
      assert has_element?(view, "#mission_mass[value='28801']")
      assert has_element?(view, "#result-unavailable")
      view |> form("#mission-form", mission: %{mass: "28801"}) |> render_change()
      assert has_element?(view, "#fuel-result", "51,898")
    end
  end

  test "validation messages and preset selection are exposed to assistive technology", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")
    assert has_element?(view, "#preset-apollo[aria-pressed=true]")
    view |> form("#mission-form", mission: %{mass: "0"}) |> render_change()
    assert has_element?(view, "#mission_mass[aria-invalid=true][aria-describedby=mission_mass-errors]")
    assert has_element?(view, "#mission_mass-errors", "must be greater than 0")
    refute has_element?(view, ".preset[aria-pressed=true]")
  end

  test "the maximum route disables adding, and duplicate IDs have a visible explanation", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")
    row = %{"action" => "launch", "planet" => "earth"}
    route = Map.new(0..49, &{to_string(&1), row})
    render_hook(view, "validate", %{"mission" => %{"mass" => "999999999999", "steps" => route}})
    assert has_element?(view, "#add-step[disabled]")
    assert has_element?(view, "#result-step-50")
    id = Ecto.UUID.generate()

    duplicate = [
      %{"id" => id, "action" => "launch", "planet" => "earth"},
      %{"id" => id, "action" => "land", "planet" => "moon"}
    ]

    render_hook(view, "validate", %{"mission" => %{"mass" => "1000", "steps" => duplicate}})
    assert has_element?(view, "#mission-rejection", "identifiers are invalid or duplicated")
    assert has_element?(view, "#result-unavailable")
    view |> element("#reset-mission") |> render_click()
    assert has_element?(view, "#fuel-result", "51,898")
  end

  test "invalid selections identify their messages", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/")

    render_hook(view, "validate", %{
      "mission" => %{"mass" => "1000", "steps" => [%{"action" => "fly", "planet" => "earth"}]}
    })

    assert has_element?(view, "select[aria-invalid=true][aria-describedby$='-errors']")
    assert has_element?(view, "#mission_steps_0_action-errors", "is invalid")
  end
end
