FROM ghcr.io/gleam-lang/gleam:v1.7.0-erlang

RUN apt update &&  apt install -y inotify-tools

ADD https://github.com/watchexec/watchexec/releases/download/v2.2.1/watchexec-2.2.1-x86_64-unknown-linux-musl.tar.xz watchexec.tar.xz
RUN tar xf watchexec.tar.xz && mv watchexec-2.2.1-x86_64-unknown-linux-musl/watchexec /bin/

WORKDIR /opt/app

COPY src/ /opt/app/src
COPY test/ /opt/app/test
COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml

RUN gleam build

RUN gleam run -m migrate

COPY run.sh ./run.sh
RUN chmod +x run.sh

ENTRYPOINT /opt/app/run.sh
