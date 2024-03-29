import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :copilot, Copilot.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "copilot_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :copilot_web, CopilotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qPFpgbh+iXFOdksZ7sJe2YysjRZAgWrL3sAiAAdGdN+LAm4DGWI7DYHt9k8AMwj7",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :copilot, Copilot.Mailer, adapter: Swoosh.Adapters.Test

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Lower complexity of hashing in tests
config :argon2_elixir,
  t_cost: 1,
  m_cost: 8
