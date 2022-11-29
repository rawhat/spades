FROM erlang:slim

RUN apt update && \
    apt install -y inotify-tools curl xz-utils

ADD https://github.com/gleam-lang/gleam/releases/download/v0.25.0/gleam-v0.25.0-x86_64-unknown-linux-musl.tar.gz gleam.tar.gz
RUN tar xf gleam.tar.gz && mv gleam /bin/

ADD https://github.com/watchexec/watchexec/releases/download/cli-v1.20.4/watchexec-1.20.4-x86_64-unknown-linux-gnu.tar.xz watchexec.tar.xz
RUN tar xf watchexec.tar.xz && mv watchexec-1.20.4-x86_64-unknown-linux-gnu/watchexec /bin/

RUN mkdir /opt/app
WORKDIR /opt/app

COPY src/ src/
COPY test/ /test/
COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml
COPY startup.sh startup.sh

RUN gleam build

CMD ["watchexec", "gleam", "run"]
