import Config

# The production environment is loaded when running `MIX_ENV=prod mix ...`

# Production logging: structured JSON logging
config :logger, :console,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:component, :event, :order_id, :trade_id, :user_id, :symbol]

For production, you might want to add file logging:
config :logger,
  backends: [:console, {LoggerFileBackend, :file}]

config :logger, :file,
  path: "/var/log/delhidarwaza/app.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:component, :event, :order_id, :trade_id, :user_id, :symbol]
