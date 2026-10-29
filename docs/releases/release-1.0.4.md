# HarvestHub 1.0.4 (build 5)

## Included

- Farmer hearts and Follow/Following buttons share persisted state across farm detail, directory and product detail. Updates are atomic, role permissions include farmers, and failures roll back.
- Product creation starts with no selected sample photo. Product details show the real uploaded photo; unrelated sample gallery images and the fabricated notification message were removed.
- Market directory also includes actual active farms' market names, deduplicates published records and respects unpublished markets.
- Place-name resolution uses native geocoding with OpenStreetMap fallback, debouncing, cache, stale-request rejection and editable address text. Obsolete queued pin lookups are discarded.
- Account email-change form with current-password reauthentication and Firebase verification of the new address. Existing password changes/reset links remain available.
- Server implementation for free email codes, secure Gemini requests, durable notification inbox and FCM sending. Its source and private Script Properties are uploaded to the existing Google account.
- Firestore rules/indexes deployed and read back for farmer preferences, notification read receipts and verified-email synchronization.
- Full 115-item SRS audit in docs/audits/srs-audit-2026-09-27.md.

## Activation status

The web app has **not** been deployed. HARVEST_BACKEND_URL is empty in the default build. Thus custom email-code enrollment, new server Gemini transport and automatic phone push are not active in this APK. Native Firebase verification/reset/email-change links, the Firebase AI Logic path and real-time Firestore order activity remain the default paths.

Apps Script API is On, CLI deployment consent is complete, source upload succeeded and four Script Properties were saved. IAM Credentials API remains disabled pending explicit approval following automatic review rejection. Runtime owner consent is pending because Google's authorization popup did not open in the in-app browser. No billing upgrade was made. See docs/setup/apps-script-backend.md for the exact remaining steps.

## Verification

- Full Flutter suite before final UI additions: 51 passed, one optional capture skipped.
- Subsequent targeted follow/photo/map suite: 14 passed, including product-details Follow and remote geocoder fallback/obsolete queue handling.
- Final Flutter analysis: no issues.
- Auth/Firestore emulator suite: 19 passed.
- Production rule/index deployment: successful; remote readback confirmed relevant rules.
- Supplied Gemini key: model listing, smoke generation and all five SRS sample prompt requests returned HTTP 200. These direct checks do not certify the undeployed app proxy or medical/nutritional accuracy.
- ADB: no connected Android device; no new on-device installation, push receipt or live email-code delivery claimed.

## Android artifact

Release build succeeded. Artifact: build/app/outputs/flutter-apk/app-release.apk,
102,908,656 bytes (98.1 MiB), generated 27 September 2026 at 00:47 local time.
Package identity remains com.example.untitled for compatible in-place updates.
APK manifest verified: versionName 1.0.4, versionCode 5, minimum SDK 24, target
SDK 36. SHA-256: 2CD934AAE83CAE8763D15AD13A597E1B15BA9323E707633E35E045CFB9623FB8.
This build includes the completed app fixes and leaves the undeployed backend
disabled. No phone was attached, so installation and real-device acceptance are
still pending.

## Known limits

Free email quota is shared with the Google account's other scripts. Notification polling may coalesce intermediate transitions; timer catch-up is approximately one minute, while app mutations request earlier sync. Pickup windows have no dated capacity reservation. Cart is memory-only. Checkout supports up to three distinct products with one order per product. Search uses loaded catalog pages.

The build reports existing Kotlin/Android SDK/NDK compatibility warnings. A successful APK build is not evidence of future Flutter compatibility; preserve the verified toolchain until a separate dependency migration is tested.
