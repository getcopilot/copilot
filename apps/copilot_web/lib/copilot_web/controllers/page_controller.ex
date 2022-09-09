defmodule CopilotWeb.PageController do
  use CopilotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
