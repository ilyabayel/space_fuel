import Config

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Browser-based E2E tests
config :phoenix_test, otp_app: :space_fuel

# The listener is enabled only for browser tests.
config :space_fuel, SpaceFuelWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "uS+i0ipgo+gcRFpgs7lMA8LAAxD31OjN5oQBq9ToSLnNAZlV9ouIWNnCJYy2vMbn",
  server: System.get_env("E2E") == "1"
