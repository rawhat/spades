#!/usr/bin/env bash

set -euo pipefail

gleam run -m migrate
watchexec --restart --verbose --wrap-process=session --stop-signal SIGTERM -e gleam --debounce 500ms --watch src/ -- "gleam run"
