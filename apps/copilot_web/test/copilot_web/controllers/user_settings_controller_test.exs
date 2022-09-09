defmodule CopilotWeb.UserSettingsControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  alias Copilot.Accounts

  setup :register_and_login_user!

  describe "GET /settings" do
    test "renders the settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))

      assert html_response(conn, 200)
    end

    test "redirects if user not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))

      assert redirected_to(conn) == Routes.sessions_path(conn, :new)
    end
  end

  describe "PATCH /settings (update email form)" do
    @tag :capture_log
    test "updates the user's email", %{conn: conn, user: user} do
      conn =
        patch(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "copilot123",
          "user" => %{"email" => "foo@bar.com"}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "confirm"
      assert Accounts.find_user_by_email(user.email)
    end

    test "does not update the email with invalid data", %{conn: conn} do
      conn =
        patch(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "no sir"}
        })

      assert html_response(conn, 200)
      # assert response =~ "<h1>Settings</h1>"
      # assert response =~ "must have the @ sign and no spaces"
      # assert response =~ "is not valid"
    end
  end

  describe "PATCH /settings (update password form)" do
    test "updates the user password and resets all tokens", %{conn: conn, user: user} do
      post_request_conn =
        patch(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "copilot123",
          "user" => %{
            "password" => "123copilot",
            "password_confirmation" => "123copilot"
          }
        })

      assert redirected_to(post_request_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(post_request_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(post_request_conn, :info) =~ "success"
      assert Accounts.find_user_by_email_and_password(user.email, "123copilot")
    end

    test "does not update password with invalid data", %{conn: conn} do
      post_request_conn =
        patch(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "no",
            "password_confirmation" => "really, no"
          }
        })

      assert html_response(post_request_conn, 200)
      # assert response =~ "should be at least 8 character(s)"
      # assert response =~ "does not match password"
      # assert response =~ "is not valid"

      assert get_session(post_request_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "GET /settings/confirm_email/:token" do
    setup %{user: user} do
      email = build(:user).email

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{encoded_token: token, email: email}
    end

    test "updates the user email once", %{
      conn: conn,
      user: user,
      encoded_token: encoded_token,
      email: email
    } do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, encoded_token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "success"
      refute Accounts.find_user_by_email(user.email)
      assert Accounts.find_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, encoded_token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "invalid"
    end

    test "does not update the email when given an invaldui token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "invalid"
      assert Accounts.find_user_by_email(user.email)
    end

    test "redirects if the user is not logged in", %{encoded_token: encoded_token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, encoded_token))
      assert redirected_to(conn) == Routes.sessions_path(conn, :new)
    end
  end
end
