# HarvestHub 1.0.12 (build 13)

## Requested checkout and order screens

- Customer checkout uses a Review Order form: editable full name, phone number, contact address and optional farmer note; Cash on Delivery; item quantities/prices, total and Confirm order action.
- Contact fields start with profile values. Edits are stored on the order as a snapshot; they do not change the account profile. The authenticated customer identity remains separate from the recipient name.
- Phone, required fields and field lengths are validated. No online payment is collected. Pickup can be booked or changed from order details.
- Customer order details show the pickup row, live progress timeline, harvest items/total and Delivery & Customer Info including the submitted phone and note. Older orders without a saved phone are labelled accordingly.
- Existing cart, dashboard, navigation, general theme and farmer/admin page layouts are retained. Demo still requires sign-in before checkout.

## Verification

- 19 Flutter screen/flow tests passed, including customer checkout and contact snapshots at 360/393 widths, progress status updates, existing role navigation and demo checkout gating.
- 13 Firestore emulator tests passed, including recipient fields, immutable customer identity, payment-method restrictions, oversized inputs, atomic stock/order updates and legacy order shape compatibility.
- Final targeted checkout tests and static analysis passed. Captured checkout, progress and contact previews were inspected.
- The deployed Firestore rules differed only by the optional validated recipient-name field. Deployment succeeded and readback exactly matched local tested rules. No Apps Script deployment was needed.

## Android artifact

- APK: `build/app/outputs/flutter-apk/app-release.apk`.
- Package `com.example.untitled`, version 1.0.12/code 13; minimum SDK 24, target SDK 36 (manifest verified).
- Size: 102,926,320 bytes.
- SHA-256: `6C53323DC4A666F8E618E23A2BBD683C94888817DD99E8A7B4E9A20208561525`.
- Release build succeeded in 238.1 seconds. Existing Android tooling warnings remain.
- Installed successfully on Infinix X690B with `adb install --no-streaming -r`. Device readback confirmed version 1.0.12/code 13 and update time 27 September 2026, 14:02:49. Existing app data was preserved.
- Verification used fixture orders and the local emulator; no production order was placed as a test. Manual phone acceptance remains with the owner.
