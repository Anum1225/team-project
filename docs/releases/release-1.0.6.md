# HarvestHub 1.0.6 (build 7)

## Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`
- Version: 1.0.6; version code: 7 (verified in the APK manifest)
- Size: 102,662,896 bytes
- Minimum SDK: 24; target SDK: 36
- SHA-256: `1AF32F0E535437DAAC962F2171D5195C51EB57625C8F243AE1CCAB3E2955E982`
- Release build completed successfully on 27 September 2026.

Installed in place on the connected Infinix X690B after the owner reconnected the
USB cable. ADB reported `Success`; device package readback confirms versionName
`1.0.6`, versionCode `7`, and lastUpdateTime `2026-09-27 02:07:36` (local).
Existing application identity/signing were retained and no app data was cleared.

## Changes

- Ola appears only on customer Home. Removed the shared-shell mascot from farmer/admin pages and the additional mascot from the customer assistant introduction.
- Artwork is smaller (86 × 84 logical pixels, previously 108 × 104), placed on the right above the navigation bar. The bag remains in the customer header.
- Purple vector artwork has shaded, highlighted eyes, smooth blinks, gentle floating/rocking motion and a soft shadow. Animation stops for reduced-motion preferences and inactive ticker subtrees; timers/controllers are cleaned up on disposal.
- The customer assistant retains live Gemini context, labelled saved answers when the provider fails, and retry behavior.

## Verification

- All 21 targeted Flutter tests passed: customer/farmer/admin tabs at four viewport sizes, right-side placement and compact width, assistant stream/retry, detail/large-text layouts and fixture preview capture.
- Final Flutter analysis: no issues found.
- Customer Home and farmer dashboard previews were visually reviewed. Previews contain fixture data.
- The opted-in phone account had one registered device. The live owner diagnostic persisted and sent “HarvestHub is connected” through the existing notification sender. Server readback confirmed completion and sent state; the owner explicitly confirmed receiving the alert on the phone.
- Backend remains on the already-live Apps Script deployment version 3; no server redeployment or new permission grant was required for this update.

## Remaining limits

The live test confirms delivery to the selected phone account. Individual order, pickup and restock events and all foreground/background/terminated/account-switching cases have not been accepted as a complete matrix. Existing free-service quotas, snapshot-polling limits and Android delivery policies still apply; see the [backend guide](../setup/apps-script-backend.md) and [SRS audit](../audits/srs-audit-2026-09-27.md).

The Android build retains existing Kotlin/NDK compatibility warnings; it uses the previously working NDK 27 installation. No dependency or signing migration was made.
