# HarvestHub 1.0.15 (build 16)

## Role folder organization

- Active source is organized under Authentication, Customer, Farmer, Admin and Common in `lib/src/features/`.
- Moved 44 source files, extracted 46 screen/helper parts from large files, and added 17 role entry files for screens with shared implementations. The migration verifies that extracted screen bodies reconstruct the original source exactly before formatting.
- Shared inventory, order, profile and authentication implementations retain existing role checks and private helper scope. Role entry files export those implementations; they do not duplicate screens.
- Application/test imports were updated, and platform/configuration locations remain compatible with Flutter. A private pre-migration source backup and a public path manifest record the moves.
- [Complete source tree](../../lib/src/README.md) and [move manifest](../architecture/role-file-moves.json).

## Existing product photos

- Inspected the six existing live products. Three carrot products had an empty image or a farm placeholder; their `image` field now references the existing bundled `carrots.jpg` photo.
- The three writes were atomic and conditional on the inspected document versions. Readback confirmed every other field was unchanged.
- No products, users, orders, categories or other historical records were restored. Existing tomato photos were retained. New product forms still start without an automatically selected image.

## Verification

- 77 distinct Flutter tests passed; three optional capture/disabled checks remain skipped. The full run initially found one test waiting for a continuously animating admin loading placeholder. Its wait was bounded, then all five access/session tests passed on rerun.
- Role navigation, authentication/mandatory code gates, customer checkout, administrator permissions, layout, guest browsing, image display, notifications and store tests passed.
- Final static analysis reported no issues.

## Android artifact

- Release build succeeded in 170.5 seconds; existing Android NDK/Kotlin tooling warnings remain.
- APK: `build/app/outputs/flutter-apk/app-release.apk`, package `com.example.untitled`, version 1.0.15/code 16, minimum SDK 24, target SDK 36 (manifest verified).
- Size: 102,893,552 bytes; SHA-256: `2897E9E0750B1638BCD4D07CD41E1A3611990258A21B405BC97D69AC75B1250B`.
- In-place installation on Infinix X690B succeeded. Device package readback confirms 1.0.15/code 16, updated 27 September 2026 at 16:18:33; app data preserved.
