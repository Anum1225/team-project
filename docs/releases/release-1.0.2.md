# HarvestHub 1.0.2 (3) — customer refinement

**Cost constraint update:** the owner requires zero spending. The proposed Blaze
activation below is superseded by `free-backend-plan.md`. Firebase stays on Spark;
the free-host migration has not yet been built into this APK.

## Changes

- Restored the original `lib/src` customer routes using the existing live session.
- Refined customer headings, search fields, two-line product names and empty states.
- Fixed the transparent Explore filter sheet and doubled Orders search border.
- Added the same shared light/dark reveal control to the customer home header.
- Redrew Ola with a smaller tilted vector design, left-side entry animation and
  persistent hide control. Chat remains available through the Assistant tab.
- Connected the header inbox indicator to server-written Firebase notifications;
  added foreground messages and notification-tap routing.
- Added email-code enrollment/sign-in/disable flows, password validation and reset
  cooldown. Backend codes expire, are single use and have attempt/send limits.
- Grouped customer artwork/styles and account security into dedicated folders.

## Verification

- Final `flutter analyze --no-pub`: no issues.
- 27 Flutter tests passed: all role tabs, customer shopping, account boundaries,
  streamed assistant, shared theme and Ola dismissal. Layouts cover 360–430 px
  widths and 1.6 text scaling at 360 px.
- 11 Auth/Firestore emulator tests passed, including rules denying unverified
  and stale email-verification sessions. Email tests also cover enrollment,
  disabling, resend throttling, expiry, wrong codes and failed delivery.
- The three email tests passed again after adding enrolled-account password
  changes, wrong-password rejection and rejection of the previous security version.
- Deployed Firestore rules were read back and contain the email proof/version gate.
- Generated customer previews use fixture data; they are not physical phone tests.
- Release APK built successfully in 204.5 seconds (97.1 MB), with existing
  Android SDK/NDK/Kotlin compatibility warnings. Build output:
  `build/app/outputs/flutter-apk/app-release.apk`.

## Activation and device status

Firebase project `harvesthub-80047` remains on Spark. The email and push Functions
are exported in source but not deployed. SMTP2GO credentials, a verified sender,
the server code secret and Blaze are required; see `email-delivery-setup.md`.
Actual inbox receipt and automatic push delivery have not been verified.

Email verification protects HarvestHub application/Firestore access and is not
native Firebase Auth MFA across all Auth endpoints.

The phone repeatedly disconnected during inspection. Only Home and Explore were
physically inspected on the previous installed version. Final APK installation
and the remaining physical-device checks are pending USB reconnection.

Keep application ID `com.example.untitled` and use `adb install -r` to install an
update while retaining app data. Do not uninstall the existing application.
