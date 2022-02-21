# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

## General configs

config :logger, :console,
  level: :debug,
  format: "[$time] [$level] $metadata$message\n",
  metadata: [:application, :socket_id],
  colors: [info: :green]

## Database configs
if :elven_database in Mix.Project.deps_apps() do
  config :elven_database, ecto_repos: [ElvenDatabase.Repo]

  config :elven_database, ElvenDatabase.Repo,
    database: "elvengard_dev",
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    port: 5432
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
if File.exists?("#{__DIR__}/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
