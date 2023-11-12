import Config


config :tzdata, :autoupdate, :disabled

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :billbored, Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :billbored, Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 20,
  queue_target: 1_000,
  queue_interval: 5_000

if url = System.get_env("DATABASE_URL") do
  config :billbored, Repo, url: url
else
  config :billbored, Repo,
    database: "billbored_test",
    hostname: "localhost",
    username: "postgres",
    password: "postgres"
end

config :billbored, BillBored.Redix,
  pool: [size: 0]

config :billbored, BillBored.ServiceRegistry, [
  {BillBored.Redix, BillBored.Stubs.Redix},
  {BillBored.CachedPosts.Server, BillBored.Stubs.CachedPostsServer},
  {BillBored.CachedPosts, BillBored.Stubs.CachedPosts},
  {Meetup, BillBored.Stubs.EventsProvider},
  {Allevents, BillBored.Stubs.EventsProvider},
  {BillBored.Clickhouse.PostViews, BillBored.Stubs.Clickhouse.PostViews},
  {BillBored.Clickhouse.UserLocations, BillBored.Stubs.Clickhouse.UserLocations},
  {BillBored.Agora.Tokens, BillBored.Stubs.AgoraTokens},
  {BillBored.Agora.API, BillBored.Stubs.AgoraAPI},
  {Notifications, Billbored.Stubs.Notifications}
]

config :billbored, Mail.Mailer, adapter: Bamboo.TestAdapter

config :billbored, BillBored.Agora.API,
  basic_auth: "ABC=",
  app_id: "0001",
  s3_config: %{
    bucket: "test-bucket",
    access_key: "ABABA",
    secret_key: "AFAFA",
    public_prefix: "https://test-bucket.aws"
  }

config :billbored, BillBored.Scheduler,
  global: true,
  jobs: []

if System.get_env("CI") do
  config :cortex, enabled: false
end

config :ex_unit,
  assert_receive_timeout: 500,
  exclude: [slow: true, fixture: true]
