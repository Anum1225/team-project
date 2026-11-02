# HarvestHub 1.0.8 (build 9)

## Installed Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Package: `com.example.untitled`
- Version: 1.0.8; version code: 9 (verified in APK manifest and phone package readback)
- Size: 102,761,292 bytes
- Minimum SDK: 24; target SDK: 36
- SHA-256: `FBD6468433EA8ED0ACA07DBF0FDDF809CDF546131E63010FF7E9AEDB34BF4C91`
- Installed in place on the Infinix X690B; ADB reported `Success`.
- Device update time: 2026-09-27 10:47:20 (local).

Existing app identity/signing and app data were retained.

## Changes

- Customer Home's floating Ola artwork is now 60 × 60 logical pixels, with a 64-pixel interaction area and a further 6-pixel shift toward the right edge. Removed the visible Ask Ola label; accessible naming, the dismiss control, blinking eyes and gentle motion remain. The static customer chat-header mascot is unchanged.
- Refined the farm hero card with a clearer cream primary button, softer secondary action, rounded leaf detail and subtle border.
- Connected the complete About page to `appConfig/public`: page title, eyebrow, headline, image/description, story, community and approach sections, and footer. Current text is also the editor's default draft; existing published story text is retained.
- Admin Settings → About & public content supports previewing without publishing, then publishing to the live public page. Blank optional sections/images can be hidden. Support email/phone remain editable.
- Saves merge into the existing document, preserving unrelated settings. Admin access is checked in the editor and by existing Firestore rules. Drafts remain available after a save failure; required fields are validated even after scrolling out of view.

## Verification

- Twenty existing navigation/layout/preview tests passed, including all three roles and large-text detail views.
- Four About regressions passed: legacy/default loading, preview/publish/live-update flow, required fields outside the viewport, and non-admin rejection. Initial test scrolling needed correction to target the page rather than text-field scrollables.
- The scoped Firestore emulator test passed: customer/farmer writes denied, admin publish accepted, public read accepted, and unrelated settings retained by merge.
- Flutter analysis passed with no issues. Customer Home preview was visually reviewed.
- The existing production rules already allow this administrator-owned public document; no rules or Apps Script deployment change is required. Tests used fixtures and the local emulator, without publishing test copy to the live About page.

Existing free-service, Android tooling and notification acceptance limits remain documented in [1.0.7](release-1.0.7.md) and the [SRS audit](../audits/srs-audit-2026-09-27.md).
