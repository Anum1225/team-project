# Firebase and mobile interface verification

This is the initial audit. The subsequent authorized cleanup and current data
state are documented in [firebase-cleanup-2026-09-26.md](firebase-cleanup-2026-09-26.md).

## Preserved backend

The production entry point initializes `harvesthub-80047` and constructs
`FirebaseStore`. The Firebase project, app IDs, existing records, deployed rules,
and indexes were not changed during this pass. Hashir's historical source remains
under `lib/legacy/hashir_work` and is not imported by the production entry point.

Live checks confirmed:

- The project is active, with billing disabled.
- Deployed Firestore rules match the local rules after whitespace normalization.
- All six configured composite indexes exist and report `READY`.
- The live database contains the marketplace collections.
- No Cloud Functions are deployed.

## Data authenticity

The production code does not import a preview store. PreviewStore was moved from
`lib/src/data` to `test/fixtures`; tests now import it from there.

The former `scripts/seed_firebase.js` contained sample records and targeted the
live project. It is now a disabled entry point which exits without making network
requests. The live `farms/green` document matches that script's Greenwood Organic
Farm sample, including its description and owner ID. Thus Firebase connectivity
does not establish that all existing records are genuine. Existing live data has
not been deleted; cleanup needs a reviewed inventory, backup and confirmation,
including checks for linked products and historical orders.

## Interface changes

- Customer and farmer headers have a profile action at the far right; the admin
  dashboard now supplies the same action.
- Ola has a larger vector illustration, a more readable Ask Ola label, a larger
  close target and shell highlights.
- Farmer and admin dashboards now expose the same dismissible assistant launcher.
- Preview screenshots were regenerated for all three roles using test fixtures.
  These screenshots are visual checks, not live-account evidence.

## Verification and limits

- Flutter regression suite: 45 passed, 1 optional capture test skipped.
- Separate role screenshot capture: passed.
- Firebase Auth/Firestore emulator and domain suite: 14 passed. It covers role
  boundaries, stock and checkout transactions, order transitions, private
  feedback, pickup restrictions, and authentication/security behavior.
- Flutter analysis: no issues.

The emulator used `demo-harvesthub`, not production data. The email-code tests
validate local handlers; they do not prove deployed email-code delivery.
Automatic push notifications and custom email-code handlers remain undeployed.
Native Firebase verification/reset links are the configured email flow.
No live customer checkout, device push delivery, or live Gemini conversation was
performed in this pass. Ola still uses Firebase AI Logic without canned answers.

The application model `gemini-3.5-flash-lite` is listed in the official
[Firebase AI Logic model documentation](https://firebase.google.com/docs/ai-logic/models).
