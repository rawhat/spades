#!/bin/sh

stty -echo
printf "DB Password: "
read DB_PASS
stty echo
printf "\n"

docker build -t spades -f release.Dockerfile ./
docker run --env DB_USER=${DB_USER} --env DB_PASS=${DB_PASS} --env DB_HOST=${DB_HOST} --env DB_NAME=${DB_NAME} --env PASSWORD_SALT=${PASSWORD_SALT} --net=host -d spades
