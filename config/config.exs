# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :delhidarwaza,
  ecto_repos: []

# Configures the endpoint
# config :delhidarwaza, DelhiDarwazaWeb.Endpoint,
#   url: [host: "localhost"],
#   adapter: Phoenix.Endpoint.Cowboy2Adapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:component, :event, :order_id, :trade_id, :user_id, :symbol]

# Set log level based on environment
config :logger, level: :info

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
