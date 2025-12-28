import Config

# The test environment is loaded when running `mix test`.

# Test logging: minimal output, warnings and errors only
config :logger, :console,
  level: :warning,
  format: "$time $metadata[$level] $message\n"
