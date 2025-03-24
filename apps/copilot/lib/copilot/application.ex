defmodule Copilot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Copilot.Repo,
      {DNSCluster, query: Application.get_env(:copilot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Copilot.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Copilot.Finch}
      # Start a worker by calling: Copilot.Worker.start_link(arg)
      # {Copilot.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Copilot.Supervisor)
  end
end
