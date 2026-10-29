# Project file review and responsive audit

**Subsequent update:** The user approved obsolete-source removal after this
read-only audit. Release 1.0.16 applies the targeted cleanup; see the
[exact removal manifest](removed-old-work-1.0.16.json). The observations below
describe the project before that cleanup.

## APK identity

The supplied `C:/Users/pc/Downloads/base.apk` is HarvestHub 1.0.15, build 16,
package `com.example.untitled`. Its SHA-256 is
`2897e9e0750b1638bcd4d07cd41e1a3611990258a21b405bc97d69ac75b1250b`, an exact match
to the project's verified 1.0.15 artifact. It contains 52 bundled asset files.
An APK does not contain the complete development project; source, tests, backend
tools and platform configuration can be necessary even when absent from the APK.

## Extra/archive candidates — nothing deleted

| Path | Finding | Recommendation for later review |
|---|---|---|
| `lib/legacy/hashir_work/` | Historical alternative app; not reachable from `lib/main.dart` | Archive candidate once its history is no longer needed |
| `lib/generated/assets.dart` | Generated asset constants not imported by the active app | Can be regenerated; review IDE generator use first |
| `lib/src/features/authentication/two_step_verification/firebase_email_verification.dart` | Older verification-link helper not reached by the current app | Review before archiving; current sign-in uses mandatory email codes |
| `functions/legacy/` | Retained earlier backend implementation | Keep as history until explicitly approved for removal |
| `scripts/legacy/` | Previous SMTP setup, outside the active free Apps Script flow | Archive candidate |
| `scripts/maintenance/organize_project.py`, `organize_role_modules.py` | Completed migration utilities | Useful move history; not runtime files |
| `build/` | Generated build outputs, approximately 2,665 MiB at inspection | Regenerable cache/artifacts; contains the release APK |
| `.dart_tool/` | Flutter generated state, approximately 1,182 MiB | Regenerable; removal requires a fresh dependency/build setup |
| `.firebase/` | Firebase generated cache, approximately 181 MiB | Regenerable; not app source |
| `functions/node_modules/` | Installed backend dependencies | Regenerable with the lockfile; needed locally for backend tooling/tests |
| `firebase-debug.log`, `firestore-debug.log`, `hs_err_pid8892.log`, `replay_pid8892.log` | Debug/emulator/JVM crash logs | Review/cleanup candidates |
| `.idea/`, `untitled.iml` | Local editor settings | Optional for runtime, useful for the current IDE |

## Keep / do not classify as redundant

- `.git/`: project history, not disposable build output.
- `.local-backups/`: private recovery records and local operator configuration. Do
  not publish or delete blindly; the inventory records only its size, not contents.
- `assets/`: bundled images/fonts and platform artwork. Dynamic image resolution
  means a filename need not appear literally at every call site.
- `lib/src/features/` role export files: intentional entry points into shared
  implementations. They are not duplicate copies of application screens.
- `functions/apps-script/`, `functions/src/`, `functions/tools/`, backend tests:
  live server source, retained server alternative, operator utilities and tests.
  The undeployed alternative is separate from the live Apps Script backend.
- `test/`, `docs/`, `config/`, manifests and lockfiles: development/verification
  materials and required configuration, not APK payload.
- `ios/`, `web/`, `windows/`, `macos/`, `linux/`: other platform targets. Optional
  for an Android-only deliverable, but remove only after that scope is confirmed.
- `android/`, `pubspec.yaml`, `pubspec.lock`, Flutter/Firebase root configuration:
  required project/build setup.

The [machine-readable inventory](project-file-inventory-2026-09-27.json) records
sizes and static import reachability. Static unreachability alone is not proof
that a file should be deleted. No files or folders were deleted during this review.

## Product photos

Existing bundled photographs are mapped to matching product names and historical
image aliases. Valid explicit images and uploads take priority. The fallback is
display-only for product, wishlist, cart, inventory and order cards; it does not
restore old products or change stored product fields. Unknown/mixed products are
not assigned an arbitrary photograph. New-product forms still start with no
selected photo.

## Responsiveness

### Fixes

- Notifications: centered empty/error text with 24-pixel side padding and a
  readable maximum line width; scrollable heading/settings on short screens;
  padded inbox cards and a bounded content width on tablets/desktop.
- Product grids: card height accounts for available image width and text scaling,
  fixing the 320-pixel Explore overflow while retaining readable button labels.
- Farmer dashboard: the harvest heading wraps within its available row width at
  larger accessibility text sizes.
- Reports: an empty response now shows an empty state instead of attempting to
  cast absent numeric fields and crashing.

### Evidence

- 33 detail screens/states checked at 320×640, 360×800, 393×873, 393×852,
  430×932, 800×360 landscape, 768×1024 tablet and 1280×800 desktop. The
  360×800 case also runs at 1.6× text, giving 297 detail-screen combinations.
- Customer, farmer and administrator navigation checked at all eight viewport
  sizes, with 1.6× text at 360 pixels.
- Notifications checked separately for all three roles at 320 pixels and 2× text;
  assertions verify both side margins and centered text.
- Login, password recovery, checkout, profile, product, farm and contact forms
  checked with a 300-pixel simulated phone keyboard inset and scrolling.
- 51 distinct targeted Flutter tests passed across responsive screens, navigation,
  images, notification alignment, keyboard layout and existing UI regressions;
  the optional splash image capture remained skipped.
- Final `flutter analyze --no-pub` completed with no issues.
- Existing asset files were verified for every image mapping. Remote/uploads,
  custom paths, unknown/mixed products and unchanged stored fields are covered.
- Generated [Notifications preview](../previews/notifications.png) and
  [farm product cards preview](../previews/farm.png) were visually inspected.
  Previews use test fixture content, not private live account data.

These are Flutter layout and interaction checks. Real device keyboard variants,
native permission dialogs, camera/gallery screens and network/map-provider
behavior are not proven by these tests. The attached APK remains the supplied
1.0.15 binary; source fixes require a new build to appear in that installed app.
