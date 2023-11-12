FROM elixir:1.10.0-alpine as build
ENV MIX_ENV=prod

WORKDIR /source
RUN mix local.hex --force && mix local.rebar --force

RUN apk update && apk add git build-base
# Install and compile dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY priv priv
COPY rel rel

RUN HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix deps.get
RUN mix deps.compile

# Compile and build the app
RUN mix compile
RUN mix distillery.release --verbose --env=prod



# Run the app
# -----------

FROM elixir:1.10.0-alpine
ENV MIX_ENV=prod
ENV PORT=3000
EXPOSE 3000
RUN apk update && apk add bash
WORKDIR /app
COPY --from=build /source/_build/${MIX_ENV}/rel/billbored .

CMD ["bin/billbored", "start"]
