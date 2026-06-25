# Development

This guide covers setting up a local development environment and building Commet
from source. The Flutter app lives in the [`commet/`](../commet) directory — run
all `flutter`/`dart` commands from there unless noted otherwise.

## Prerequisites

- **Flutter** — the repo pins **3.44.1** via [`.fvmrc`](../commet/.fvmrc) (CI
  builds on `3.41.9` stable). Dart `>=3.6.0` is required. Using
  [FVM](https://fvm.app) is recommended so you match the pinned version.
- **Rust toolchain** ([`rustup`](https://rustup.rs)) — Commet bundles a native
  Rust library (`rust_lib_commet`, via `flutter_rust_bridge`). It is compiled
  automatically during the build by [cargokit](../rust/rust_builder/cargokit), so
  you only need `rustup`/`cargo` installed.
- **Platform-specific:**

  | Platform | Requirements |
  | --- | --- |
  | Linux | `cmake clang ninja-build rustup libgtk-3-dev libmpv-dev mpv ffmpeg libmimalloc-dev libwebkit2gtk-4.1-dev keybinder-3.0` |
  | Android | JDK 17, Android SDK / command-line tools |
  | macOS / iOS | Xcode + Command Line Tools, [CocoaPods](https://cocoapods.org) |
  | Windows | Visual Studio (Desktop C++), and `git config --global core.longpaths true` |
  | Web | none beyond Flutter |

## Get the code

```bash
git clone --recursive <your-fork-url>
cd <repo>/commet
```

## Install the pinned Flutter (FVM)

```bash
fvm install      # installs the version from .fvmrc (3.44.1)
fvm use
```

If you don't use FVM, install Flutter 3.44.1 manually and drop the `fvm` prefix
from the commands below.

## Generate code (required before the first run or build)

```bash
fvm dart run scripts/codegen.dart
```

This runs `flutter pub get`, generates localizations with `intl_utils`, and runs
`build_runner` (Drift database + JSON serialization). Re-run it after changing
`.arb` localizations, Drift tables, or other generated sources.

## Run

```bash
fvm flutter run --dart-define PLATFORM=<platform>
```

`PLATFORM` drives `BuildConfig` (desktop/mobile/web branches), so **always pass
it**. Values: `linux`, `windows`, `macos`, `android`, `ios`, `web`.

## Build

Every build needs `--dart-define PLATFORM=<platform>`:

```bash
fvm flutter build <target> --release --dart-define PLATFORM=<platform>
```

`<target>` is one of `linux`, `windows`, `apk` (Android), `macos`, `web`.

Alternatively use the release helper, which sets the version name and all the
`--dart-define`s the official builds use (and streams the build output live):

```bash
fvm dart run scripts/build_release.dart \
    --platform macos \
    --version_tag v0.4.2 \
    --git_hash $(git rev-parse HEAD)
```

## Building for macOS

> macOS is not yet an officially released target, but the project builds and runs
> on macOS. The fixes required for a working build are already in the repo.

**Prerequisites:** Xcode + Command Line Tools and CocoaPods (`brew install
cocoapods` or `sudo gem install cocoapods`).

```bash
cd commet
fvm dart run scripts/codegen.dart
fvm flutter build macos --release --dart-define PLATFORM=macos
```

Output:

```
commet/build/macos/Build/Products/Release/commet.app
```

Run it with `open build/macos/Build/Products/Release/commet.app`.

### Signing & distribution

The default build is **ad-hoc signed** (`CODE_SIGN_IDENTITY = "-"`): it runs on
the machine that built it, but Gatekeeper blocks it on other Macs. To distribute,
sign with a **Developer ID Application** certificate and **notarize**
(`xcrun notarytool submit`), then optionally wrap it in a `.dmg`.

### macOS specifics already configured

These are handled by the repo — listed so you know what's going on:

- **Sandbox entitlements** — `network.client` (homeserver), `network.server`
  (calls), and `files.user-selected.read-write` (attachments) are set in
  `macos/Runner/{Release,DebugProfile}.entitlements`.
- **WebRTC-SDK pod conflict** — `flutter_webrtc` and `livekit_client` pin
  different `WebRTC-SDK` patch versions; `macos/Podfile` re-aligns them at
  pod-install time. Tracked in issue #196 (remove the workaround once upstream
  aligns).
- **E2EE** — vodozemac is initialized via the native `flutter_vodozemac`
  framework on macOS (not the wasm path).
- **Emoji** — rendered with the system *Apple Color Emoji* font; Impeller is
  disabled (`FLTEnableImpeller=false`) so color fonts render.

### macOS troubleshooting

- **`pod install` fails: "WebRTC-SDK could not find compatible versions … 137 …"**
  — the committed/cached `Podfile.lock` is stale. Delete `macos/Podfile.lock` and
  rebuild; the Podfile re-aligns the version automatically.
- **The build appears frozen** — `flutter build macos --release` AOT-compiles all
  Dart (`gen_snapshot`) and builds CocoaPods/Xcode; it can take 5–20 min. Use
  `ps aux | grep -E 'gen_snapshot|xcodebuild|clang'` in another terminal to
  confirm it's working.
