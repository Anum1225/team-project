# Zero-cost backend requirement

**Rejected proposal:** the owner subsequently rejected Cloudflare Workers and
new SMTP accounts. The proposal below is retained as history only. The current
build uses Firebase's own verification/reset emails; see `firebase-email.md`.

The owner requires zero spending. Firebase must remain on Spark. Do not enable
Blaze, paid Workers, trials requiring billing, email overages or paid upgrades.
This supersedes the activation instructions in release-1.0.2.md and the former
Cloud Functions email setup. Existing Cloud Functions have not been deployed.

## Selected free deployment route

| Service | Purpose | Free allowance checked 26 September 2026 |
|---|---|---|
| Firebase Spark | Existing authentication and Firestore data | Existing Spark quotas; no billing account |
| Firebase Cloud Messaging | Push transport to Android | No cost |
| Cloudflare Workers Free | Proposed host for email-code and notification server logic | 100,000 requests/day, 10 ms CPU/invocation; no credit card required |
| SMTP2GO Free | Verification email delivery via HTTPS API | 1,000/month, 200/day; 25/hour without a verified domain |

SMTP2GO accepts individual verified senders, so buying a domain is not required.
It stops sending when the monthly free quota is reached. Workers Free rejects
requests above its daily quota. Remain on free plans when limits are reached;
show temporary unavailability in the app instead of upgrading.

## Required implementation changes

The current APK calls Firebase callable Functions. Choosing a free hosting
provider does not activate those endpoints. Port the email endpoints to Workers,
preserving authentication, password proof, HMAC codes, transactional attempt/send
limits and session version checks. Keep all provider and service-account secrets
on the server, never in the APK. Prefer SMTP2GO HTTPS API in the Worker.

Cloudflare cannot directly receive the current Firestore Functions triggers.
Notification delivery therefore needs a replacement that verifies persisted
events and prevents duplicate sends. A bounded scheduled poll may be used, with
query cursors and a strict Firestore read budget; document its delivery delay.
Do not scan the full database on every tick. Validate the implementation against
Workers' CPU/request limits before claiming compatibility or deploying it.

Update the Flutter transport and repeat security tests before building the next
APK. Existing Firebase password reset/change can continue on Spark independently.

## Account prerequisites and present status

Free Cloudflare account access and an SMTP2GO account with a verified sender are
required. Neither account's availability has been confirmed. No Worker has been
deployed and the current APK has not been migrated to the free host yet.

## Official references

- https://firebase.google.com/pricing
- https://www.cloudflare.com/products/workers/
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/workers/platform/limits/
- https://support.smtp2go.com/hc/en-gb/articles/223087947-Free-Plan
- https://developers.smtp2go.com/docs/send-an-email
