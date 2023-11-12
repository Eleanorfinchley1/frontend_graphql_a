import Config

config :billbored, Web.Endpoint, http: [port: 4002]

config :logger, level: :warn

config :billbored, Repo,
  database: "billbored_bench",
  hostname: "localhost",
  pool_size: 20
