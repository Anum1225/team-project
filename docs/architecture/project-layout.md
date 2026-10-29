# Project folder guide

## Application and services

| Location | Purpose |
|---|---|
| `lib/` | Flutter entry point and active application code |
| `assets/` | Bundled fonts, photos and vectors |
| `test/` | Flutter tests and preview fixtures |
| `functions/` | Apps Script backend, server source, utilities and backend tests |
| `config/firebase/` | Database rules, indexes and retained optional Storage rules |
| `scripts/` | Current maintenance utilities and disabled seed guard |
| `docs/` | Architecture, setup, audits, release notes, history and previews |

## Platform projects

`android/`, `ios/`, `web/`, `windows/`, `macos/` and `linux/` are Flutter's
standard platform folders. Their names and locations are part of the build
structure. Android's installed application ID remains unchanged.

## Root configuration

| File | Purpose |
|---|---|
| `README.md` | Project overview and run/build instructions |
| `pubspec.yaml`, `pubspec.lock` | Flutter package manifest and pinned dependencies |
| `analysis_options.yaml` | Dart analysis settings |
| `firebase.json` | Firebase CLI entry point; references `config/firebase/` |
| `.firebaserc` | Firebase project selection |
| `.gitignore` | Generated/private file exclusions |
| `.metadata` | Flutter project metadata |

## Generated and local files

| Location | Purpose |
|---|---|
| `build/` | Generated builds, including `app/outputs/flutter-apk/app-release.apk` |
| `.dart_tool/`, `.flutter-plugins-dependencies` | Flutter/Dart generated state |
| `.firebase/` | Firebase CLI cache |
| `.idea/`, `*.iml` | Android Studio/IntelliJ local project state |
| `.local-backups/` | Private operator configuration, local backups and verification logs |
| `.git/` | Repository history and Git state |

Generated and private files stay at their existing paths and are excluded from
version control where appropriate. Do not put credentials into documentation or
release folders. Keep build artifacts in `build/` and release notes in
`docs/releases/`.

## Organization record

Release 1.0.16 removed verified obsolete source and migration/setup utilities
with user approval. The [removal manifest](../audits/removed-old-work-1.0.16.json)
records exact paths. Current source, assets, configuration and backend files were
verified unchanged by the cleanup; earlier move records below are historical.

The subsequent role-based application layout follows Authentication, Customer,
Farmer, Admin and Common. See the [source tree](../../lib/src/README.md) and
[role move/extraction record](role-file-moves.json). Shared screen logic is kept
once, with role-specific entry files; extracted screen bodies retain their Dart
library scope. Imports in application source and tests were updated together.

On 27 September 2026, the root Firestore rules, indexes and Storage rules were
moved to `config/firebase/`. Their SHA-256 hashes matched before and after the
moves. Firebase paths, emulator references and documentation links were updated.
The original-to-current path map is [file-moves.json](file-moves.json).
No files were deleted and application source behavior was unchanged.
