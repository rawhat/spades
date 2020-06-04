#FROM rust:latest AS gleam-build

#WORKDIR /opt/app


#RUN git clone https://github.com/gleam-lang/gleam.git && cd gleam && cargo build --release

FROM elixir:latest

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN apt update && \
    apt install -y inotify-tools nodejs

#COPY --from=0 /opt/app/gleam/target/release/gleam /bin/gleam

RUN curl -Lo /opt/gleam-v0.11.2.tar.gz https://github.com/gleam-lang/gleam/releases/download/v0.11.2/gleam-v0.11.2-linux-amd64.tar.gz && tar -xf /opt/gleam-v0.11.2.tar.gz -C /bin

RUN mkdir /opt/app

COPY . /opt/app

WORKDIR /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

RUN cd assets && npm install

CMD ["mix", "phx.server"]
