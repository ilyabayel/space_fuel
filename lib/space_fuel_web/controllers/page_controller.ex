defmodule SpaceFuelWeb.PageController do
  use SpaceFuelWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
