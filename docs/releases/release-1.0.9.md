# HarvestHub 1.0.9 (build 10)

## Changes

- Customer dashboard assistant visibility is cached and persisted per account on this device. Unknown preferences stay hidden while loading, preventing a dismissed Ola from flashing on return. Existing hide preferences migrate automatically. Profile → App settings → Show Ola assistant can restore the floating mascot; the Assistant tab remains available.
- Admin welcome card has a softer green treatment and a separate date selector, leaving room for long names. Metric values pulse while reports load, respect reduced motion, and replace placeholders when data arrives. Stale report responses are ignored after account/range changes.
- Confirmation now shows a scrollable farm/order/item summary with totals and clear status/home actions. Contact has a compact support introduction. Removed the nonfunctional product-image rotation controls.
- Shared photos now support uploaded image data URIs and asset filenames with extensions, enforce thumbnail dimensions, and fall back safely for malformed data. Basket and confirmation use product photos.
- Farmers can select, preview, undo and save a gallery banner from Edit farm. Images are compressed using the existing free-plan image pipeline. The live farm image remains unchanged until save succeeds. Firestore permits only owner/admin updates, with the existing 140,000-character image limit.
- Splash plant redrawn with symmetrical leaves, fine veins, a centered wheat stalk and an aligned base. The native animated vector has an SVG source at `assets/images/harvest_sprout.svg`.

## Verification

- Flutter analysis: no issues.
- Targeted regression checks cover preference persistence/account isolation, dismissal during preference load, return-navigation visibility, settings restoration, decoded photo rendering/fallback/dimensions, and admin loading transitions.
- Existing role navigation, checkout and responsive detail-screen checks passed, including large text. Screenshot exports now wait for native image decoding.
- Firestore emulator: owner banner save/read passed; other farmer/customer writes, oversized images and ownership changes were denied. Compared production rules before deployment: only the farm image permission and size condition changed.
- Initial verification attempts hit Windows virtual-memory exhaustion. Releasing the idle Gradle daemon resolved it. Test mocks were updated for persisted preferences and asynchronous image decoding before the successful rerun.

## Artifact and deployment

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`; version 1.0.9, version code 10 (APK manifest verified).
- Size: 102,778,580 bytes; minimum SDK 24, target SDK 36.
- SHA-256: `CAE656EAC24803A8C7ABDF107A06E1D729268A51A930CA28C5F336EE6E7F167A`
- Release compilation succeeded. Existing Kotlin/SDK/NDK compatibility warnings remain; tooling versions and signing identity were retained.
- The tested Firestore banner rules were deployed to harvesthub-80047 and read back successfully.
- Installed in place on Infinix X690B after USB reconnection. ADB reported `Success`; phone package readback confirmed version 1.0.9/code 10 and update time 2026-09-27 11:42:12 (local). Existing app data was retained. The first transfer had ended with USB EOF; the completed retry sent the entire APK at 13.0 MB/s.
