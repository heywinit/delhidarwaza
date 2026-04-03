import Config

# The test environment is loaded when running `mix test`.

# Test logging: only errors, suppress warnings from expected failure cases
config :logger, :console,
  level: :error,
  format: "$time $metadata[$level] $message\n"
