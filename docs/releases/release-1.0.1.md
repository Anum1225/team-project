# HarvestHub 1.0.1 — build 2

## Build and install

```powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell monkey -p com.example.untitled -c android.intent.category.LAUNCHER 1
```

The Android application ID remains `com.example.untitled` to update the existing installation. The visible application name is **HarvestHub**. This project currently signs local release APKs with the existing debug signing configuration; store publication requires a proper managed signing identity. Do not uninstall or clear data to perform the update.

## Firebase

Project: `harvesthub-80047`. Core data writes use Firebase Auth + Firestore transactions guarded by `firestore.rules`; they do not require the old callable functions in `functions/index.js`.

Firebase AI Logic is provisioned for Android. The app streams from `gemini-3.5-flash-lite` using Firebase-managed authorization. No private Gemini API key should appear in source, build defines, APK assets, or public configuration. The user-supplied key was validated directly with Google but is not required by this architecture.

App Check policy for the sideloaded Android APK remains pending explicit approval; see the audit. Gemini requests require Firebase Authentication. Do not disable enforcement to hide an attestation failure.

### Notifications (source ready, not deployed)

After Blaze is enabled by the project owner:

```powershell
firebase deploy --only functions:notifications --project harvesthub-80047
```

`functions/package.json` now points to `notification-entry.js`. This codebase exports only new-order, order-status, pickup-change and product-stock notification triggers. It does not deploy the legacy callable backend. Restock subscriptions use collection-group indexes from `firestore.indexes.json`.

Enable notifications in Profile → Notifications and allow the Android permission. Test delivery on two real accounts, including while the recipient app is backgrounded. Test sign-out/token revocation and ensure the previous account stops receiving notifications on the shared phone. FCM delivery is best effort; inbox records are durable and trigger retries use stable notification IDs.

### Backups (not configured)

After billing approval, configure daily Firestore backups with seven-day retention, verify a backup appears, then perform a restore drill into a separate database. These backups include admin activity logs stored in Firestore. No schedule currently exists.

## Data structure

| Path | Purpose |
|---|---|
| `users/{uid}` | Profile, role, active flag, contact and avatar |
| `users/{uid}/private/preferences` | Saved product IDs, followed farms, read notices |
| `users/{uid}/pickups/{orderId}` | Published pickup window selected by customer |
| `users/{uid}/devices/{token}` | Opted-in notification device |
| `users/{uid}/notifications/{eventId}` | Server-written notification inbox |
| `farms/{id}` | Owner, location/market, coordinates, pickup windows, active flag |
| `products/{id}` | Catalog, integer minor-unit prices, stock, farm/category and photo |
| `categories/{id}` | Category name and transaction-maintained product count |
| `orders/{id}` | Immutable purchase snapshot and current lifecycle state |
| `checkoutRequests/{uid_requestId}` | Idempotent checkout receipt |
| `farmersMarkets/{id}` | Market name, address, hours, coordinates, active flag |
| `appConfig/public` | Administrator-published About/support content |
| `feedback/{id}` | Protected customer support message |
| `adminActivityLogs/{id}` | Administrator operation log |

## Safe testing

Production is not seeded with sample products or test accounts. Run rule tests against the local emulator using the `demo-harvesthub` project. PreviewStore exists only for injected test/preview scenarios.

```powershell
cd functions
firebase emulators:exec --project demo-harvesthub --only firestore "node --test --test-concurrency=1 test/spark.test.js"
node --test test/domain.test.js
```

See `srs-audit-2026-09-26.md` for verified behavior, limitations and pending infrastructure. Do not describe the release as fully SRS complete until those items are resolved.

## Build verification

Release APK built successfully (77,792,629 bytes). Installed with `adb install -r` on Infinix X690B at 11:06:25 on 26 September 2026. Android reports version 1.0.1, build 2. Existing app data was retained. Analyzer: clean. Flutter regression tests: 30 passed plus the new streamed-chat test; one optional screenshot test skipped. Firestore emulator: seven passed. Domain tests: three passed. Full signed-in device verification remains pending; device disconnected after installation.

Build warnings: current plugins still use Kotlin Gradle Plugin and request NDK 28.2 while the project selects 27.0. The release build succeeded, but toolchain alignment should be addressed before store publishing.
