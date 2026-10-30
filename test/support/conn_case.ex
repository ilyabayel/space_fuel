defmodule SpaceFuelWeb.ConnCase do
  @moduledoc "Connection test helpers for the public Phoenix application."

  use ExUnit.CaseTemplate

  using do
    quote do
      use SpaceFuelWeb, :verified_routes

      import Phoenix.ConnTest

      # Import conveniences for testing with connections
      import Plug.Conn
      import SpaceFuelWeb.ConnCase

      # The default endpoint for testing
      @endpoint SpaceFuelWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
