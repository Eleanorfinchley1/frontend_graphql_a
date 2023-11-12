defmodule BillBored.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Meetup.API.Auth.initialize()
    Iso3166.initialize()
    BillBored.Clickhouse.initialize()

    Redix.Telemetry.attach_default_handler()

    children = [
      Signer.Config,
      Repo,
      {Rihanna.Supervisor, [postgrex: Repo.config()]},
      BillBored.Livestreams.InMemory,
      {Task.Supervisor, name: Eventbrite.TaskSupervisor},
      {Task.Supervisor, name: Eventful.TaskSupervisor},
      {Task.Supervisor, name: BillBored.TaskSupervisor},
      Web.Endpoint,
      Web.Presence,
      BillBored.Scheduler,
      BillBored.Redix.child_spec(),
      BillBored.CachedPosts.Server,
      BillBored.Users.OnlineTracker,
      BillBored.Chat.DropchatUpdateServer
    ]

    Metrics.setup()

    sentry_config = Application.get_all_env(:sentry)

    if sentry_config[:environment_name] in sentry_config[:included_environments] do
      {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BillBored.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
