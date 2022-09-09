defmodule CopilotWeb.SessionsControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  setup do
    %{user: insert(:user)}
  end

  describe "GET /login" do
    test "renders the login page", %{conn: conn} do
      conn = get(conn, Routes.sessions_path(conn, :new))

      assert html_response(conn, 200)
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn =
        conn
        |> login_user(user)
        |> get(Routes.sessions_path(conn, :new))

      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /login" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.sessions_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "copilot123"}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
    end

    test "logs the user in with remember me set", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.sessions_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => "copilot123",
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_copilot_web_user_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the user in with return to set", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.sessions_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "copilot123"}
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "returns errors with invalid credentials", %{conn: conn} do
      conn =
        post(conn, Routes.sessions_path(conn, :create), %{
          "user" => %{"email" => "foo@bar.com", "password" => "no"}
        })

      response = html_response(conn, 200)
      assert response =~ "Invalid"
    end
  end

  describe "GET /logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn =
        conn
        |> login_user(user)
        |> get(Routes.sessions_path(conn, :destroy))

      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if there is no user currently logged in", %{conn: conn} do
      conn = get(conn, Routes.sessions_path(conn, :destroy))

      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
