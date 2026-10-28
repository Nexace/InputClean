#!/usr/bin/env python3
"""Capture real app views over an app-owned gradient, using the caller's screen access."""
from pathlib import Path
import json
import plistlib
import subprocess
import time

root = Path(__file__).resolve().parent.parent
assets = root / 'assets'
bundle = root / 'build/ReadmePhotos.app'
binary = bundle / 'Contents/MacOS/ReadmePhotos'
binary.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-Os', '-Wall', '-Wextra', '-Werror',
                '-framework', 'AppKit', '-framework', 'ApplicationServices', '-framework', 'IOKit',
                '-framework', 'QuartzCore', '-framework', 'IOSurface',
                str(root / 'tools/screenshots.m'), '-o', str(binary)], check=True)
info = {'CFBundleExecutable': 'ReadmePhotos', 'CFBundleIdentifier': 'local.amogh.InputClean.ReadmePhotos',
        'CFBundleName': 'InputClean Photos', 'CFBundlePackageType': 'APPL', 'LSUIElement': True,
        'LSMinimumSystemVersion': '14.0', 'NSHighResolutionCapable': True}
(bundle / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
subprocess.run(['codesign', '--force', '--sign', '-', str(bundle)], check=True)
request, ack = assets / '.capture-request.json', assets / '.capture-done'
for temporary in (request, ack):
    temporary.unlink(missing_ok=True)
launcher = subprocess.Popen(['open', '-W', '-n', str(bundle), '--args', str(assets)])
captured = set()
deadline = time.monotonic() + 35
try:
    while launcher.poll() is None and time.monotonic() < deadline:
        if request.exists():
            state = json.loads(request.read_text())
            name = state['name']
            if name not in {'ready.png', 'paused.png', 'mode-menu.png'}:
                raise RuntimeError('Unexpected capture filename')
            if name not in captured:
                region = ','.join(str(round(n)) for n in state['rect'])
                subprocess.run(['/usr/sbin/screencapture', '-x', '-R' + region, str(assets / name)], check=True)
                captured.add(name)
                ack.write_text(name)
        time.sleep(.05)
finally:
    for temporary in (request, ack):
        temporary.unlink(missing_ok=True)
if len(captured) != 3:
    raise RuntimeError(f'Captured {len(captured)} of 3 photos; check the preview app and Screen Recording access')
print('Captured ready, paused, and native mode-menu photos.')
