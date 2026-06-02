# Pickleball League Tournament App

Cross-platform (Android & iOS) pickleball doubles tournament app with player entry, partner selection, league scoring, standings, and knockout progression.

## Quick start

1. **Install Flutter** (see [BEGINNER_GUIDE.md](BEGINNER_GUIDE.md) for step-by-step setup).
2. **Open this folder** in a terminal.
3. **Create platform folders** (if you created the project manually and don’t have `android/` and `ios/` yet):
   ```bash
   flutter create .
   ```
   Answer **n** when asked to overwrite existing files, so your `lib/` and `pubspec.yaml` are kept.
4. **Install dependencies:**
   ```bash
   flutter pub get
   ```
5. **Run the app:**
   ```bash
   flutter run
   ```
   Use an Android emulator, iOS simulator, or a connected device.

## Commands summary

| Command | Purpose |
|--------|---------|
| `flutter pub get` | Install packages (run after changing `pubspec.yaml`). |
| `flutter run` | Build and run on the default device. |
| `flutter devices` | List available devices. |
| `flutter run -d <id>` | Run on a specific device. |
| `flutter build apk` | Build an Android APK (output in `build/app/outputs/flutter-apk/`). |

## Features

- **Player setup:** Enter player names and remove unassigned players before the tournament starts.
- **Partner selection:** Create doubles teams by choosing two unassigned players.
- **League stage:** Generates a round-robin schedule where every team plays every other team once.
- **Score entry:** Enter or edit each match score; tied scores are blocked because every pickleball match needs a winner.
- **Standings:** Automatically ranks teams by league points, wins, point difference, points scored, and team name.
- **Knockout progression:** Advances top teams based on team count:
  - 2-4 teams: top 2 go straight to the final.
  - 5-8 teams: top 4 go to semi finals.
  - 9+ teams: top 8 go to quarter finals.
- **Final champion:** Winners advance through the bracket until a champion is shown.
- **Resume:** Tournament state is saved locally and can be resumed later.
- **Dark mode and themes:** Toggle dark mode and choose a color theme from the app bar.

## QA and testing

Run `flutter test` for automated coverage of the home screen and tournament progression.

## Project layout

See **[BEGINNER_GUIDE.md](BEGINNER_GUIDE.md)** for framework choice, concepts, folder structure, and setup in detail.
