defmodule Copilot.Repo do
  use Ecto.Repo,
    otp_app: :copilot,
    adapter: Ecto.Adapters.Postgres
end
