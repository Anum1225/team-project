# HarvestHub 1.0.10 (build 11)

## Email 2FA fixes

- Newly issued email codes expire after 30 minutes. Existing codes retain their original server expiry; request a new code after updating.
- Reopening the verification screen or retrying an initial send response resumes the same valid challenge. It does not send a replacement email, consume another send allowance or restart the expiry clock. An explicit resend replaces the code, and the UI explains that the newest email must be used.
- Login resend is allowed within the 30-minute recent-sign-in window. A still-valid code can be resumed after that window; requesting a new one then requires a fresh password sign-in. Enrollment resend retains its original password-proof deadline.
- The phone displays remaining time using the server timestamp, avoiding incorrect countdowns caused by a phone clock offset.
- Account profile handling waits for an in-flight verification/custom-token exchange. This prevents the enrollment profile change from temporarily opening another code screen while verification is finishing.
- The retained, undeployed callable implementation also uses the 30-minute lifetime and matching email copy.

## Verification and deployment

- Ten Apps Script tests passed: expiry boundaries, screen resume, explicit resend, password-proof deadline, single use, attempts, session/email binding, delivery failures, existing assistant and notification checks.
- Two phone-screen widget tests passed: leading-zero code entry, retry without replacement, server-clock countdown and explicit resend using the new challenge.
- Flutter analysis passed with no issues.
- Apps Script version 4 was deployed to the existing web-app URL. Version 3 remains available for rollback. Existing scopes, permissions, secrets and billing configuration were preserved.
- Live disposable-account checks passed enrollment and password-plus-code login, a 30-minute persisted lifetime, same-challenge resume, token exchange, password-only access rejection and code reuse rejection. The disposable identity and tracked records were removed. This verifies the backend flow; it does not substitute for the user's own phone acceptance.

## Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`; version 1.0.10, code 11 (manifest verified).
- Size: 102,778,580 bytes; minimum SDK 24, target SDK 36.
- SHA-256: `CDE34174C9A13E02086E21A14E171AC28EEC3F205CCAE6342BE77516F0BECE0A`
- Release build succeeded in 236.6 seconds. Existing Android tooling compatibility warnings remain.
- Installation pending: ADB lists no connected phone. The last verified installed version is 1.0.9/code 10. Reconnect with USB debugging enabled and install this APK in place with `-r`.

Subsequent update: these fixes were bundled into [1.0.11](release-1.0.11.md), which was successfully installed on the phone. The APK output path now contains that newer release.
