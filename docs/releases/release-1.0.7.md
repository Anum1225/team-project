# HarvestHub 1.0.7 (build 8)

## Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`
- Version: 1.0.7; version code: 8 (verified in the APK manifest)
- Size: 102,662,896 bytes
- Minimum SDK: 24; target SDK: 36
- SHA-256: `6E6EE844E56F2A7A83293F661270AA326FE7A133A9C7D6D1DFC66E1B2D2DBBC4`
- Release build completed successfully on 27 September 2026.

Installed in place on the connected Infinix X690B after the USB connection was
restored. ADB push installation reported `Success`; device package readback
confirmed versionName `1.0.7`, versionCode `8`, and lastUpdateTime
`2026-09-27 03:44:46` (local). Existing application identity/signing and app data
were retained.

## Changes

- Floating Ola artwork reduced from 86 × 84 to 72 × 72 logical pixels. It remains on the right of customer Home, with blinking eyes and gentle motion; the label and dismiss control retain their usable space.
- Recolored the mascot in HarvestHub's leaf/forest greens with a warm cream face. Colors adapt to the theme.
- Added a static 36-pixel mascot beside the customer chat title, visible during conversations. The floating control remains exclusive to customer Home; farmer/admin screens have neither mascot.
- Refined admin user, catalog, category and order search fields with a consistent rounded outline, subtle green tint, inset search icon, focus treatment and clear action.
- Increased navigation label side padding and removed extra letter spacing so Dashboard stays inside its selected capsule. The existing dock layout and animation remain.

## Verification

- All 21 existing targeted tests passed after correcting a wrapped mascot-label overflow: role/tab layouts at four viewport sizes, customer flows, assistant stream/retry, large-text/detail screens and preview capture.
- Flutter analysis passed with no issues.
- Customer Home, chat, admin users and admin dashboard previews were visually reviewed; Dashboard fits its highlight. Preview records are fixtures.
- Live backend version 3 is unchanged. The owner-confirmed phone notification receipt from release 1.0.6 remains the delivery evidence; no duplicate test alert was sent.

The build retains the existing Android Kotlin/NDK compatibility warnings and working NDK 27 configuration. Free-service and notification acceptance limits are recorded in [1.0.6](release-1.0.6.md) and the [SRS audit](../audits/srs-audit-2026-09-27.md).
