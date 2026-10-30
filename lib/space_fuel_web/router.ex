defmodule SpaceFuelWeb.Router do
  use SpaceFuelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpaceFuelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_csp_report_only
  end

  defp put_csp_report_only(conn, _opts) do
    case Application.get_env(:space_fuel, :csp_report_only) do
      nil -> conn
      policy -> Plug.Conn.put_resp_header(conn, "content-security-policy-report-only", policy)
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpaceFuelWeb do
    pipe_through :browser

    live "/", MissionLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpaceFuelWeb do
  #   pipe_through :api
  # end
end
