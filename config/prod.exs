import Config


config :pigeon, :apns,
  apns_default: %{
    key: System.get_env("APNS_AUTH_KEY"),
    key_identifier: System.get_env("APNS_KEY_ID"),
    team_id: System.get_env("APPLE_TEAM_ID"),
    mode:
      if Mix.env() == :prod do
        :prod
      else
        :dev
      end
  }

config :billbored, Web.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  version: Application.spec(:billbored, :vsn),
  server: true,
  root: "."

# TODO set to :warn once it's not staging anymore, but actually prod
config :logger, level: :debug

config :arc,
  storage: Arc.Storage.GCS,
  bucket: "billbored-beta-media-store-bucket-europe"

config :goth,
  json: "priv/account.json" |> Path.expand() |> File.read!()

config :billbored, Mail.Mailer,
  adapter: Bamboo.SendGridAdapter

config :sentry,
  filter: Web.SentryFilter,
  dsn: "https://dec4eb873a8c481b8b5dcdff15789fb1@sentry.io/1528012",
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()
