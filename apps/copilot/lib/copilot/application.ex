defmodule Copilot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Copilot.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Copilot.PubSub}
      # Start a worker by calling: Copilot.Worker.start_link(arg)
      # {Copilot.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Copilot.Supervisor)
  end
end
