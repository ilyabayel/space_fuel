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

  defp submit_snapshot(session, button) do
    evaluate(
      session,
      """
      (() => {
        const planner = document.querySelector('#mission-planner');
        const form = document.querySelector('#mission-form');
        form.requestSubmit(document.querySelector('#{button}'));
        return {
          pending: planner.dataset.missionPending,
          busy: planner.getAttribute('aria-busy'),
          loading: form.classList.contains('phx-submit-loading'),
          inert: ['#mission-form', '#mission-presets', '#reset-mission'].map(s => document.querySelector(s).inert),
          mass: document.querySelector('#mission_mass').value,
          readonly: document.querySelector('#mission_mass').readOnly,
          selects: [...form.querySelectorAll('select')].map(e => ({value: e.value, inert: !!e.closest('[inert]')})),
          addDisabled: document.querySelector('#add-step').disabled,
          presetsDisabled: [...document.querySelectorAll('.preset')].every(e => e.disabled),
          resetDisabled: document.querySelector('#reset-mission').disabled,
          statusVisible: getComputedStyle(document.querySelector('#mission-pending-status')).display !== 'none'
        };
      })()
      """,
      fn snapshot ->
        assert snapshot["pending"] == "true"
        assert snapshot["busy"] == "true"
        assert snapshot["loading"]
        assert snapshot["inert"] == [true, true, true]
        assert snapshot["mass"] == "28801"
        assert snapshot["readonly"]
        assert Enum.all?(snapshot["selects"], & &1["inert"])
        assert snapshot["addDisabled"]
        assert snapshot["presetsDisabled"]
        assert snapshot["resetDisabled"]
        assert snapshot["statusVisible"]
      end
    )
  end

  test "structural submissions lock the editor and preserve changes", %{conn: conn} do
    session = conn |> visit("/") |> assert_has("body .phx-connected")

    session =
      Enum.reduce(3..0//-1, session, fn index, session ->
        session |> press("#remove-step-#{index}", "Enter") |> refute_has("#remove-step-#{index}")
      end)

    session
    |> evaluate("window.liveSocket.enableLatencySim(500)")
    |> submit_snapshot("#add-step")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> assert_has("#result-step-1", text: "Launch Earth")
    |> fill_in("SPACECRAFT MASS", with: "1000")
    |> assert_has("#fuel-result", text: "517")
    |> press("#reset-mission", "Enter")
    |> assert_has("#fuel-result", text: "51,898")
    |> submit_snapshot("#remove-step-1")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> fill_in("SPACECRAFT MASS", with: "1000")
    |> assert_has("#result-step-2", text: "Launch Moon")
    |> assert_has("#result-step-3", text: "Land Earth")
    |> refute_has("#result-step-4")
    |> assert_has("#fuel-result", text: "1,155")
    |> evaluate("window.liveSocket.disableLatencySim()")
  end

  test "malformed mass invalidates the result and recovers", %{conn: conn} do
    session = conn |> visit("/") |> assert_has("#fuel-result", text: "51,898")

    session =
      Enum.reduce(["28801e", "1e3", "10.5", "abc", "", "0", "-1", "1000000000000"], session, fn mass, session ->
        session
        |> fill_in("SPACECRAFT MASS", with: mass)
        |> assert_has("#result-unavailable")
        |> refute_has("#fuel-result")
        |> fill_in("SPACECRAFT MASS", with: "28801")
        |> assert_has("#fuel-result", text: "51,898")
      end)

    session |> fill_in("SPACECRAFT MASS", with: "28801") |> assert_has("#fuel-result", text: "51,898")
  end

  test "Enter preserves the route, invalid submissions unlock, and reconnect restores editing", %{conn: conn} do
    conn
    |> visit("/")
    |> assert_has("body .phx-connected")
    |> evaluate(
      "window.routeBefore = [...document.querySelectorAll('.step-row')].map(row => [row.id, ...[...row.querySelectorAll('select')].map(s => s.value)])"
    )
    |> press("#mission_mass", "Enter")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> evaluate(
      "JSON.stringify(window.routeBefore) === JSON.stringify([...document.querySelectorAll('.step-row')].map(row => [row.id, ...[...row.querySelectorAll('select')].map(s => s.value)]))",
      &assert(&1)
    )
    |> fill_in("SPACECRAFT MASS", with: "0")
    |> assert_has("#result-unavailable")
    |> press("#add-step", "Enter")
    |> assert_has("#remove-step-4")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> assert_has("#result-unavailable")
    |> press("#remove-step-4", "Enter")
    |> refute_has("#remove-step-4")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> fill_in("SPACECRAFT MASS", with: "28801")
    |> assert_has("#fuel-result", text: "51,898")
    |> evaluate("window.liveSocket.enableLatencySim(500)")
    |> submit_snapshot("#add-step")
    |> evaluate("window.liveSocket.disconnect()")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> evaluate("window.liveSocket.disableLatencySim(); window.liveSocket.connect()")
    |> assert_has("body .phx-connected")
    |> refute_has("#mission-planner[data-mission-pending]")
    |> fill_in("SPACECRAFT MASS", with: "28801")
    |> assert_has("#fuel-result")
    |> press("#reset-mission", "Enter")
    |> assert_has("#fuel-result", text: "51,898")
  end

  for {width, height} <- [{320, 900}, {1440, 1000}] do
    @tag browser_context_opts: [viewport: %{width: width, height: height}]
    test "large results wrap within the #{width}px viewport", %{conn: conn} do
      session =
        conn
        |> visit("/")
        |> assert_has("body .phx-connected")
        |> fill_in("SPACECRAFT MASS", with: "999999999999")
        |> assert_has(".total-value", text: "1,849,866,067,144")
        |> screenshot("large-apollo-#{unquote(width)}.png")

      session =
        Enum.reduce(3..0//-1, session, fn index, session ->
          session |> press("#remove-step-#{index}", "Enter") |> refute_has("#remove-step-#{index}")
        end)

      session =
        Enum.reduce(0..49, session, fn index, session ->
          session
          |> press("#add-step", "Enter")
          |> assert_has("#remove-step-#{index}")
          |> refute_has("#mission-planner[data-mission-pending]")
        end)

      session
      |> assert_has(".total-value", text: "336,681,682,585,413,579,314,401")
      |> assert_has("#add-step[disabled]")
      |> evaluate(
        """
          (() => ({
            documentFits: document.documentElement.scrollWidth <= innerWidth,
            boxesFit: [...document.querySelectorAll('.total, .breakdown-row')].every(e => e.scrollWidth <= e.clientWidth),
            unit: document.querySelector('.total-unit').textContent.trim()
          }))()
        """,
        fn result ->
          assert result["documentFits"]
          assert result["boxesFit"]
          assert result["unit"] == "kg"
        end
      )
      |> screenshot("large-route-#{unquote(width)}.png")
      |> press("#remove-step-49", "Enter")
      |> refute_has("#remove-step-49")
      |> refute_has("#add-step[disabled]")
    end
  end
end
