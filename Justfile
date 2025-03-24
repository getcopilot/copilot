default:
    @just --choose

install:
    mix deps.get
    pnpm install --prefix apps/copilot_web/assets

setup:
    mix setup

console:
    iex -S mix

format *args:
    treefmt {{ args }}

lint:
    mix credo --strict

dialyzer *args:
    mix dialyzer {{ args }}

test *args:
    MIX_ENV=test mix test {{ args }}

server:
    mix phx.server

routes:
    mix phx.routes CopilotWeb.Router

migrate:
    mix ecto.migrate

debug-test *args:
    MIX_ENV=test iex -S mix test {{ args }} --trace

seed:
    mix run apps/copilot/priv/repo/seeds.exs

pnpm *args:
    pnpm {{ args }} --prefix apps/copilot_web/assets
