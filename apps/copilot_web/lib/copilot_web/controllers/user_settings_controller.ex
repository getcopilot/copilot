defmodule CopilotWeb.UserSettingsController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Accounts
  alias CopilotWeb.Authentication

  plug :assign_email_and_password_changesets

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.verify_user_update_email(user, password, user_params) do
      {:ok, verified_user} ->
        Accounts.deliver_user_update_email_instructions(
          verified_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email has been sent to the new address"
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> Authentication.login_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  @spec confirm_email(Plug.Conn.t(), map) :: Plug.Conn.t()
  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully")
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired")
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  @spec assign_email_and_password_changesets(Plug.Conn.t(), any()) :: Plug.Conn.t()
  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.update_user_email_changeset(user))
    |> assign(:password_changeset, Accounts.update_user_password_changeset(user))
  end
end
