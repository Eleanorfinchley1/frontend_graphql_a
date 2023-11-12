import Config


config :billbored, Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# watchers: [npm: ["run", "watch", cd: Path.expand("../assets", __DIR__)]]

config :billbored, Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/web/views/.*(ex)$},
      ~r{lib/web/templates/.*(eex)$}
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :billbored, Repo,
  database: System.get_env("POSTGRES_DB") || "billbored_dev",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  pool_size: 10

config :billbored, Mail.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: "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"

config :arc,
  storage: Arc.Storage.Local,
  storage_dir: "priv/uploads"

config :billbored, prometheus_basic_auth: [
  username: "prometheus",
  password: "password"
]

config :billbored, BillBored.Agora.Tokens,
  app_id: System.get_env("AGORA_APP_ID"),
  app_certificate: System.get_env("AGORA_APP_CERTIFICATE"),
  generator_path: System.get_env("AGORA_TOKEN_GENERATOR") || Path.expand("priv/bin/agora_token_generator")
