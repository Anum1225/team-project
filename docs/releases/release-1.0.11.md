# HarvestHub 1.0.11 (build 12)

## Customer demo

- Restored **Explore demo mode** underneath the login form.
- Uses the customer screens and production products, active farms, categories and markets, including search, filtering, product details, farm details and public content.
- Basket, favourites and following work locally during the demo session. Checkout offers **Keep browsing** and **Sign in / Create account**. The basket survives returning to the form and transfers after the signed-in customer catalog loads, with quantities clamped to available stock. It is not persisted across process termination.
- Checkout is blocked both in the UI and in the guest store. Private orders, profile changes and notifications prompt for sign-in.
- Guest assistant answers are labelled catalog guidance/saved tips. Live Gemini requires an authenticated account.
- Published catalog reads use a fixed, paginated Apps Script action with explicit public-field allowlists. It cannot select arbitrary collections or expose profiles, emails, orders, credentials or farm owner IDs. Firestore security rules were not broadened.
- Includes the 30-minute email verification and verification-race fixes from 1.0.10.

## Verification

- Customer demo flow and role-layout suite: 16 tests passed before the final basket-handoff regression was added.
- Email-code input/resend regressions: two tests passed.
- Final guest suite: three tests passed, covering pagination, published markets, local actions, order rejection, customer basket handoff after data loading and full browse-to-sign-in navigation.
- Apps Script suite: 11 tests passed, including public-field projection, inactive farm exclusion, pagination cursor validation and authenticated action rejection.
- Flutter analysis: no issues.
- Apps Script version 5 is live at the existing endpoint; version 4 is retained for rollback. No new permissions, billing or credentials were required.
- Read-only live smoke passed: one published product, four active farms, nine categories, zero separately published market records. Farm-provided market names remain visible. Unauthenticated code verification was rejected. The counts reflect the live catalog at verification time.

## Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`; version 1.0.11, code 12; minimum SDK 24, target SDK 36 (manifest verified).
- Size: 102,926,184 bytes.
- SHA-256: `63F95479E56BED0133844EAF7A76BDF849E6046B8B7CF3AFBCA56A52FD0FAA19`.
- Release build succeeded in 164.5 seconds. Existing Android tooling compatibility warnings remain; final Flutter analysis reported no issues.
- Installed successfully on the connected Infinix X690B using `adb install --no-streaming -r`, preserving app data. Device package readback confirmed version 1.0.11/code 12, updated 27 September 2026 at 13:07:09.
- Automated screen tests and live backend checks passed. Manual acceptance of the new demo on the physical phone remains with the owner.
