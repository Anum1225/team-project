# Free email with the existing Google account

Update, 27 September: the Apps Script backend has now been implemented and
locally tested and uploaded. CLI deployment consent and Apps Script API enablement
are complete; activation awaits IAM API approval and runtime owner consent. See
[current activation instructions](apps-script-backend.md).
The feasibility research below records the earlier state.

Status: researched on 26 September 2026; not implemented or deployed. The owner
rejected Cloudflare Workers and creating a new SMTP account. No Cloudflare
deployment or paid service was created. The discarded Worker draft has been
removed; the existing Firebase security source remains intact.

## Available immediately through Firebase Spark

Firebase Authentication can send its own account email-verification and password
reset links. These do not need an SMTP account or an external server. An email
verification link confirms ownership of the email address; it is not a second
factor required for each sign-in. The app must label that difference accurately.

## Apps Script feasibility

Google Apps Script `MailApp` could send custom messages from the existing Google
account after that account authorizes the script. It uses Google authorization,
not Gmail SMTP or an app password. A consumer account currently has a quota of
100 email recipients per day. Quota exhaustion stops execution; no paid upgrade
is required. `getRemainingDailyQuota()` can be checked before accepting a send.

A deployed Apps Script web app can run as its owner. This means it could host a
small authenticated email-code endpoint, but deployment and an OAuth consent
grant by the Google account owner are still required. An existing Firebase CLI
login is not proof that Apps Script has this authorization. No account access or
deployment authorization has been established for Apps Script in this session.

This is therefore a possible future backend, not an activated replacement. A
secure implementation would still need all of the following:

- Validate Firebase ID tokens against the configured project before accepting a
  request. Derive the recipient from the validated account, never from an
  arbitrary client-supplied email address.
- Keep signing credentials and the OTP HMAC secret on the server. Store only
  hashed, expiring codes, with transactional attempt and resend limits.
- Preserve the existing challenge binding to user, session, purpose, email and
  security version, and consume a code atomically before minting a session.
- Authorize server access to Firestore and Firebase custom-token signing without
  putting Google access tokens or private keys into the mobile app.
- Handle Apps Script's response redirects in the native HTTP client, and test
  delivery, replay rejection, disabled accounts and service quotas end to end.
- Independently implement bounded notification polling if automatic push is
  wanted. Email sending alone does not replace Firestore event triggers.

Consumer limits also include 20,000 URL Fetch calls per day, six minutes per
execution, and 90 minutes of total trigger runtime per day. These are shared
quotas and can change. Polling cannot promise immediate delivery or observation
of every intermediate database update.

## Official references

- [Apps Script quotas](https://developers.google.com/apps-script/guides/services/quotas)
- [MailApp API and authorization](https://developers.google.com/apps-script/reference/mail/mail-app)
- [Apps Script web app deployment and execution identity](https://developers.google.com/apps-script/guides/web)
- [Firebase Flutter password reset and email verification](https://firebase.google.com/docs/auth/flutter/manage-users)
