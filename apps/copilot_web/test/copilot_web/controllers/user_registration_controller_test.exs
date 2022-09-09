defmodule CopilotWeb.UserRegistrationControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  setup do
    %{user: insert(:user, %{confirmed_at: nil})}
  end

  describe "GET /register" do
    test "renders the register page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      assert html_response(conn, 200)
    end

    test "redirects if already logged in", %{conn: conn} do
      conn =
        conn
        |> login_user(insert(:user))
        |> get(Routes.user_registration_path(conn, :new))

      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/create" do
    @tag :capture_log
    test "creates an account and logs the user in", %{conn: conn} do
      email = build(:user).email

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => email, "password" => "copilot123", "name" => "Ernest Shackleton"}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/"
    end

    test "renders errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "foo"}
        })

      assert conn.assigns[:changeset]
      assert html_response(conn, 200)
    end
  end
end
