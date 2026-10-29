# Email verification delivery — setup pending

**Superseded deployment route:** the owner requires zero spending, no Cloudflare
and no new SMTP account. Keep Firebase on Spark and follow `firebase-email.md`. The Cloud Functions/Secret Manager
instructions below describe the previous implementation, which is not deployed;
they must not be used as the activation route under the zero-cost requirement.

Email-code verification is implemented in the customer account flow and exported
from the Functions entry point. Firestore rules enforcing the verified session
were deployed on 26 September 2026. Functions have not been deployed: the project
is still on Spark and SMTP2GO credentials have not been configured. Do not set
email2faEnabled on production profiles manually; enrollment must complete a real
mailbox challenge after deployment.

## Selected SMTP service

SMTP2GO has a free tier limited to 1,000 sends per month and 200 per day
(checked 26 September 2026). Without a verified domain, a 25-per-hour cap also
applies. Individual sender email verification is supported. It requires an
account and a verified sender. Free service does not mean an
anonymous SMTP server or unlimited sends.

- https://support.smtp2go.com/hc/en-gb/articles/223087947-Free-Plan
- https://support.smtp2go.com/hc/en-gb/articles/12747932085145-Quick-Start-Guide

The server-side SMTP adapter uses Nodemailer and required TLS. Resend support
has been removed at the owner's request. No provider password belongs in the
Flutter app, committed files, build arguments or public Firebase configuration.

Secret Manager secret `HARVESTHUB_EMAIL_SENDER` must contain a JSON object with:

| Field | Value |
|---|---|
| provider | smtp |
| host | mail.smtp2go.com |
| port | 2525 |
| secure | false (STARTTLS is required by the adapter) |
| user | SMTP username from Sending > SMTP Users |
| password | SMTP password, not an API key or account password |
| from | HarvestHub <your verified sender address> |

The former `scripts/legacy/configure-email-sender.ps1` was removed during the
approved 1.0.16 cleanup. This section is historical; the live free email service
uses Apps Script as described in `apps-script-backend.md`.

The separate `HARVESTHUB_EMAIL_CODE_SECRET` still needs a cryptographically
random server secret before deployment. Preserve it across routine deployments.

## Remaining activation requirements

- SMTP2GO account and verified sender/SMTP credentials.
- Firebase Blaze for the chosen Cloud Functions backend (SMTP's free quota does
  not make Firebase hosting of Functions available on Spark).
- Deploy the exported email and notification functions after configuring secrets.
- A user-approved test inbox; verify actual receipt, expiry, resend limits and
  single-use codes. No live delivery has been verified.

Existing Firebase password-reset emails do not depend on this SMTP integration.

## Implementation and verification

The server stores an HMAC of each six-digit code, with a ten-minute expiry,
one-minute resend delay, five attempts per code and five sends per hour per user.
Challenges are bound to the account, purpose, authentication time and security
version. Successful verification consumes the challenge and issues a custom
Firebase session token. Enrollment and disabling require password and mailbox
proof; changing an enrolled account's password requires a verified session.

Auth/Firestore emulator tests cover enrollment, resending, incorrect attempts,
expiry, single use, session binding, failed delivery, disabling, rules enforcement
and the native password reset/change lifecycle. These do not establish real
inbox or push delivery.

This is an application email verification step protecting HarvestHub access and
Firestore data. It is not native Firebase Authentication MFA: it does not add an
email factor to Firebase Auth or govern all direct Auth REST operations.

After enabling Blaze, configure both server secrets and deploy using:

```powershell
firebase deploy --only functions --project harvesthub-80047
```

Then verify real code receipt, enrollment, sign-out/sign-in, expired and reused
codes, password reset/change, and push delivery on a physical phone before
reporting the features as live. SMTP credentials and OTPs must never be logged.
