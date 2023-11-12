use Distillery.Releases.Config,
  default_release: :billbored,
  default_environment: Mix.env()

environment :dev do
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"=u||ugP<XhY?YvX~`p@FJIRD2pI,,e:.rR(;gzPqV5iawy`r@LA^IjP3QB&yUucy")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :"z@FF.{|>,8/|eP!E!I?%>Zt9d4__hBkH{;ZGi)bdkY;frpomF1@|L:}aQBn==Q]@")

  set(
    overlays: [
      {:copy, "rel/etc/config.exs", "etc/config.exs"},
      {:copy, "rel/etc/billbored.service.sample", "etc/billbored.service.sample"},
      {:copy, "rel/etc/billbored.env.sample", "etc/billbored.env.sample"}
    ]
  )

  set(
    config_providers: [
      {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
    ]
  )
end

release :billbored do
  # TODO
  set(version: "0.1.0")

  set(
    applications: [
      :parse_trans,
      :runtime_tools
    ]
  )

  set(pre_start_hooks: "rel/hooks/pre_start.d")

  set(
    commands: [
      migrate: "rel/hooks/pre_start.d/migrate.sh"
    ]
  )
end
