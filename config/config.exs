# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :discovery, DiscoveryWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "g1PHdlhOK+iqbT8lX0iVWGra5tUPixVmSD752nswvRja0x1NLeqGEeSJdOR3/UVS",
  render_errors: [view: DiscoveryWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Discovery.PubSub,
  live_view: [signing_salt: "0tLW2WSY"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
