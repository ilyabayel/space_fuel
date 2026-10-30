# SpaceFuel

A single-page spacecraft fuel planner built with Phoenix LiveView and embedded Ecto schemas. It has no database or external services.

## Setup

Install Elixir (see `mise.toml`) and Erlang/OTP, then run:

```sh
mix setup
mix phx.server
```

Open http://localhost:4000. Run the fast test suite with `mix test`, or the project checks with `mix precommit`. The fast suite does not start an HTTP listener.

For browser tests, install dependencies with `npm --prefix assets install` and `npm --prefix assets exec -- playwright install chromium`, build assets with `mix assets.build`, then run `E2E=1 mix test`. The browser suite binds `127.0.0.1:4002`; set `E2E_PORT` to use a different port.

## How it works

`SpaceFuel.Missions` is the public API. Its embedded schemas define and validate missions and flight stages, contracts check raw input before casting, and services perform fuel calculations. Internal catalogs own gravity, maneuver formulas, and reference missions. The LiveView calculates only valid missions. Each maneuver is evaluated backwards from the end of the route: its effective mass is the spacecraft dry mass plus the fuel needed for every later maneuver. The fuel needed to carry each fuel increment is calculated recursively until the next increment is nonpositive. Results are presented in flight order.

Gravity and formula coefficients are scaled integers, avoiding floating-point rounding. Spacecraft mass must be a positive integer number of kilograms up to 999,999,999,999 (at most 12 input characters), including for an empty route. Routes can contain at most 50 stages. Empty routes require zero fuel. Any sequence of supported launches and landings is accepted; the planner does not impose physical route constraints.

`SpaceFuel.Missions.gravity/1` returns m/s² scaled by 1,000, so Earth's 9.807 is stored as 9,807. `SpaceFuel.Missions.fuel_required/3` takes an action identifier, integer mass in kilograms, and scaled gravity. Formula coefficients are also scaled by 1,000 (42 means 0.042); dividing the product by 1,000,000 floors each increment before subtracting the offset in kilograms. `SpaceFuel.Missions.calculate_fuel/2` accepts a validated mass and ordered steps and returns a `Result` with total fuel and the stage breakdown. Calculation functions assume validated inputs; changesets handle user input validation.

To add a supported planet or maneuver using the existing formula, extend the ordered `@planets` or `@maneuvers` definitions in the corresponding catalog. Catalog options supply labels and string identifiers to both form dropdowns and inclusion validation. New planet/formula combinations must produce shrinking fuel increments to ensure termination.

The included reference missions produce:

- Apollo 11: 28,801 kg spacecraft, 51,898 kg fuel
- Mars Mission: 14,606 kg spacecraft, 33,388 kg fuel
- Passenger Ship: 75,432 kg spacecraft, 212,161 kg fuel

## Limitations

This is a simplified fuel model, not an orbital mechanics simulation. Missions are not persisted: refreshing the page restores Apollo 11. LiveView form recovery restores an in-progress form after a connection interruption while the browser page remains open.

## Content Security Policy

Production sends the existing enforced base/frame restrictions and a stricter report-only policy. Check browser developer tools for Content Security Policy violations while testing the deployed application, including reconnection and assets. No reporting endpoint is configured. After observing the policy in the intended deployment and resolving violations, promote the candidate policy to enforcement in a separate change.
