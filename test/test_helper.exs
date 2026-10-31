ExUnit.start()

# Keep browser tests separate from fast unit/integration tests.
if System.get_env("E2E") != "1" do
  ExUnit.configure(exclude: [e2e: true])
end

if System.get_env("E2E") == "1" do
  {:ok, _pid} = PhoenixTest.Playwright.Supervisor.start_link()

  Application.put_env(
    :phoenix_test,
    :base_url,
    SpaceFuelWeb.Endpoint.url()
  )
end
