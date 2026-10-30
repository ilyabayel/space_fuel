defmodule SpaceFuelWeb.SecurityHeadersTest do
  use SpaceFuelWeb.ConnCase

  test "retains enforced headers and sends the configured report-only policy", %{conn: conn} do
    previous = Application.get_env(:space_fuel, :csp_report_only)

    on_exit(fn ->
      if previous,
        do: Application.put_env(:space_fuel, :csp_report_only, previous),
        else: Application.delete_env(:space_fuel, :csp_report_only)
    end)

    policy = "default-src 'self'; script-src 'self'; object-src 'none'"
    Application.put_env(:space_fuel, :csp_report_only, policy)
    conn = get(conn, ~p"/")
    assert get_resp_header(conn, "content-security-policy-report-only") == [policy]
    assert [enforced] = get_resp_header(conn, "content-security-policy")
    assert enforced =~ "base-uri 'self'"
    assert enforced =~ "frame-ancestors 'self'"
  end
end
