FROM erlang:slim

RUN apt update && \
    apt install -y inotify-tools curl xz-utils

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN apt install -y nodejs

ADD https://github.com/gleam-lang/gleam/releases/download/v0.22.1/gleam-v0.22.1-linux-amd64.tar.gz gleam.tar.gz
RUN tar xf gleam.tar.gz && mv gleam /bin/

ADD https://github.com/watchexec/watchexec/releases/download/cli-v1.20.4/watchexec-1.20.4-x86_64-unknown-linux-gnu.tar.xz watchexec.tar.xz
RUN tar xf watchexec.tar.xz && mv watchexec-1.20.4-x86_64-unknown-linux-gnu/watchexec /bin/

RUN mkdir /opt/app

COPY . /opt/app

WORKDIR /opt/app

RUN gleam build

RUN cd assets && npm install

COPY startup.sh .

CMD ["./startup.sh"]
