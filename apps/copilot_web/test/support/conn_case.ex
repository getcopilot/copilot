defmodule CopilotWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CopilotWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Copilot.Factory
      import Copilot.TestHelpers
      import CopilotWeb.ConnCase

      alias CopilotWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint CopilotWeb.Endpoint
    end
  end

  setup tags do
    Copilot.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @spec register_and_login_user!(%{conn: Plug.Conn.t()}) :: %{
          conn: Plug.Conn.t(),
          user: Copilot.Accounts.User.t()
        }
  def register_and_login_user!(%{conn: conn}) do
    user = Copilot.Factory.insert(:user)
    %{conn: login_user(conn, user), user: user}
  end

  @spec login_user(Plug.Conn.t(), Copilot.Accounts.User.t()) :: Plug.Conn.t()
  def login_user(conn, user) do
    {:ok, encoded_token} = Copilot.Accounts.create_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, encoded_token)
  end
end
