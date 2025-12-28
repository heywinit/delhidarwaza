import Config

# The development environment is loaded by default
# using the `dev` environment.

# Development logging: more verbose
config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:component, :event, :order_id, :trade_id, :user_id, :symbol]
