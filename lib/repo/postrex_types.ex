Postgrex.Types.define(
  Repo.PostgrexTypes,
  [BillBored.Geo.Types | Ecto.Adapters.Postgres.extensions()],
  json: Jason
)
