# SpaceFuel

A single-page spacecraft fuel planner built with Phoenix LiveView and embedded Ecto schemas. It has no database or external services.

## Setup

Install Elixir (see `mise.toml`) and Erlang/OTP, then run:

```sh
mix setup
mix phx.server
```

Open http://localhost:4000. Run the test suite with `mix test`, or the project checks with `mix precommit`.

## How it works

`Mission` and `FlightStep` validate the form. The pure domain modules are independent of Phoenix and Ecto: `Planet` owns gravity, `Maneuver` owns formulas and recursive fuel calculation, and `FuelCalculator` accumulates the mission's fuel. The LiveView calculates only valid missions. Each maneuver is evaluated backwards from the end of the route: its effective mass is the spacecraft dry mass plus the fuel needed for every later maneuver. The fuel needed to carry each fuel increment is calculated recursively until the next increment is nonpositive. Results are presented in flight order.

Gravity and formula coefficients are scaled integers, avoiding floating-point rounding. Spacecraft mass must be a positive integer number of kilograms, including for an empty route. Empty routes require zero fuel. Any sequence of supported launches and landings is accepted; the planner does not impose physical route constraints.

`Planet.gravity/1` returns m/s² scaled by 1,000, so Earth's 9.807 is stored as 9,807. `Maneuver.fuel_required/3` takes an action identifier, integer mass in kilograms, and scaled gravity. Formula coefficients are also scaled by 1,000 (42 means 0.042); dividing the product by 1,000,000 floors each increment before subtracting the offset in kilograms. `FuelCalculator.calculate/2` keeps the existing mass-and-steps interface and returns a `Result` with total fuel and the stage breakdown. Calculation functions assume validated inputs; changesets handle user input validation.

To add a supported planet or maneuver using the existing formula, extend the ordered `@planets` or `@maneuvers` definitions in its domain module. Each module's `options/0` supplies labels and string identifiers to both form dropdowns and inclusion validation. The calculator needs no changes. New planet/formula combinations must produce shrinking fuel increments to ensure termination. A maneuver requiring a different algorithm can be handled with pattern matching in `Maneuver`; protocols can be introduced if distinct maneuver data types become useful.

The included reference missions produce:

- Apollo 11: 28,801 kg spacecraft, 51,898 kg fuel
- Mars Mission: 14,606 kg spacecraft, 33,388 kg fuel
- Passenger Ship: 75,432 kg spacecraft, 212,161 kg fuel

## Limitations

This is a simplified fuel model, not an orbital mechanics simulation. Missions are not persisted: refreshing the page restores Apollo 11. LiveView form recovery restores an in-progress form after a connection interruption while the browser page remains open.
