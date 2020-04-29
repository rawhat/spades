#!/bin/sh

stty -echo
printf "DB Password: "
read DB_PASS
stty echo
printf "\n"

if [ -z $SECRET_KEY ]; then
  SECRET_KEY_BASE="$(mix phx.gen.secret)"
else
  SECRET_KEY_BASE="${SECRET_KEY}"
fi

DATABASE_URL="ecto://${DB_USER}:${DB_PASS}@${DB_HOST}/spades"

docker build -t spades -f Dockerfile.release ./
docker run --env SECRET_KEY_BASE=$SECRET_KEY_BASE --env DATABASE_URL=$DATABASE_URL -p 4000:4000 -d spades
