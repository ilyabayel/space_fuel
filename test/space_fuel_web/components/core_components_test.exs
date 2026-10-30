defmodule SpaceFuelWeb.CoreComponentsTest do
  use SpaceFuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias SpaceFuelWeb.CoreComponents

  test "input retains caller descriptions when it adds error associations" do
    html =
      render_component(&CoreComponents.input/1, %{
        id: "choice",
        name: "choice",
        type: "select",
        options: ["One"],
        value: "One",
        errors: ["Invalid choice"],
        "aria-describedby": "choice-help"
      })

    assert html =~ ~s(aria-describedby="choice-help choice-errors")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(id="choice-errors")
  end
end
