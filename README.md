## Setup

```sh
# start postgres with postgis
> docker-compose up
# install elixir dependencies
> mix deps.get
# setup db
> mix ecto.setup
```

## Run

```sh
> iex -S mix phx.server
```

## Test

```sh
# setup db
> MIX_ENV=test mix ecto.setup
> mix test
```
