# Build UI bundle
FROM node:latest AS ui

WORKDIR /opt/app

COPY assets/package.json /opt/app
COPY assets/package-lock.json /opt/app

RUN npm install

COPY assets /opt/app

RUN npm run build

# Build API release

FROM elixir:alpine AS api

WORKDIR /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY --from=ui /opt/app/build priv

RUN mix phx.digest

# CMD ["/bin/sh"]

COPY lib lib
RUN MIX_ENV=prod mix do compile, release

# Combine
FROM alpine:latest

RUN apk add --no-cache openssl ncurses-libs

WORKDIR /opt/app

COPY --from=api /opt/app/_build/prod/rel/spades ./

ENV HOME /opt/app

ARG SECRET_KEY_BASE
ARG DATABASE_URL

ENV SECRET_KEY_BASE $SECRET_KEY_BASE
ENV DATABASE_URL $DATABASE_URL

CMD ["bin/spades", "start"]
