# HarvestHub 1.0.3 (4)

## Changes

- Reduced the floating Ola robot and basket sizes while retaining their controls.
- Map selection resolves a readable address through the native geocoder. Geographic
  coordinates remain separate for distance filtering and farm/market persistence.
  Debouncing, stale-result rejection, timeout, retry and manual address entry cover
  failed lookups. Provider availability still depends on the device/network.
- Shared country-aware phone entry defaults to Pakistan and supports 245 regions.
  Signup, account editing and public support contact forms validate numbering
  patterns and save international E.164 numbers. Registration, account persistence
  and checkout also validate. This checks format, not ownership or assignment.
- Product stock accepts bounded nonnegative integers.
- Organized active Flutter code into features, shared widgets/forms and data.
  Preserved the alternative implementation under lib/legacy; grouped backend code,
  tools and documents. See architecture/file-moves.json for the 91 moved files.

## Verification

- Flutter analysis: no issues.
- Flutter regressions: 45 passed; preview capture skipped in the normal suite.
- Separate customer preview capture: passed and five screenshots refreshed.
- Focused map/phone tests: 12 passed, covering country switching, invalid numbers,
  stale responses, provider errors and lookup timeouts.
- Email security emulator suite: three tests passed before the file reorganization,
  including verification-link and password lifecycle checks.
- Backend domain suite: three passed after reorganization; entrypoint resolves.

## Email and cost limits

No paid service, billing upgrade, Cloudflare Worker or new SMTP account was enabled.
Firebase's existing verification-link and password-reset mail needs no new SMTP
account. Verification links are explicitly not login 2FA.

The custom six-digit, single-use code implementation expires after ten minutes,
with resend/attempt limits and server-side session binding. It is not deployed and
cannot send production email without an authorized sender and compatible trusted
backend. Automatic push server handlers also remain undeployed. The default app
does not advertise an operational email-code enrollment flow.

## Android update

Application ID remains com.example.untitled; version is 1.0.3 (4). Installation
must use adb install -r with the existing signing identity to retain app data.
