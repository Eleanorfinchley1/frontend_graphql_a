use Mix.Config

config :billbored, Web.Endpoint,
  http: [:inet6, port: System.fetch_env!("PORT"), compress: true],
  url: [scheme: "https", port: 443],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :billbored, Repo,
  hostname: System.fetch_env!("DATABASE_HOST"),
  port: System.fetch_env!("DATABASE_PORT"),
  database: System.fetch_env!("DATABASE_NAME"),
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  prepare: :unnamed,
  pool_size: 40,
  idle_interval: 5_000,
  queue_target: 150,
  queue_interval: 1_000

config :billbored, BillBored.Redix,
  pool: [
    size: 10,
    max_overflow: 10
  ],
  redix: [
    host: "#{System.fetch_env!("REDIS_HOST")}",
    database: "#{System.get_env("REDIS_DB", "0")}"
  ]

config :billbored,
  prometheus_basic_auth: [
    username: "prometheus",
    password: "#{System.fetch_env!("METRICS_PASSWORD")}"
  ]

config :sentry,
  tags: %{
    env: System.fetch_env!("SENTRY_ENV_NAME")
  }

config :pigeon, :fcm,
  fcm_default: %{
    key: System.fetch_env!("FCM_SERVER_KEY")
  }

if System.get_env("APNS_DYNAMIC") do
  config :pigeon, :apns,
    apns_default: %{
      cert: System.fetch_env!("APNS_CERT"),
      key: System.fetch_env!("APNS_KEY"),
      mode: System.fetch_env!("APNS_MODE") |> String.to_atom()
    }
end

config :billbored, Mail.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: System.fetch_env!("SENDGRID_KEY")

config :billbored, Notifications.Template,
  default_apns_options: [
    topic: System.fetch_env!("APNS_BUNDLE_ID"),
    sound: "billborednoti.wav"
  ]

config :billbored, Pillar, url: System.fetch_env!("CLICKHOUSE_URL")

config :billbored, BillBored.Agora.Tokens,
  app_id: System.get_env("AGORA_APP_ID"),
  app_certificate: System.get_env("AGORA_APP_CERTIFICATE"),
  generator_path: Path.join(:code.priv_dir(:billbored), "bin/agora_token_generator")

config :billbored, BillBored.Agora.API,
  basic_auth: System.get_env("AGORA_BASIC_AUTH"),
  app_id: System.get_env("AGORA_APP_ID"),
  s3_config: %{
    bucket: System.get_env("STREAMS_S3_BUCKET"),
    access_key: System.get_env("STREAMS_S3_ACCESS_KEY"),
    secret_key: System.get_env("STREAMS_S3_SECRET_KEY"),
    public_prefix: System.get_env("STREAMS_S3_PUBLIC_PREFIX")
  }

config :kernel, inet_dist_use_interface: {127, 0, 0, 1}
