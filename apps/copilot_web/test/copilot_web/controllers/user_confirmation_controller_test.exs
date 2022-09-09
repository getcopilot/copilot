defmodule CopilotWeb.UserConfirmationControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  setup do
    %{user: insert(:user, %{confirmed_at: nil})}
  end

  alias Copilot.Accounts
  alias Copilot.Repo

  describe "GET /users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.user_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response
    end
  end

  describe "POST /users/confirm" do
    test "sends a new confiration token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If you have an account"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not sent a confirmation token if the user is already confirmed", %{
      conn: conn,
      user: user
    } do
      Repo.update!(Accounts.User.confirm_changeset(user))

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If you have an account"
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send a confirmation token if the email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => "no"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If you have an account"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      conn = get(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "account has been confirmed"
      assert Accounts.find_user_by_id!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # When not logged in
      conn = get(conn, Routes.user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "invalid"

      # When logged in
      conn =
        build_conn()
        |> login_user(user)
        |> get(Routes.user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "invalid"
      refute Accounts.find_user_by_id!(user.id).confirmed_at
    end
  end
end
