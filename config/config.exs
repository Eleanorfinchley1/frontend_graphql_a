import Config


# TODO remove
config :goth,
  json: "priv/account.json" |> Path.expand() |> File.read!()

config :phoenix, :format_encoders, json: Jason
config :phoenix, :json_library, Jason

# Configures the endpoint
config :billbored, Web.Endpoint,
  url: [host: System.get_env("WEB_ENDPOINT") || "localhost"],
  secret_key_base: "p7bTNGoPCxHJHHCIXhhRg4XTDay4yDjAdiwv+AQgjBRDiGtjSRZNxae3aBjl4LHE",
  render_errors: [view: Web.ErrorView, accepts: ~w(json)],
  pubsub: [name: Web.PubSub, adapter: Phoenix.PubSub.PG2],
  instrumenters: [Web.Instrumenter.Phoenix]

config :prometheus, Web.Instrumenter.Phoenix,
  controller_call_labels: [:controller, :action],
  channel_join_labels: [:channel, {:topic, Web.Instrumenter.Phoenix}, :transport],
  channel_receive_labels: [:channel, {:topic, Web.Instrumenter.Phoenix}, :transport, :event],
  registry: :default,
  duration_unit: :microseconds,
  duration_buckets: [
    1000,
    50_000,
    100_000,
    250_000,
    500_000,
    1_000_000,
    10_000_000
  ]

config :prometheus, Repo.Instrumenter,
  stages: [:queue, :query],
  counter: true,
  labels: [:result],
  duration_unit: :microseconds,
  query_duration_buckets: [
    1_000,
    50_000,
    100_000,
    250_000,
    500_000,
    750_000,
    1_000_000
  ]

config :prometheus, Metrics.Plug,
  path: "/", # SIC! Forwarded via pipeline at /metrics
  format: :auto,
  registry: :default

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :billbored, ecto_repos: [Repo]
config :billbored, Repo,
  timeout: 240_000,
  types: Repo.PostgrexTypes,
  telemetry_prefix: [:billbored, :repo]

config :billbored, BillBored.Redix,
  pool: [
    size: 10,
    max_overflow: 10
  ],
  redix: [
    host: System.get_env("REDIS_HOST") || "localhost"
  ]

config :billbored, BillBored.CachedPosts,
  marker_cache_ttl: 900,
  empty_marker_cache_ttl: 3600

config :rihanna,
  producer_postgres_connection: {Ecto, Repo}

config :billbored, Pillar,
  url: "http://localhost:8123/billbored_dev"

config :phone_verification,
  provider: PhoneVerification.Provider.Authy,
  default: [locale: :en, code_length: 4, via: :sms]

config :billbored, Notifications.Template,
  default_apns_options: [
    topic: "com.BillBored.Thyne",
    sound: "billborednoti.wav"
  ]

config :phone_verification, PhoneVerification.Provider.Authy,
  json_codec: Jason,
  #  api_key: System.get_env("AUTHY_API_KEY") || "ClbwV",
  api_key: "CqsX0htwBRJsk7xoIR7l5MQRtI8LbxW0",
  mocks: %{}

config :google_maps,
  api_key: "AIzaSyC_zFunEk0JJOqFgk7dxLfF9FlcUdOPdGU"

config :billbored,
  otp_secret: "RPMWQWNZGEMJXM5F"

config :arc,
  storage: Arc.Storage.Local

config :ecto_cursor_pagination,
  per_page: 15,
  cursor_id: :id

config :billbored, Eventful.API, api_key: "4wLznrDmn2rCW2x8"

config :billbored,
  torch_login_page_url: System.get_env("TORCH_LOGIN_URL") || "localhost"

config :billbored, Meetup.API,
  # required
  redirect_uri: "https://www.billbored.com/oauth2/redirect",
  consumer_key: "40p32itgad8gf924md0tt91gor",
  consumer_secret: {:system, "MEETUP_SECRET"}

config :billbored, Allevents.API,
  subscription_key: {:system, "ALLEVENTS_SUB_KEY"}

config :ex_money, default_cldr_backend: BillBored.Cldr

config :sentry,
  dsn: "https://public_key@app.getsentry.com/1",
  included_environments: [:prod],
  environment_name: Mix.env()

