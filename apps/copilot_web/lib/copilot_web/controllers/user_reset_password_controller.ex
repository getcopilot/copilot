defmodule CopilotWeb.UserResetPasswordController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Accounts

  plug :fetch_user_by_reset_password_token when action in [:edit, :update]

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.find_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &Routes.user_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  @spec edit(Plug.Conn.t(), any) :: Plug.Conn.t()
  def edit(conn, _params) do
    changeset = Accounts.update_user_password_changeset(conn.assigns.user)

    render(conn, "edit.html", changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"user" => user_params}) do
    case Accounts.reset_user_password(conn.assigns.user, user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully")
        |> redirect(to: Routes.sessions_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  @spec fetch_user_by_reset_password_token(Plug.Conn.t(), any()) :: Plug.Conn.t()
  defp fetch_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if user = Accounts.find_user_by_reset_password_token(token) do
      conn
      |> assign(:user, user)
      |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or has expired")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
