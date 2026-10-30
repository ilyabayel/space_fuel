#!/usr/bin/env bash
set -uo pipefail

# Non-mutating checks only. Run from the root of a Mix project.
if [[ ! -f mix.exs ]]; then
  echo 'ERROR: Run this script from a Mix project root (mix.exs required).' >&2
  exit 2
fi
if ! command -v mix >/dev/null 2>&1; then
  echo 'ERROR: Elixir/Mix is unavailable on PATH.' >&2
  exit 2
fi

status=0
run_check() {
  printf '\n--- %s ---\n' "$*"
  if "$@"; then
    echo 'PASS'
  else
    code=$?
    echo "FAIL (exit $code)" >&2
    status=1
  fi
}

run_check mix format --check-formatted
run_check mix compile --warnings-as-errors
run_check mix test

if mix help credo >/dev/null 2>&1; then
  run_check mix credo --strict
else
  echo 'SKIP: Credo is not installed/configured.'
fi

if [[ "${1:-}" == '--deep' ]]; then
  if mix help dialyzer >/dev/null 2>&1; then
    run_check mix dialyzer
  else
    echo 'SKIP: Dialyzer Mix task is not installed/configured.'
  fi
fi
exit "$status"
