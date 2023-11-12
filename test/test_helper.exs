{:ok, _apps} = Application.ensure_all_started(:ex_machina)

Bureaucrat.start(
  writer: Bureaucrat.MarkdownWriter,
  default_path: "DOC.md",
  paths: [],
  titles: [{Web.NotificationController, "API /api/notifications"}],
  env_var: "DOC",
  json_library: Jason
)

ExUnit.start(formatters: [ExUnit.CLIFormatter, Bureaucrat.Formatter])

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)

{:ok, redix_pid} = BillBored.Stubs.Redix.start_link()
BillBored.Stubs.Redix.use_global(redix_pid)

Supervisor.start_link([{Phoenix.PubSub.PG2, name: ExUnit.PubSub}], strategy: :one_for_one)
