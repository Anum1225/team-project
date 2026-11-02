# HarvestHub 1.0.13 (build 14)

## Mandatory email verification

- All administrator, customer and farmer password sign-ins require an emailed code. New customer/farmer registrations enter the same verification gate before protected data loads.
- Existing profiles are covered even when the old `email2faEnabled` setting is false or missing. A valid email/security-version-bound custom-token session is required; old enable/disable flags no longer control access.
- Settings show an informational **Always active** panel with no setup or disable button. Backend disable requests and previously issued disable challenges are rejected.
- Codes retain their 30-minute lifetime, resend cooldown, attempt limits, single use, and same-challenge resume behavior. Existing verified sessions remain valid until normal sign-out, expiry/revocation or credential/security-version changes.
- Password/email changes use verified backend operations. Pending email changes must have been recorded through the verified account flow; password-only email changes cannot silently replace the canonical second-step address.
- The public browsing demo remains available and continues to require sign-in before orders.

## Verification

- 21 Apps Script tests passed, including every role with the previous flag true/false/absent and old disable-challenge rejection.
- 18 Auth/Firestore emulator tests passed, covering mandatory proof, new customer/farmer registration, protected data, existing order rules and credential changes.
- 20 Flutter tests passed: mandatory claims, read-only settings panel, code entry/resend and role navigation. Static analysis reported no issues.
- Apps Script version 6 is deployed at the existing endpoint. A disposable production identity completed login without prior enrollment, 30-minute code resume and custom-token verification; replay and disable attempts were rejected. No real user's password or code was required.

## Deployment and Android artifact

- Mandatory Firestore rules were deployed and read back with an exact match. The CLI printed deployment complete and then a post-deployment error; independent readback and live access checks confirmed the release is active.
- The live disposable account's password-only token received HTTP 403 for protected catalog data, while its email-verified token received HTTP 200.
- APK: `build/app/outputs/flutter-apk/app-release.apk`; package `com.example.untitled`, version 1.0.13/code 14; minimum SDK 24, target SDK 36 (manifest verified).
- Size: 102,893,552 bytes. SHA-256: `974A29F7452583E724661DEBDE9C92937013957A4A11AA4C8C179E2B6711AFE0`.
- Release build succeeded in 379.1 seconds; existing Android tooling warnings remain. An idle previous Gradle daemon was stopped after Windows paging exhaustion, and affected tests were rerun successfully before packaging.
- Installed with `adb install --no-streaming -r` on Infinix X690B, preserving app data. An initial USB disconnect required one retry. Device readback confirmed 1.0.13/code 14 at 27 September 2026, 14:47:09.
- Older app versions must be updated to present the mandatory code gate correctly. Mail/Google service quotas and connectivity remain required; no password-only fallback is provided.
