#!/bin/sh
set -eu
cd "$(dirname "$0")"
app="InputClean.app"
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/inputclean-build.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
xcrun clang -fobjc-arc -Os -DNDEBUG -Wall -Wextra -Werror \
  -mmacosx-version-min=12.0 -framework AppKit -framework ApplicationServices -framework IOKit -framework QuartzCore -framework IOSurface \
  main.m -Wl,-dead_strip -o "$build_dir/InputClean"
cp "$build_dir/InputClean" "$app/Contents/MacOS/InputClean.new"
mv "$app/Contents/MacOS/InputClean.new" "$app/Contents/MacOS/InputClean"
cp Info.plist "$app/Contents/Info.plist"
if [ -f AppIcon.icns ]; then cp AppIcon.icns "$app/Contents/Resources/"; fi
codesign --force --sign - "$app"
codesign --verify --strict "$app"
