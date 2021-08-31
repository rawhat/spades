FROM elixir:latest

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -

RUN apt update && \
    apt install -y inotify-tools nodejs

RUN mkdir /opt/app

COPY . /opt/app

WORKDIR /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

RUN cd assets && npm install

COPY startup.sh .

CMD ["./startup.sh"]
