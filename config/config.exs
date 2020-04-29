# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :spades,
  ecto_repos: [Spades.Repo]

# Configures the endpoint
config :spades, SpadesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "gNuWdW4suCqoW2P2OTszWMc6hNWRefgVutBXxTHb3jDSf1Jwq0QCfbC8Ppm6BID6",
  render_errors: [view: SpadesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Spades.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "AmbWDbkE"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Poison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
