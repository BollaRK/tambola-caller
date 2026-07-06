# AGENTS.md

## Cursor Cloud specific instructions

This is a single-product **Flutter (Dart)** app: `tambola_caller`, an offline Tambola/Housie number caller. There is **no backend** — all state is on-device (`shared_preferences`), so nothing external needs to be stood up.

### Toolchain
- Flutter SDK is installed at `/opt/flutter` and added to `PATH` via `~/.bashrc` (Flutter 3.44.x, Dart 3.12.x). New non-login shells may not have it on `PATH`; if `flutter` is not found, run `export PATH="$PATH:/opt/flutter/bin"`.
- Only the **web** target works here. `flutter doctor` reports the Android and Linux-desktop toolchains as missing (no Android SDK; `ninja`/`libgtk-3-dev` not installed) — this is expected and not needed for web development.

### Common commands (run from repo root)
- Install deps: `flutter pub get` (also the startup update script).
- Lint / static analysis: `flutter analyze` (config in `analysis_options.yaml`). Expect many `info`-level deprecation hints (`withOpacity`, `groupValue`/`onChanged` Radio) — these are pre-existing, not errors.
- Tests: `flutter test`.
- Run (dev, web): `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0` then open `http://localhost:8080`. (`flutter run -d chrome` also works but auto-launches Chrome.)

### Gotchas
- `test/widget_test.dart` is a **pre-existing failing test** — it's the leftover default counter-app template referencing `const MyApp()`, which does not exist (the real root widget is `TambolaApp` in `lib/main.dart`). `flutter analyze` reports this as an error and `flutter test` fails on it. This is a repo code bug, unrelated to environment setup; do not treat it as a setup problem.
- Flutter web needs a few seconds to compile/render on first load — wait for the home screen before interacting.
