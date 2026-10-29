# HarvestHub 1.0.16 (build 17)

## Approved old-work cleanup

- Removed 52 verified obsolete files: the alternative legacy Flutter app, retired callable backend and its two old test files, old SMTP setup, two completed migration scripts, unused generated asset constants, the old verification-link panel, and four debug/crash logs.
- Kept active app modules, asset images/fonts, role entry files, Firebase rules/configuration, live Apps Script backend, current server source/tests/tools, platform build files, dependencies and Git history.
- Verified hashes of 210 retained application/backend/configuration/asset files before and immediately after cleanup. All matched.
- A private ZIP backup was verified before removal. The public [removal manifest](../audits/removed-old-work-1.0.16.json) records exact paths and hashes; it contains no file contents or credentials.

## Included app fixes

- Product/inventory/wishlist/cart/order cards display matching bundled asset photos when their image is missing or a known placeholder. Uploaded and explicit images keep priority; stored product data and new-product image selection are unchanged.
- Notifications have padded, centered empty/error messages and a scrollable header for short screens.
- Product grids fit narrow screens and enlarged text; the farmer dashboard heading wraps correctly.
- Reports show a proper empty state when no report data is returned.
- [Responsive audit and preview evidence](../audits/project-files-and-responsiveness-2026-09-27.md).

## Verification and delivery

- Post-cleanup full Flutter suite: 100 passed, 3 optional/environment-dependent tests skipped.
- Apps Script source suite: 21 passed, 0 failed.
- Final static analysis: no issues.
- Release APK build succeeded in 287.5 seconds. Existing Android NDK/Kotlin tooling warnings remain.
- APK: `build/app/outputs/flutter-apk/app-release.apk`; verified package `com.example.untitled`, version 1.0.16/code 17, minimum SDK 24, target SDK 36; launcher `com.example.untitled.MainActivity`.
- Size: 103,024,624 bytes. SHA-256: `DD2BFA462F10D6892D70A868116D93BEA43AD2103A73878D83CAEE69C3F4E582`.
- APK signatures verified successfully; signing certificate matches the supplied 1.0.15 `base.apk`, allowing an in-place update with retained app data.
- Installed successfully as an in-place update on the connected Infinix X690B. Device readback confirmed version 1.0.16/code 17 and last update time 2026-09-27 17:19:42; no uninstall or data clear was performed.
- Launched successfully after a transient USB reconnection. Android reported `com.example.untitled/.MainActivity` as `RESUMED`, with its app process running (PID 1789). This verifies installation and foreground launch, not a complete on-device interaction test.
