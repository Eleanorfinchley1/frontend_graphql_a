defmodule BillBored.MixProject do
  use Mix.Project

  def project do
    [
      app: :billbored,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: preferred_cli_env(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {BillBored.Application, []},
      extra_applications: [:sasl, :logger, :runtime_tools, :ssl, :poolboy]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "fake", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "fake", "dev"]
  defp elixirc_paths(_env), do: ["lib"]

  ## Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.10"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.10"},
      {:ecto, "~> 3.8", override: true},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_view, "~> 2.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0", override: true},
      {:plug_cowboy, "~> 2.0"},
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0-rc", only: :dev, runtime: false},
      {:distillery, "~> 2.1", runtime: false},
      {:ex_machina, "~> 2.3", only: [:dev, :test]},
      {:faker, "~> 0.13.0", only: [:dev, :test]},
      {:bamboo, "~> 1.2"},
      {:rihanna, "~> 2.0"},
      {:cortex, "~> 0.5.0", only: [:dev, :test]},
      {:httpoison, "~> 2.2", override: true},
      {:totpex, "~> 0.1.3"},
      {:rexbug, "~> 1.0"},
      {:geo_postgis, "~> 3.0"},
      {:google_maps, "~> 0.11.0"},
      {:benchee, "~> 1.0", only: :bench},
      {:bcrypt_elixir, "~> 0.12"},
      {:phone_verification, "~> 0.4.0"},
      {:scrivener_ecto, "~> 2.0"},
      {:arc, "~> 0.11"},
      {:arc_ecto, "~> 0.11"},
      {:arc_gcs, "~> 0.1.0"},
      {:uuid, "~> 1.1"},
      {:distance, "~> 1.1.1"},
      {:ecto_cursor_pagination, "~> 0.1.1"},
      {:pigeon, "~> 1.2"},
      {:kadabra, "~> 0.4"},
      {:sentry, "~> 7.0"},
      {:exvcr, "~> 0.11.0", only: :test},
      {:slugify, "~> 1.2.0"},
      {:arbor, "~> 1.1.0"},
      {:prometheus, "~> 4.6", override: true},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_ecto, "~> 1.4"},
      {:prometheus_phoenix, "~> 1.3"},
      {:prometheus_plugs, "~> 1.1"},
      {:prometheus_process_collector, "~> 1.4.5"},
      {:bureaucrat, "~> 0.2.5", only: :test},
      {:ex_money, "~> 5.0"},
      {:ex_cldr_territories, "~> 2.0"},
      {:assertions, "~> 0.15.0", only: :test},
      {:torch, "~> 5.0"},
      {:geohash, git: "https://github.com/avkozlov-dev/elixir-geohash.git", ref: "b671b2d973ed97d8aaac217f3a9eb44f84ff7ec7", override: true},
      {:geobox, "~> 0.1.0"},
      {:quantum, "~> 2.4.0"},
      {:redix, "~> 1.3.0"},
      {:poolboy, "~> 1.5.2"},
      {:cors_plug, "~> 2.0"},
      {:pillar, "~> 0.18"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:tesla, "~> 1.8"},
      {:hackney, "~> 1.18"},
      {:openai, "~> 0.5.3"},
      {:comeonin, "~> 5.4"},
      {:elixir_make, "~> 0.7.7"}
      # {:mox, "~> 0.3", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.load --dump-path priv/repo/python_dump.sql",
        "ecto.migrate"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.migrate", "test"]
    ]
  end

  defp preferred_cli_env do
    [
      vcr: :test,
      "vcr.delete": :test,
      "vcr.check": :test,
      "vcr.show": :test
    ]
  end
end
