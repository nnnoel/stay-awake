# Stay Awake

A tiny macOS menu bar app: a coffee cup you click to keep your Mac awake.

- **Filled cup**: the Mac won't idle-sleep, and the screen stays on (configurable).
- **Outlined, dimmed cup**: normal macOS sleep behavior.

It was built to stop long-running work (AI coding sessions, builds, downloads,
remote shells) from being cut off when an aggressive sleep timer puts the Mac
to sleep and drops its network connections.

## Features

- **Click** the cup to toggle on or off.
- **Right-click** (or Control-click) for the menu:
  - current status (on or off, until when, and whether the screen is kept on)
  - **Stay Awake** toggle
  - **Keep Awake For** 1, 2, 4 or 8 hours, which switches off automatically when the time runs out
  - **Keep Screen On** (on by default)
  - **Launch at Login**
  - **Quit Stay Awake**
- Remembers your on/off choice and **Keep Screen On** across launches. Timed
  sessions don't change the remembered choice.
- Starts **on** the first time it runs.

## How it works

Stay Awake holds standard macOS power assertions through IOKit, the same
mechanism `caffeinate` uses:

| Assertion | Held when | Effect |
|---|---|---|
| `PreventUserIdleSystemSleep` | Stay Awake is on | The Mac doesn't idle-sleep, so network connections stay up |
| `PreventUserIdleDisplaySleep` | Stay Awake is on **and** Keep Screen On is checked | The display stays on, so the Mac doesn't lock |

- **Nothing in System Settings or `pmset` changes, and no admin password is
  needed.** Quitting the app, or the app crashing, releases the assertions
  immediately.
- **Closing a laptop lid or choosing Apple menu → Sleep still sleeps the Mac.**
  Only *idle* sleep is prevented.

Check what's being held at any time:

```sh
pmset -g assertions | grep "Stay Awake"
```

### Why the screen option exists

If macOS is set to require a password after the display turns off, letting the
display sleep also locks the Mac. With **Keep Screen On** checked, the screen
never turns off while Stay Awake is on, so the Mac never locks on its own.
Lock it manually (Control-Command-Q) when you step away.

## Requirements

- macOS 13 Ventura or newer (developed on macOS 27, Apple Silicon)
- Xcode Command Line Tools (`xcode-select --install`) to build

## Build and install

```sh
./build.sh
```

The script:

1. compiles `StayAwake.swift` with `swiftc` (one file, no dependencies)
2. assembles `build/Stay Awake.app` with `Info.plist` (`LSUIElement`, so there's no Dock icon)
3. ad-hoc code-signs the app
4. installs it into `~/Applications`, replacing any running copy, and launches it

To start it automatically, right-click the cup → **Launch at Login**, or add it
under System Settings → General → Login Items.

## Uninstall

1. Right-click the cup → **Quit Stay Awake**.
2. If enabled, turn off **Launch at Login** first (or remove it in Login Items).
3. Delete `~/Applications/Stay Awake.app`.
4. Optionally remove its saved preferences: `defaults delete dev.noel.stayawake`.

## Troubleshooting

| Symptom | Check |
|---|---|
| The screen still turns off | Right-click → make sure **Keep Screen On** is checked |
| The Mac still slept | `pmset -g assertions` should list "Stay Awake menu bar app"; manual sleep and closing the lid aren't blocked |
| "Couldn't change Launch at Login" | Add the app in System Settings → General → Login Items instead |
| macOS says the app can't be opened | It's ad-hoc signed for local use; build it yourself with `./build.sh`, or right-click → Open once |

## Files

| File | Purpose |
|---|---|
| `StayAwake.swift` | The whole app: power assertions, menu bar item, menu |
| `Info.plist` | Bundle metadata (menu-bar-only app, bundle id `dev.noel.stayawake`) |
| `build.sh` | Build, sign, install and launch |
