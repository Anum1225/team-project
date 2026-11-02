# HarvestHub 1.0.18 (build 19)

## Email two-step verification settings

- Customers, farmers and administrators can enable or disable email two-step verification in Settings. The same controls remain available in Password & security.
- Both changes require the current password and a single-use email code. Cancelling, failed delivery and incorrect codes leave the saved preference unchanged. The switch reads the server profile and is unavailable while loading or confirming a change.
- Successful changes increment the account security version. Re-enabling blocks password-only sessions and older verification proofs; disabling allows subsequent password-only sign-ins. Missing preferences remain protected by default.
- Firestore clients cannot change their security flag directly. The Apps Script backend, optional Cloud Functions implementation, Flutter login gate and Firestore rules honor the same preference.
- Verification emails name the intended enable/disable action. Existing code expiry, resend limits, attempt limits and session/email binding remain in place.

## Validation

- 24 Apps Script tests passed, including enable/disable round trips for every role, cancellation-equivalent pending challenges, wrong codes, replay and stale proofs.
- 18 Auth/Firestore emulator tests passed, including verified enable/disable, direct flag-write rejection and protected data access.
- Six focused Flutter security tests passed. Related email-code, role-access and dashboard tests also passed (one optional screenshot test skipped).
- Flutter static analysis: no issues.
- Existing Apps Script endpoint updated to version 8. Matching Firestore rules deployed successfully after retrying a network failure.
- Live acceptance uses a disposable account and seeded test-only challenges; it sends no email and does not establish new inbox-delivery evidence.
- Live acceptance passed on the deployed backend: disable persisted, a fresh password login accessed protected data while disabled, re-enable persisted, and a fresh password login was blocked afterward. Incorrect passwords/codes and reused codes were rejected. The disposable account and challenge were removed. Earlier attempts encountered connection timeouts and one unexpected response; the complete final run passed.

## Android delivery

- Release APK built successfully in 565.2 seconds; version 1.0.18/code 19 and package com.example.untitled verified. Existing NDK/Kotlin toolchain warnings remain.
- APK signature verified. SHA-256: 9E23BA0DFE0CF65698A8AA48BE8894BDEC384B23D824FC49C95AD6EFC70B5200.
- Installed in place on the connected Infinix X690B, preserving app data. Device readback confirms version 1.0.18/code 19, update time 2026-09-27 20:42:04; app launch succeeded and its process was running.
- Distribution file: build/releases/HarvestHub-1.0.18.apk (103,040,912 bytes).
