FROM erlang:slim

RUN apt update && \
    apt install -y inotify-tools curl

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -

RUN apt install -y nodejs

ADD https://github.com/gleam-lang/gleam/releases/download/v0.22.1/gleam-v0.22.1-linux-amd64.tar.gz gleam.tar.gz
RUN tar xvfz gleam.tar.gz && mv gleam /bin/gleam

RUN mkdir /opt/app

COPY . /opt/app

WORKDIR /opt/app

RUN gleam build

RUN cd assets && npm install

COPY startup.sh .

CMD ["./startup.sh"]
