FROM ghcr.io/gleam-lang/gleam:v1.7.0-erlang

RUN apt update && apt install -y inotify-tools

WORKDIR /opt/app

COPY gleam.toml gleam.toml
COPY manifest.toml manifest.toml
COPY src/ /opt/app/src

RUN gleam build

CMD ["gleam", "run", "-m", "lustre/dev", "start", "--port=5000"]
