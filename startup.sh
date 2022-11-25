#!/bin/sh

# watchexec -r -e gleam -- gleam run

trap killgroup INT

killgroup() {
  kill 0
}

(watchexec -r -e gleam -- gleam run) &
(cd assets && npm run watch) &
wait
