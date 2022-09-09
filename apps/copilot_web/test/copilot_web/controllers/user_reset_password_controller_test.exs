defmodule CopilotWeb.UserResetPasswordControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  alias Copilot.Accounts
  alias Copilot.Repo

  setup do
    %{user: insert(:user)}
  end

  describe "GET /reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.user_reset_password_path(conn, :new))
      assert html_response(conn, 200)
    end
  end

  describe "POST /reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send a reset password reset token if the email is invalud", %{conn: conn} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /reset_password/:token" do
    setup %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{encoded_token: encoded_token}
    end

    test "renders the reset password form", %{conn: conn, encoded_token: encoded_token} do
      conn = get(conn, Routes.user_reset_password_path(conn, :edit, encoded_token))
      assert html_response(conn, 200)
    end

    test "redirects with an invalid token", %{conn: conn} do
      conn = get(conn, Routes.user_reset_password_path(conn, :edit, "no"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "invalid"
    end
  end

  describe "PATCH /reset_password/:token" do
    setup %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{encoded_token: encoded_token}
    end

    test "resets the password once", %{conn: conn, user: user, encoded_token: encoded_token} do
      conn =
        patch(conn, Routes.user_reset_password_path(conn, :update, encoded_token), %{
          "user" => %{
            "password" => "123copilot",
            "password_confirmation" => "123copilot"
          }
        })

      assert redirected_to(conn) == Routes.sessions_path(conn, :new)
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "success"
      assert Accounts.find_user_by_email_and_password(user.email, "123copilot")
    end

    test "does not reset the password when given invalid data", %{
      conn: conn,
      encoded_token: encoded_token
    } do
      conn =
        patch(conn, Routes.user_reset_password_path(conn, :update, encoded_token), %{
          "user" => %{
            "password" => "no",
            "password_confirmation" => "also no"
          }
        })

      assert html_response(conn, 200)
    end

    test "does not reset password with an invalid token", %{conn: conn} do
      conn = patch(conn, Routes.user_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "invalid"
    end
  end
end
