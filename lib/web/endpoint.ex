defmodule Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :billbored
  use Sentry.Phoenix.Endpoint

  socket "/socket", Web.UserSocket,
    websocket: [check_origin: [
      # dropchats.one
      "//*.beta.dropchats.one",
      "//*.dropchats.one",
      "//dropchats.one",

      # mightymap.fun
      "//*.beta.mightymap.fun",
      "//*.mightymap.fun",
      "//mightymap.fun"
    ]],
    longpoll: false

  plug Plug.Session,
    store: :cookie,
    key: "_billbored_session",
    encryption_salt:
      System.get_env("SESSION_ENCRYPTION_SALT") ||
        "LuYJ1KQmUK2PqTuVx+nvEmb3ROrt7oPLRf6axpbqldGOwtH8Bvn8Ap0ATTSmX+lq",
    signing_salt: System.get_env("SESSION_SIGNING_SALT") || "pagO3Sd/BiHrQ/EvoEoYf3+fsR6g0Och"

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :billbored,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  plug Plug.Static,
    at: "/.well-known",
    from: {:billbored, "priv/static/well-known"},
    gzip: false,
    content_types: %{"apple-app-site-association" => "application/json"}

  plug Plug.Static,
    at: "/fallback_event_images",
    from: {:billbored, "priv/static/fallback_event_images"},
    gzip: false

  plug Plug.Static,
    at: "/torch",
    from: {:billbored, "priv/static/torch"},
    gzip: true,
    cache_control_for_etags: "public, max-age=86400",
    headers: [{"access-control-allow-origin", "*"}]

  plug Plug.Static,
    at: "/torch",
    from: {:torch, "priv/static"},
    gzip: true,
    cache_control_for_etags: "public, max-age=86400",
    headers: [{"access-control-allow-origin", "*"}]

  plug Plug.Static,
    at: "/agora",
    from: {:billbored, "priv/agora"},
    gzip: false

if Mix.env() == :dev do
  plug Plug.Static,
    at: "/uploads",
    from: {:billbored, "priv/uploads"},
    gzip: false
end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug CORSPlug, origin: [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "https://dev.billbored.app",
    "https://dev.beta.billbored.app",
    "https://beta.billbored.app",
    "https://business.billbored.com",
    "https://test.business.billbored.com",
    "https://dev.mightymap.fun",
    "https://beta.mightymap.fun",
    "https://beta.dropchats.one",
    "https://dev.dropchats.one"
  ]

  plug(Web.Router)
end
