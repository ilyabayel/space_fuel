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

`Mission` and `FlightStep` validate the form; `FuelCalculator` is a pure module independent of Phoenix and Ecto. The LiveView manages the form and calculates only valid missions. Each maneuver is evaluated backwards from the end of the route: its effective mass is the spacecraft dry mass plus the fuel needed for every later maneuver. The fuel needed to carry each fuel increment is calculated recursively until the next increment is nonpositive. Results are presented in flight order.

Gravity and formula coefficients are scaled integers, avoiding floating-point rounding. Spacecraft mass must be a positive integer number of kilograms, including for an empty route. Empty routes require zero fuel. Any sequence of supported launches and landings is accepted; the planner does not impose physical route constraints.

The included reference missions produce:

- Apollo 11: 28,801 kg spacecraft, 51,898 kg fuel
- Mars Mission: 14,606 kg spacecraft, 33,388 kg fuel
- Passenger Ship: 75,432 kg spacecraft, 212,161 kg fuel

## Limitations

This is a simplified fuel model, not an orbital mechanics simulation. Missions are not persisted: refreshing the page restores Apollo 11. LiveView form recovery restores an in-progress form after a connection interruption while the browser page remains open.
