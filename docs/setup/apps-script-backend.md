# Apps Script backend activation

Status on 27 September 2026: **live, version 8**. [Web app](https://script.google.com/macros/s/AKfycbzrVxOkY9A-HQHLRCSSUdPxepUHUp-yy4H619oIe-gWZaGNXWoBxfRTvvq2L57gVi2I/exec). The default Flutter URL is configured. Owner runtime consent and IAM Credentials API activation are complete. The owner separately approved the custom `harvestHubJwtSigner` role containing only `iam.serviceAccounts.signJwt`, bound only to the existing Firebase signing service account. No service-account key was created and billing remains disabled.

Existing project: [HarvestHub trusted backend](https://script.google.com/home/projects/1Z0CMeRl30BAQ9Omb2q_69n9SuGSEZHETHGcQ6vxa3teggc0Ek3jt7EC0/edit). `verifySetup` passed Firestore, token signing, email quota and Gemini configuration checks. Stock baseline initialization completed for five products and the notification timer was installed. Live health/authentication, email-code login, signed-token exchange, code reuse rejection, Gemini context and notification synchronization passed. Version 8 supports verified enable/disable changes in Settings. Owner confirmed receipt of the verification email. FCM dry-run validation and a real send succeeded. After enabling notifications, the owner confirmed receiving “HarvestHub is connected” on the phone; the same notice was persisted in the inbox. Individual order/pickup/restock events and the complete Android lifecycle matrix remain separate acceptance checks.

## Services and boundaries

The existing Google account hosts the web app and sends verification emails through MailApp. Firebase remains on Spark. No SMTP account, Cloudflare service, service-account private key or billing upgrade is needed by this design. The backend can access project data as its owner, so account actions verify a Firebase ID token and check the active user/profile and applicable email proof. The sole public data action, `publicCatalog`, returns fixed allowlisted fields from published products, active farms, categories and active markets, using bounded pages. It cannot write data or select private collections.

The source is functions/apps-script/Code.js and appsscript.json. Flutter calls lib/src/features/common/data/trusted_backend.dart. The supplied Gemini API key is stored in server Script Properties and ignored local operator configuration. Never put it in a dart-define, Flutter source, APK, committed configuration, deployment version source or log. Owner Google API calls explicitly set `x-goog-user-project: harvesthub-80047`; otherwise Google's default Apps Script project causes an IAM `SERVICE_DISABLED` error.

Administrators, customers and farmers can enable or disable email second-step verification in Settings. Both changes require the current password and a valid email code; only the trusted backend can save the preference. Missing settings default to enabled. This is a custom app gate enforced in Firestore rules, not Firebase native MFA. Password-only sessions may read their own profile so the gate can render; when verification is enabled, protected app data and privileged backend operations require the version/email-bound custom-token claims. Disabled accounts can sign in with their password. Code hashes expire after thirty minutes, allow five attempts, have one-minute resend cooldown and five sends/user/hour. The server chooses the canonical account email; callers cannot supply a recipient. Reopening the code screen resumes the same valid challenge. Only explicit resend rotates it; resuming keeps the original expiry and does not send another email. Responses include server time for the phone countdown.

## Recovery / redeployment checklist

1. IAM Credentials API and Apps Script API are already enabled. Preserve the approved narrow signer grant; do not broaden it or enable billing.
2. Source and manifest have been pushed with the existing logged-in official clasp CLI and functions/apps-script/.clasp.json. Push again only after source changes; do not create a duplicate project or repeat OAuth login unnecessarily.
3. The script is named HarvestHub trusted backend and these four properties have already been saved. For recovery, use Project Settings → Script properties and the ignored local operator configuration:
   - FIREBASE_WEB_API_KEY: Firebase's public project web API key.
   - GEMINI_API_KEY: the owner-supplied private Gemini key.
   - OTP_SECRET: the already-generated random HMAC secret. Keep it stable; rotating it invalidates outstanding codes.
   - SIGNER_SERVICE_ACCOUNT: the existing firebase-adminsdk account identified in this project.
   - GEMINI_MODEL: optional; defaults to gemini-3.5-flash-lite, whose availability and real generation were checked.
4. Run verifySetup as the owner. The script will request external-request, send-mail, cloud-platform and trigger-management scopes. Obtain confirmation for any new security-sensitive grant at the actual consent screen. verifySetup reads Firestore, signs an unused setup token without creating an Auth account and logs only nonsecret status/quota booleans.
5. If signing returns permission denied, inspect the exact IAM error. Any required signJwt permission must be scoped to the existing signing service account and separately authorized; never grant a blanket new owner role or generate a downloadable service-account key.
6. Run initializeNotificationState until it reports complete. It processes up to 80 existing products per invocation and establishes their stock baseline without generating fabricated restock notifications.
7. Run installNotificationTrigger once. It installs a single approximately one-minute catch-up job and avoids creating duplicates.
8. Deploy a versioned web app, executing as the owner and accepting unauthenticated HTTP transport. Each account action independently requires and validates the caller's Firebase ID token. The publicCatalog action is read-only and restricted to public catalog fields. Record the returned /exec URL. Keep access to the script project itself private.
9. Verify the /exec health response and that an absent/invalid token returns an application authentication error. Exercise the signed-in email-code, Gemini and notification paths with dedicated test accounts.
10. The verified /exec URL is now the Flutter default. Use HARVEST_BACKEND_URL only to override it for another deployment. Record deployment version/URL and test results in the release document.
11. Verify incoming messages on a connected Android phone before calling push/email delivery operational. Update the release documentation and default distribution configuration only after these checks pass.

The source manifest disables exception logging of automatic error details. Endpoint errors return controlled messages; passwords, ID tokens, OTPs and upstream replies are not logged. verifySetup logs only booleans and the remaining email allowance.

## Notification behavior

Firestore listeners provide the live inbox and unread state. Read receipts persist per notification. The server derives recipients from authoritative orders, farms and saved/followed preferences; clients cannot create notices or edit notice text.

The app asks for synchronization shortly after successful order, stock and pickup writes. The timer provides retry/catch-up when that request is missed. Source queries use bounded pages and time/document cursors. Notification IDs deduplicate each observed update; permanent invalid FCM tokens are removed.

This is snapshot polling, not an exhaustive event log. Intermediate changes between scans can be coalesced, including a rapid 0 → positive → 0 stock cycle. For a guarantee on every transition, add a rule-validated transactional event outbox before claiming that guarantee. Closed-app push also depends on Android permissions, connectivity and device delivery policies. A new token does not replay already-completed sends; historical updates remain visible in the inbox.

Current bounds: 80 documents per source scan, 30 registered devices per recipient query, 1,000 matching preferences for each saved/followed restock query, latest 100 inbox notices in the app. Larger deployments require pagination/fanout expansion and monitoring.

## Zero-cost limits

Consumer Google accounts currently have 100 email recipients/day, shared across that account's Apps Script use. Sender checks the remaining quota before creating a send and rejects when exhausted. Apps Script runtime/URL-fetch limits, Firestore Spark reads/writes and Gemini provider quotas also apply. Per-user limits are not a guarantee that a large deployment fits the shared daily quotas. No automatic paid upgrade is implemented.

Gemini receives up to 16 messages, 200 products, 200 active farms, 200 published market records, 100 categories, public support information, a validated basket and up to 20 of the caller's own recent orders. Private user profiles, addresses, email codes, credentials and other customers' identities are excluded. Results identify truncated catalog context. A real request through the deployed proxy returned the actual farm names, stocks and correctly converted rupee prices. AI failures invoke labelled local saved tips; those tips are excluded from later model history and replaced on a successful retry.

`verifyPushDelivery` is an owner-run diagnostic, absent from public request actions. It reads an expiring, server-only `backendChecks/pushDelivery` request prepared for an explicitly selected app account and writes one durable test notice through the same FCM sender. It requires a registered device. The smoke utility never logs codes, passwords, ID tokens or device tokens. Automated OTP verification derives a code only for its tracked disposable test identity; actual inbox receipt was confirmed separately by the owner.

## Validation before activation

- Enable/disable for every role, password and email-code validation, wrong/expired/reused code, resend cooldown and stale email/version/session proof.
- An attacker with only a password cannot replace the canonical second-step email or access protected app collections.
- Current-password reauthentication, changed-email verification link, profile synchronization and next login.
- Customer order → farmer notice; farmer status → customer notice; pickup modification/cancellation → farmer notice.
- Stock baseline, low stock and wishlisted/followed restock deduplication.
- Opt-in/out, foreground/background/terminated Android receipt, tapped target, logout/account switching and invalid-token cleanup.
- All five SRS example assistant questions; invalid token, provider rate limit and transient outage.
- Keep dedicated test identity credentials private. The owner's Google login is not an app demo account.

## Rollback and operations

Retain the last working Apps Script deployment version so it can be restored. Do not simply disable the endpoint after enrolling production email-code users: they would be unable to complete sign-in. Keep recovery under an authenticated project-owner procedure, never a client-accessible switch. Before changing signing secrets or deployment permissions, record affected users and active challenges privately.

Rules/indexes have already been deployed separately and verified; there is no Cloud Functions deployment. Historical SMTP/Workers guides describe rejected alternatives and are not the current plan.

## Official references

- [Apps Script web apps](https://developers.google.com/apps-script/guides/web)
- [Apps Script quotas](https://developers.google.com/apps-script/guides/services/quotas)
- [Firebase custom tokens](https://firebase.google.com/docs/auth/admin/create-custom-tokens)
- [Firebase user management](https://firebase.google.com/docs/auth/flutter/manage-users)
- [Gemini API keys](https://ai.google.dev/gemini-api/docs/api-key)
- [Google quota-project header](https://docs.cloud.google.com/docs/quotas/set-quota-project)

