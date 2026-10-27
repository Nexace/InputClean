#!/bin/sh
set -eu
cd "$(dirname "$0")"
app="TrackpadClean.app"
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/trackpadclean-build.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
xcrun clang -fobjc-arc -Os -DNDEBUG -Wall -Wextra -Werror \
  -mmacosx-version-min=12.0 -framework AppKit -framework ApplicationServices -framework IOKit -framework QuartzCore -framework IOSurface \
  main.m -Wl,-dead_strip -o "$build_dir/TrackpadClean"
cp "$build_dir/TrackpadClean" "$app/Contents/MacOS/TrackpadClean.new"
mv "$app/Contents/MacOS/TrackpadClean.new" "$app/Contents/MacOS/TrackpadClean"
cp Info.plist "$app/Contents/Info.plist"
if [ -f AppIcon.icns ]; then cp AppIcon.icns "$app/Contents/Resources/"; fi
codesign --force --sign - "$app"
codesign --verify --strict "$app"
