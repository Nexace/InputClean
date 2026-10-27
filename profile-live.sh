#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build
xcrun clang -Os -Wall -Wextra -Werror -framework CoreGraphics tests/resource-sample.c -o build/resource-sample
./build/resource-sample "${1:?Usage: ./profile-live.sh APP_PID}" "$PWD/live-performance.json"
