# Firebase configuration

- `firestore.rules`: active database access rules.
- `firestore.indexes.json`: active Firestore query indexes.
- `storage.rules`: preserved optional Storage rules for the legacy emulator setup. The current free-plan app stores compressed photos in Firestore; Storage deployment is not enabled.

The root `firebase.json` references the active Firestore files. Run Firebase CLI
commands from the project root, or run the documented emulator command from
`functions/`. Emulator tests resolve rule files relative to their own source.

These files were moved without content changes on 27 September 2026. Moving
configuration does not require a production deployment or a new APK.
