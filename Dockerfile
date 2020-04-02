FROM elixir:latest

WORKDIR /opt/app

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -

RUN apt update && \
    apt install -y inotify-tools nodejs

COPY config/ config
COPY lib/ lib
COPY mix.exs mix.exs
COPY mix.lock mix.lock

COPY assets/package.json /opt/apt/assets/package.json
COPY assets/package-lock.json /opt/apt/assets/package-lock.json
COPY assets/tsconfig.json /opt/app/assets/tsconfig.json
COPY assets/src /opt/app/assets/src
COPY assets/public /opt/app/assets/public

RUN cd assets && npm install && cd /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

CMD ["mix", "phx.server"]
