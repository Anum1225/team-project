# HarvestHub 1.0.14 (build 15)

## Changes

- Customer product cards, product details and saved products use text-only **Add to cart** actions. Quantity increment controls remain functional. Grid spacing accommodates the longer label and enlarged text.
- Administrator notification titles and message text have a small increase in left inset.
- The default HarvestHub Administrator account was updated in place to the requested email and password. Its UID, role and data were preserved; old sessions were invalidated and mandatory email verification remains active. Credentials are not included in source or the APK.
- Password reset uses the submitted email address. The confirmation now retains that exact recipient even if the input is edited while the request is pending. A live request was accepted for the updated administrator email; inbox receipt was not independently checked.

## Verification

- Updated administrator credentials passed a live Firebase sign-in check, and Auth/profile email and administrator role were read back successfully.
- Reset-recipient and narrow-grid regressions passed, including text scaling at 1.6. Detail screens passed at four phone widths with enlarged text at 360 pixels.
- 25 Flutter tests passed across reset recipient, narrow product grids, detail screens, role navigation, checkout and demo access. Final static analysis reported no issues.

## Android delivery

- Release build succeeded in 232.0 seconds. Existing NDK/Kotlin tooling warnings remain.
- APK: `build/app/outputs/flutter-apk/app-release.apk`; package `com.example.untitled`, version 1.0.14/code 15; minimum SDK 24, target SDK 36 (manifest verified).
- Size: 102,893,552 bytes. SHA-256: `DFDABF2EA1E63AD677E0AD1994CBAFB8BBBBEF3FAEB6C3856601050B08303471`.
- Installed successfully on the connected Infinix X690B with `adb install --no-streaming -r`, preserving app data.
