FROM ghcr.io/gleam-lang/gleam:v0.34.1-node

WORKDIR /opt/app

COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml
COPY src/ /opt/app/src
COPY test/ /opt/app/test

ADD https://github.com/watchexec/watchexec/releases/download/v1.25.1/watchexec-1.25.1-x86_64-unknown-linux-gnu.tar.xz /opt/app/watchexec.tar.xz
RUN tar -xf watchexec.tar.xz && cp watchexec-1.25.1-x86_64-unknown-linux-gnu/watchexec /usr/local/bin/

RUN gleam build

RUN gleam run -m esgleam/install

CMD ["watchexec", "-r", "--watch", "src", "gleam", "run", "-m", "build"]
