defmodule CopilotWeb.UserConfirmationController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Accounts

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn, "new.html")
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.find_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :update, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If you have an account with us, you'll be receiving an email with confirmation instrutions shortly"
    )
    |> redirect(to: "/")
  end

  @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Your account has been confirmed! Please log in to continue")
        |> redirect(to: "/")

      :error ->
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Your confirmation link is invalid or it has expired")
            |> redirect(to: "/")
        end
    end
  end
end
