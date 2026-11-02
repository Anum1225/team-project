# HarvestHub 1.0.5 (build 6)

Follow-up: superseded by [1.0.6 (build 7)](release-1.0.6.md). The owner subsequently
enabled phone notifications and confirmed receipt of the live test alert. The
pending-delivery statements below describe the original 1.0.5 release checkpoint.

## Installed Android artifact

Built and installed in place on the owner's connected Infinix X690B on 27 September 2026. ADB reported Success; package readback confirms versionName 1.0.5 and versionCode 6. Existing application identity/signing were retained, with no app-data clearing.

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`
- Size: 102,679,280 bytes
- Minimum SDK: 24; target SDK: 36
- SHA-256: `B7A0A5FF9B3D992594FE3AE199330BBDF523B8BAF072D89BBF63DD871DA5903C`
- Device package update time: 2026-09-27 01:40:56 (local)

## Changes

- Live Apps Script backend, deployment version 3. Its public URL is the Flutter default; private Gemini/OTP secrets remain on the server.
- IAM Credentials API and runtime consent completed. Owner-approved role permits only JWT signing on the existing Firebase signer, with no downloaded service-account key. API requests use HarvestHub's quota project; billing remains disabled.
- Free email two-step verification supports enrollment, login and disabling with short-lived, one-time codes. This is an application gate enforced by rules/server checks, not native Firebase MFA.
- Notification stock baseline initialized and a minute catch-up trigger installed. App changes request earlier synchronization. Inbox contents/read receipts are stored in Firestore; phone push is opt-in.
- Gemini receives current products, active farms, markets, categories, public support information, a validated basket and the caller's own recent orders. Private profile fields and other users' identities are excluded. Context bounds and stock snapshots are explicit.
- Saved answers restored for AI outages, visibly labelled and excluded from future AI history. Retry replaces the fallback with the successful answer.
- Customer bag moved into the header; purple vector Ola mascot based on the supplied reference now floats on the right. Large accessibility text no longer overflows its container.

## Verification

- Health response and invalid Firebase-token rejection passed on the deployed endpoint.
- Live disposable-account enrollment, subsequent login, disable, one-time code reuse rejection and custom-token exchange passed. Password-only access was rejected while email verification was enabled. Owner confirmed actual email receipt; automated code verification used a white-box fixture and does not itself prove inbox delivery. Test accounts/records were removed afterward.
- Live Gemini catalog question returned actual farm/products, stocks and correct rupee prices. All five starter prompts answered through the proxy. Seasonal/storage review led to prompt corrections; targeted rechecks returned a location question and safe cut-tomato refrigeration guidance.
- FCM validation accepted; live notification synchronization returned success. Scheduled runs from 01:22 through 01:44 were observed completing successfully, typically in 2–3 seconds. Receiving-phone test is pending the owner's in-app opt-in; the selected account currently has no registered device.
- Six Apps Script regression tests passed, covering code boundaries, proof validation, context privacy and notification deduplication.
- Flutter regression run passed 54 checks, with two intentional skips and one large-text failure. The overflow was fixed and that exact failing test passed afterward. Assistant stream/retry and saved-answer checks passed. Explicitly disabled-backend checks also passed.
- Final Flutter analysis passed with no issues, including the accessibility correction compiled into the installed APK.
- Customer layout preview was visually reviewed. Test previews use fixtures, not production data.

## Remaining limits

Free Google email, Gemini, Apps Script and Firebase quotas apply. Consumer email allowance was 100 recipients/day at setup. Phone push depends on opt-in, Android delivery policies and connectivity. Polling can coalesce rapid intermediate changes; an event outbox is needed for an exhaustive notification guarantee. Remaining unrelated SRS gaps are tracked in the audit.

Android tooling retains existing Kotlin/SDK/NDK compatibility warnings. The attempted newer NDK package was unavailable; the release was built successfully with the previously working NDK 27 installation. No dependency migration or billing upgrade was performed.
