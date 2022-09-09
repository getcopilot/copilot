defmodule CopilotWeb.AuthenticationTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  alias Copilot.Accounts

  alias CopilotWeb.Authentication

  @remember_me_cookie "_copilot_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CopilotWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{user: insert(:user), conn: conn}
  end

  describe "login_user/3" do
    test "stores a user token in the session", %{conn: conn, user: user} do
      conn = Authentication.login_user(conn, user)
      assert token = get_session(conn, :user_token)

      assert get_session(conn, :live_socket_id) ==
               "user_sessions:#{token}"

      assert redirected_to(conn) == "/"
      assert Accounts.find_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:foobar, "barfoo")
        |> Authentication.login_user(user)

      refute get_session(conn, :foobar)
    end

    test "redirects to the configured return to path", %{conn: conn, user: user} do
      conn =
        conn
        |> put_session(:user_return_to, "/foo")
        |> Authentication.login_user(user)

      assert redirected_to(conn) == "/foo"
    end

    test "writes a cookie if remember_me is true", %{conn: conn, user: user} do
      conn =
        conn
        |> fetch_cookies()
        |> Authentication.login_user(user, %{"remember_me" => "true"})

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]
      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_user/1" do
    test "clears the session and cookie", %{conn: conn, user: user} do
      {:ok, encoded_token} = Accounts.create_user_session_token(user)

      conn =
        conn
        |> put_session(:user_token, encoded_token)
        |> put_req_cookie(@remember_me_cookie, encoded_token)
        |> fetch_cookies()
        |> Authentication.logout_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"

      refute Copilot.Repo.one(Accounts.UserToken.find_by_user_and_context_query(user, :all))
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      CopilotWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> Authentication.logout_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn =
        conn
        |> fetch_cookies()
        |> Authentication.logout_user()

      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end
end
