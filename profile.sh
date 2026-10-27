#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build
xcrun clang -fobjc-arc -Os -Wall -Wextra -Werror \
  -framework AppKit -framework ApplicationServices -framework IOKit -framework QuartzCore -framework IOSurface \
  tests/ui-profile.m -o build/ui-profile
MallocSpaceEfficient=1 ./build/ui-profile "$PWD/ui-performance.json"
