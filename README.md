# HarvestHub

Flutter marketplace for customers, farmers and administrators, backed by Firebase.
Android application ID: `com.example.untitled` (preserved for in-place updates).

## Project layout

| Folder | Contents |
|---|---|
| `lib/main.dart`, `lib/src/app.dart` | Firebase bootstrap, session gates and role navigation |
| `lib/src/features/` | Authentication, customer, farmer, admin and common modules; see [source map](lib/src/README.md) |
| `lib/src/features/common/shared/` | Shared widgets, themes, charts and country-aware form fields |
| `lib/src/features/common/data/` | Models, session state and live Firebase persistence |
| `test/fixtures/` | Preview records used only by automated tests |
| `assets/` | Fonts and artwork referenced by Flutter |
| `config/firebase/` | Firestore rules/indexes and retained Storage rules |
| `functions/src/` | Undeployed email-code and notification server implementation |
| `functions/apps-script/` | Live Google account backend for email codes, Gemini and notification sending |
| `functions/tools/` | Administrator and backend verification utilities |
| `test/`, `functions/test/` | Flutter regressions and backend/emulator tests |
| `docs/` | Setup, architecture, releases, audits, history and previews |
| `scripts/` | Current maintenance utilities and disabled production seed guard |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Standard Flutter platform projects |

Flutter manifests and the Firebase CLI entry point remain at the repository root.
`firebase.json` points to the rules and indexes in `config/firebase/`.
Generated caches, build output, local logs and credentials are ignored.
The complete [folder guide](docs/architecture/project-layout.md) explains each
top-level entry. The file-move inventory is in `docs/architecture/file-moves.json`.

## Run and verify

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter run
```

For Auth/Firestore emulator checks, install dependencies in `functions/`, make
Java available, then run from that directory:

```powershell
npm ci
firebase emulators:exec --project demo-harvesthub --only auth,firestore "node --test --test-concurrency=1 test/spark.test.js test/email-security.test.js test/apps-script.test.js"
```

Preview captures are fixture data, not proof of production delivery or device tests.

## Build and update Android

```powershell
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Use `-r` and the same signing identity to retain installed app data.

## Free-service constraint

The owner requires zero spending, no Cloudflare Workers and no new SMTP account.
Firebase remains on Spark. Built-in verification-link and password-reset emails
use the existing Firebase project. They do not require SMTP credentials.

The Apps Script web backend is deployed. The default build includes its public
URL; `HARVEST_BACKEND_URL` can override it. Private Gemini and OTP secrets stay
in server Script Properties. No legacy code/push flags are needed.

Email two-step verification is a custom app gate enforced by Firestore rules
and server checks, not Firebase native MFA. Live enrollment, subsequent login,
one-time code use and rejection of password-only access were verified
with a disposable account. The owner confirmed email receipt.
Administrators, customers and farmers can enable or disable verification in
Settings or Password & security. Both changes require the current password and
an email code; the server saves the choice only after verification. Accounts
without a saved preference require verification by default. Email codes remain
valid for 30 minutes.

The live inbox uses persisted notifications. App changes request prompt server
synchronization and a minute timer provides catch-up. Enable **Profile →
Notifications → Phone notifications** for device delivery. Google/Android
quotas, permission and connectivity apply; intermediate changes between scans
can be coalesced.

Ola uses the live Gemini proxy with products, active farms, markets, categories,
public support information and the signed-in customer's/farmer's own recent
orders. Saved answers appear only after an AI failure and are labelled clearly.
The bag is in the customer header. The compact green Ola mascot floats on the
right of customer Home with gentle motion and blinking eyes. A static mascot
also appears in the customer chat header. Farmer/admin screens have no Ola
mascot. Reduced-motion preferences are respected.
The owner confirmed receipt of the live phone notification test.

Admin Settings → **About & public content** manages the complete About page,
including its image, sections and footer. Existing content is prefilled; preview
the draft before publishing. Public pages receive changes through Firestore.

See [Apps Script setup](docs/setup/apps-script-backend.md) for activation and
quota limits, [the full 115-item audit](docs/audits/srs-audit-2026-09-27.md) for
remaining SRS gaps, and [release 1.0.17](docs/releases/release-1.0.17.md) for this
change set. Rules and indexes for following, read receipts and verified email
synchronization were deployed and read back successfully.

Customer Profile → **App settings** controls the floating Ola assistant. Closing
it on Home persists on this device without a flash when returning. Farmers can
change their banner through **Edit farm**; uploads use the existing compressed
image storage on the free plan. Admin totals show animated loading placeholders,
and basket/confirmation photos share the same image renderer.

**Explore demo mode** is below the login form. It opens the customer interface
with the published production catalog, search, product/farm details, markets,
session-local favourites/following. Add to cart prompts for sign-in or
registration; visitors cannot add items to a basket until they sign in.
Demo cannot create orders. Account records require sign-in; demo assistant replies
use labelled catalog guidance and saved tips. Live Gemini remains authenticated.