config :billbored, BillBored.Scheduler,
  global: true,
  overlap: false,
  jobs: [
    # Import COVID cases data snapshot every hour
    covid_scraper: [
      overlap: false,
      schedule: "0 * * * *",
      task: {Covid.DataScraper, :import_snapshot, []}
    ],

    # Send pending area notifications according to the timetable
    scheduled_area_notifications: [
      overlap: false,
      schedule: "*/10 * * * *",
      task: {BillBored.Notifications.AreaNotifications.TimetableEntries, :send_pending_notifications, []}
    ],

    # Sen pending location reward notifications
    scheduled_location_reward_notifications: [
      overlap: false,
      schedule: "*/7 * * * *",
      task: {BillBored.Workers.NotifyLocationRewards, :call, []}
    ],

    # Update dropchat stream recordings via Agora API
    update_stream_recordings: [
      overlap: false,
      schedule: "*/5 * * * *",
      task: {BillBored.Workers.UpdateStreamRecordings, :call, []}
    ],

    # Finish expired dropchat streams
    finish_expired_streams: [
      overlap: false,
      schedule: "* * * * *",
      task: {BillBored.Workers.FinishExpiredStreams, :call, []}
    ],

    # Expire dropchat stream recordings
    expire_stream_recordings: [
      overlap: false,
      schedule: "10 * * * *",
      task: {BillBored.Workers.ExpireStreamRecordings, :call, []}
    ],

    # Give Daily Points
    give_daily_points: [
      overlap: false,
      schedule: "0 9 * * *",
      task: {BillBored.Workers.GiveDailyPoints, :call, []}
    ],

    # Expire signup points
    expire_signup_points: [
      overlap: false,
      schedule: "*/5 * * * *",
      task: {BillBored.Workers.ExpireSignupPoints, :call, []}
    ],

    # Give absent points
    give_absent_points: [
      overlap: false,
      schedule: "0 0 */#{System.get_env("ABSENT_DAYS") || 3} * *",
      task: {BillBored.Workers.GiveAbsentPoints, :call, []}
    ],

    # Give bonus for donation points
    give_bonus_donation_points: [
      overlap: false,
      schedule: "* * * * *",
      task: {BillBored.Workers.GiveBonusDonationPoints, :call, []}
    ],

    give_anticipation_points: [
      overlap: false,
      schedule: "0 15-22 * * *",
      task: {BillBored.Workers.GiveAnticipationPoints, :call, []}
    ],

    # Generate topics
    topic_generator: [
      timeout: :infinity,
      overlap: false,
      schedule: "00 12 * * *",
      task: {BillBored.Workers.GiveBonusDonationPoints, :call, []}
    ],

    # Update dropchats list
    update_dropchats_list: [
      overlap: false,
      schedule: "* * * * *",
      task: {BillBored.Workers.UpdateDropchatsList, :call, []}
    ],

    # Leaderboard Notifications
    leaderboard_notification: [
      overlap: false,
      schedule: "* 16,1 * * *",
      task: {BillBored.Leaderboard, :team_daily_notification, []}
    ]

  ]

config :billbored, BillBored.Agora.API,
  basic_auth: System.get_env("AGORA_BASIC_AUTH"),
  app_id: System.get_env("AGORA_APP_ID"),
  s3_config: %{
    bucket: "billbored-dev-dropchat-streams",
    access_key: "AKIAW472U2NEILGC744R",
    secret_key: System.get_env("STREAMS_S3_SECRET_KEY"),
    public_prefix: "https://billbored-dev-dropchat-streams.s3.us-east-2.amazonaws.com"
  }

config :billbored, BillBored.UserPoints,
  signup_points: System.get_env("SIGNUP_POINTS") || 450, # 450 = 45 points
  signup_points_available_hours: System.get_env("SIGNUP_POINTS_AVAILABLE_HOURS") || 18, # 18 hours
  daily_points: System.get_env("DAILY_POINTS") || 450, # 450 = 45 points
  referral_points: System.get_env("REFERRAL_POINTS") || 100, # 100 = 10 points
  anticipation_points: System.get_env("ANTICIPATION_POINTS") || 100, # 100 = 10 points
  peak_percentages: %{
    listeners: System.get_env("PEAK_LISTENERS_PERCENTAGE") || 60, # 60%
    likes: System.get_env("LIKES_PERCENTAGE") || 25, # 25%
    claps: System.get_env("CLAPS_PERCENTAAGE") || 15 # 15%
  },
  signin_points: System.get_env("SIGNIN_POINTS") || 100, # 100 = 10 points
  points_per_minute: System.get_env("POINTS_PER_MINUTE") || 5, # 5 = 0.5 points
  absent_days: System.get_env("ABSENT_DAYS") || 3, # 3 Days
  absent_percentage: System.get_env("ABSENT_PERCENTAGE") || 10 # 10%

config :billbored, BillBored.Chat.Room.DropchatStreams,
  daily_free_minutes: System.get_env("DAILY_FREE_MINUTES") || 0 # Set this in 0. Instead, we are giving daily free streaming points.

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}],
  region: {:system, "AWS_REGION"},
  jason_codec: Jason

config :tesla, adapter: Tesla.Adapter.Hackney

config :openai,
  api_key: System.get_env("OPEN_AI_KEY"),
  http_options: [recv_timeout: :infinity]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
