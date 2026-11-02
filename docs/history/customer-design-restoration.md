# Customer design restoration — 26 September 2026

The app entry point had forwarded signed-in customers into
`lib/hashir_work/app.dart`, creating a separate customer interface and store.
It now uses the original `lib/src` role shell for customers as well as farmers
and administrators. The alternative implementation remains in the repository.

This restores the existing Home, Explore, Assistant, Orders and Profile pages,
the original animated green navigation dock, Ola robot and 82-pixel floating
basket. Authentication and customer data continue through FirebaseStore.

## Verification

- `flutter analyze --no-pub`: no issues.
- Existing auth, role-navigation, responsive layout, shopping-flow and streamed
  assistant checks: 24 passed.
- New live-customer routing and sign-out regression: passed. It asserts the
  original HomeScreen receives the existing authenticated session store.
- SMTP wrapper syntax and local secret-setup script syntax: valid.

No email provider is activated. See `email-delivery-setup.md` for the separate
unfinished email-verification work and its infrastructure requirements.

The Android update is built with `--build-name 1.0.2 --build-number 3`, keeping
`com.example.untitled` and the existing signing configuration. Install with
`adb install -r` to retain user data; do not uninstall the existing app.

## Physical phone check

Connected Infinix X690B, serial 055832504H001842, installed version 1.0.1 (2):

- Home opened with the signed-in customer and original navigation, Ola robot
  and enlarged basket visible.
- Explore loaded 11 catalog products. Some products displayed the missing-photo
  fallback; image delivery for those products is not yet verified.
- Opening filters exposed a transparent-sheet bug: filter text overlapped the
  underlying catalog. Fixed the modal to use the themed opaque surface, safe
  area and clipping. Existing customer shopping-flow test passed afterward.
- ADB repeatedly disconnected/went offline. Assistant, Orders, Profile and
  their nested routes have not yet been inspected on this phone. Neither have
  farmer/admin sessions. Do not report all pages as verified.

The initial restored-design APK built successfully after reducing Gradle
memory and worker concurrency. An attempted NDK upgrade was reverted because
the newer NDK folder contained only an incomplete installer. The existing
NDK 27 build succeeded with plugin compatibility warnings.
