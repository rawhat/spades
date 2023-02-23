# Build UI bundle
FROM node:latest AS ui

WORKDIR /opt/app

COPY assets/package.json /opt/app
COPY assets/package-lock.json /opt/app

RUN npm install

COPY assets /opt/app

RUN npm run build

# Build API release

FROM erlang:alpine as api

RUN apk add --no-cache openssl ncurses-libs

WORKDIR /opt/app

ADD https://github.com/gleam-lang/gleam/releases/download/v0.26.2/gleam-v0.26.2-x86_64-unknown-linux-musl.tar.gz ./gleam.tar.gz
RUN tar xfz gleam.tar.gz && chmod +x gleam && mv gleam /usr/bin/

COPY gleam.toml ./
COPY src src

RUN gleam export erlang-shipment

COPY --from=ui /opt/app/dist priv

ENV HOME /opt/app

ARG DB_USER
ARG DB_PASS
ARG DB_HOST
ARG DB_NAME

ENV DB_USER $DB_USER
ENV DB_PASS $DB_PASS
ENV DB_HOST $DB_HOST
ENV DB_NAME $DB_NAME

CMD ["./build/erlang-shipment/entrypoint.sh", "run"]
