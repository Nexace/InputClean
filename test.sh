#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p build
flags="-fobjc-arc -Os -Wall -Wextra -Werror"
xcrun clang $flags -framework AppKit -framework ApplicationServices -framework IOKit -framework QuartzCore -framework IOSurface check.m -o build/check
./build/check
xcrun clang $flags -framework AppKit -framework ApplicationServices -framework IOKit -framework QuartzCore -framework IOSurface tests/ui-check.m -o build/ui-check
./build/ui-check
