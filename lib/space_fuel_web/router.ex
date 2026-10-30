defmodule SpaceFuelWeb.Router do
  use SpaceFuelWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpaceFuelWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
