# Email with no new SMTP account

For the newly implemented Apps Script code/push/Gemini backend and its pending
activation steps, see [Apps Script setup](apps-script-backend.md). The default
build described below continues to use Firebase links until activation.

Current build: Firebase Spark's built-in email verification and password reset.
No Cloudflare Worker, new SMTP provider, API key or billing upgrade is required.

In the app, open Profile → Password & Security → Email address verification and
send the verification link. Open the link from the account inbox, then return to
the app and check again. Password recovery remains on the sign-in page.

The app refreshes the email verification state when it resumes. Both send flows
have a resend cooldown and display Firebase quota/network errors honestly.

These links confirm email ownership. They do not implement per-login email 2FA.
The custom-code implementation remains in `functions/src/security/` for a future
trusted deployment, with its setup hidden in the default APK. Existing enabled
accounts still retain their verification gate; this release does not bypass it.

Automatic background push triggers remain undeployed. FCM itself is free, but
automatic sends require an authenticated server. No anonymous/open SMTP relay
is configured, and no privileged email or Firebase credentials are in the APK.

The emulator tests verify link application, single use, password reset and
credential changes. Real inbox delivery and on-device resumption require a
connected phone and the account inbox; they are not claimed from emulator tests.

Official guide: https://firebase.google.com/docs/auth/flutter/manage-users
