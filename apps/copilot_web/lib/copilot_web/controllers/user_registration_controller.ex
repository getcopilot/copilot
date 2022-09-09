defmodule CopilotWeb.UserRegistrationController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Accounts
  alias Copilot.Accounts.User

  alias CopilotWeb.Authentication

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    changeset = Accounts.create_user_changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :update, &1)
          )

        conn
        |> put_flash(:info, "User created successfully")
        |> Authentication.login_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
