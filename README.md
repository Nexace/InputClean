# InputClean

A small native macOS menu bar app for cleaning your trackpad, keyboard, or both without accidental input.

![InputClean card typography](assets/card-preview.png)

## Use

1. Put InputClean in Applications and open it.
2. Grant **System Settings → Privacy & Security → Accessibility** access when prompted.
3. **Control-click** the keyboard/trackpad icon (or right-click) to choose **Clean trackpad**, **Clean keyboard**, or **Clean both**. A plain click starts or stops the chosen mode. Your choice stays selected for the current session; trackpad-only is the initial default.
4. Restore input with **five separate Esc presses**, or click the icon using an external mouse. In keyboard-only mode, the trackpad also remains usable.

Keep consecutive Esc presses within 1.5 seconds of each other. Holding Esc does not count; another key resets the sequence. A five-minute safety timeout also restores input.

External mouse events pass through unchanged, preserving macOS sensitivity and acceleration. Hover over the icon to see the chosen mode in the translucent status card. The right-click menu also provides Restore input and Quit.

Keyboard cleaning blocks ordinary keys, modifiers, and media controls from all keyboards. Power/Touch ID and controls reserved by macOS are outside the app's control. This is a temporary cleaning tool, not a security lock.

The app uses one process and has no network code, telemetry, or resident helper. Cleaning mode is temporary; it does not change trackpad preferences.

## Open at Login

After installing in Applications, enable the native macOS login item with:

```sh
/Applications/InputClean.app/Contents/MacOS/InputClean --enable-login
```

Manage it later in **System Settings → General → Login Items & Extensions**.

The same executable accepts `--disable-login` and `--login-status`. Login startup is optional and is not enabled by the build script.

## Build and check

Requires Xcode command line tools with the macOS 26 SDK or newer. The supplied app is built for Apple Silicon; the source builds for the host Mac's architecture. Minimum runtime macOS is 12; native login registration requires macOS 13 or later.

```sh
./build.sh
./test.sh
./profile.sh
```

The build is ad hoc signed, without Apple notarization. Rebuilding changes its signing hash, so macOS may require Accessibility access to be enabled again for an updated development build.

Tests cover the five-Esc sequence, held keys, interrupted sequences, timeouts, mode-specific keyboard filtering, pointer/gesture types, byte-for-byte preservation of native mouse events, mode reuse after recovery, menu activation after tracking ends, card layout, accessibility text, and view cleanup.

`tools/draw-icon.m` retains the native CoreGraphics source for the app icon.

## RAM and CPU

Measurements use physical footprint, kernel lifetime peak, and process CPU time. CPU percentages use one core as 100%. Values are machine and macOS specific.

| UI stress phase | Current RAM | Lifetime peak | Average CPU |
| --- | ---: | ---: | ---: |
| Initial idle, 10 seconds | 9.90 MB | 9.90 MB | 0.007% |
| 30 hover cycles | 13.08 MB | 13.81 MB | 0.180% |
| Five menu openings | 14.42 MB | 15.07 MB | 0.248% |
| Post-use idle, 10 seconds | 15.06 MB | 15.07 MB | 0.002% |

Raw UI stress measurements are in [ui-performance.json](ui-performance.json). These are from the UI harness using the same application code; [live-performance.json](live-performance.json) records the separately launched app. MB means decimal megabytes. The 7 MB RAM target remains unmet.

The earlier ten-minute baseline in live-performance.json ended at 10.88 MB, with a 10.90 MB lifetime peak. It recorded idle activity only, so it does not establish CPU or RAM usage while cleaning. Keyboard blocking and five-Esc recovery, trackpad blocking, and native mouse behavior were physically checked during development. The final Control-click mode menu and combined mode are awaiting confirmation. A tagged-event test in the live macOS event stream also confirmed keyboard suppression and five-Esc recovery.

The card uses native Clear Liquid Glass on macOS 26+, with a translucent popover fallback on earlier systems. One IOSurface draws the system typography. Temporary surfaces and the window are released on dismissal; a local event wakes AppKit to drain deferred window resources. A space-efficient allocator reduces retained heap memory. There is no repeating cursor polling timer.

To record a live session, run `./profile-live.sh APP_PID`, test all three cleaning modes, then leave the app idle for ten seconds. The sampler records every half-second and stops after all modes and the final idle period, or after ten minutes. In its JSON, `cleaning` is 0 for idle, 1 for trackpad, 2 for keyboard, and 3 for both.

## Implementation and compatibility

The event filter runs only during cleaning. Trackpad movement is confined to the last allowed cursor position and its events are suppressed. Recognized external mouse events are returned unchanged. Temporary event-tap interruptions are resumed when macOS permits it.

Menu selections start the input filter after AppKit has left the menu tracking loop. Choosing a mode also sets the icon's behavior for the rest of the current session, including after restoring input.

The click type and Control modifier are captured before closing the hover card, so closing transient UI cannot change which action the icon performs. Control-click also opens the mode menu when a trackpad's secondary click is unavailable.

Device routing uses undocumented CGEvent sender field 87 and public IORegistry metadata. This technique is described in [Mac Mouse Fix's device attribution code](https://github.com/noah-nuebling/mac-mouse-fix/blob/master/Helper/Utility/EventUtility.m); no source code from that project is included. Unknown pointing-device sources are suppressed, so some mouse drivers or automation-generated pointer events may also be blocked. Five Esc presses remain available for recovery. Browser and accessibility automation can still act directly, while synthetic keyboard/pointer events may be filtered. Switch cleaning mode off before using computer-control automation.

Developer diagnostics are opt-in with `INPUTCLEAN_DIAGNOSTICS=1`. They record selected modes, device sender IDs and aggregate blocked/passed counts, with no keystrokes or pointer coordinates.
