# HarvestHub administrator backend

The administrator screens now use Firebase Authentication, Cloud Firestore, Cloud Storage and callable Cloud Functions. The existing screens, ChangeNotifier scope, models, integer minor-unit prices and order status sequence are retained. Seeded records are only available through an explicitly injected `PreviewStore` test fixture; the production entry point never creates it.

## Files

Created:

- `lib/src/store.dart`: shared view state and operation contract extracted from the existing store.
- `lib/src/firebase_store.dart`: Firebase session, scoped live queries, asynchronous mutations, uploads, serialization and error mapping.
- `lib/src/reporting.dart`: real administrator dashboard and period reports.
- `functions/index.js`, `functions/domain.js`, `functions/package.json`, `functions/package-lock.json`: trusted callable operations and report calculations.
- `functions/provision-admin.js`: private provisioning of an existing dedicated Auth account.
- `functions/test/domain.test.js`, `functions/test/emulator.test.js`, `test/admin_access_test.dart`: domain, emulator and route regression tests.
- `firestore.rules`, `storage.rules`, `firestore.indexes.json`, and this documentation.

Modified:

- `lib/main.dart`: Firebase initialization, retry screen and optional isolated emulator configuration.
- `lib/src/app.dart`, `auth.dart`: real login/registration, session-derived routing and logout; no production preview gateway or simulated social login.
- `lib/src/models.dart`: account creation timestamp.
- `lib/src/components.dart`: network photos, loading/error/refresh/load-more controls and data-derived chart series.
- `lib/src/operations.dart`, `orders.dart`, `profile.dart`, `customer.dart`: awaited persistence, validation, searches, profile/farm editing, account suspension, category safeguards, product archiving and checkout.
- `lib/src/preview_store.dart` and existing tests: explicit fixture injection and asynchronous operation compatibility.
- `pubspec.yaml`, `pubspec.lock`, generated platform plugin registrants, `firebase.json`, `.gitignore`.
- Dart formatting also normalized existing source/test formatting. Existing unrelated icon, platform and design changes were preserved.

## Collections and integrity

| Collection | Contract |
| --- | --- |
| `users/{authUid}` | Trusted role, active status, name, Auth email, phone, address, created/updated timestamps. |
| `farms/{farmerUid}` | Existing farm fields: owner UID, name, location, market name, description, image, active status. |
| `products/{id}` | Existing product fields plus archive flag and timestamps. Price is integer paisa; stock is a nonnegative integer. |
| `categories/{normalizedNameKey}` | Display name, transactional product count, timestamps. Key is base64url of lowercase trimmed name. |
| `orders/{id}` | Customer/farmer/farm IDs, customer/farm/market snapshots, purchased line snapshots, total, address, status, timestamps. |
| `checkoutRequests/{uid_requestId}` | Idempotency receipt for safe checkout retries. Not client-readable. |
| `adminActivityLogs/{id}` | Admin UID, action, entity ID, server timestamp. No credentials or tokens. |
| `feedback/{id}` | Authenticated contact submissions. No new support-management module was added. |

The checkout had no existing persisted schema or security rules. These collections map the existing Dart models rather than introducing duplicate customer/farmer models. Do not import the old preview fixtures into production. If external data exists in the Firebase project, inspect and migrate it to this contract before deployment; remote data was not inspected or modified during implementation.

Product deletion archives the listing. Orders retain names, prices, quantities and images independently of later edits. Account management suspends/reactivates profiles and farms without deleting Auth identities or order history. Suspended profiles cannot execute callable operations or access protected data.

Category/product writes share category documents inside Firestore transactions. This prevents duplicate names and deletion/assignment races. Renaming updates active product references atomically. A referenced category cannot be deleted. Renames affecting 400 or more active products are blocked with an instruction to reassign products in smaller groups.

Order progress is `pending → confirmed → ready → completed`. An open order may instead become `cancelled`. Terminal orders cannot change. Cancellation restores nonarchived product stock in the same transaction exactly once. Checkout validates current stock and farm availability, groups by farm and writes orders, stock changes and retry receipt atomically.

## Authentication and authorization

Email/password login is verified by Firebase Auth. The selected portal is checked against the server-fetched `users/{uid}` role and active status. Public profile registration accepts only customer/farmer roles. Privileged roles cannot be set by client writes.

Firebase Auth restores the session; a profile listener handles role/status changes. Session changes replace the navigator, removing pushed privileged pages. Admin pages also reject nonadmin access directly. Logout clears cached records and cancels subscriptions.

Business writes are denied directly in Firestore, including writes from admin clients. Callables independently authenticate the caller, read the active profile inside their transaction, validate ownership and input, and perform the operation through the server Admin SDK. Rules restrict private user/order reads. Storage permits new PNG/JPEG uploads up to 8 MB only in the active farmer/admin caller's own upload namespace. Overwrites/deletes are denied to preserve historical references.

Firebase Auth and Codex Security guidance informed the trust-boundary review. Emulator tests verify these concrete controls; this is not represented as a separate sealed Codex Security scan.

## Queries and reports

The shared session attaches five bounded collection listeners plus the current profile listener. Lists begin with 100 records; Load more expands the live window by 100. Screens reuse this cache instead of creating per-row listeners. Search and filter controls explicitly cover loaded pages. Refresh retries queries and updates totals.

Reports are independent of the client list window. Count aggregations calculate account/category/catalog counts. Orders are read in bounded 500-record server pages for the requested period and grouped by status, UTC calendar day, farm and snapshotted market. Most-active farmers are ranked by orders received, with completed counts and simulated value; the top 20 are returned. All-status order value includes cancelled orders and is labelled accordingly; completed value is separate. No payments or payment transactions are invented.

Six composite indexes cover customer/farmer order sorting and farmer report ranges, product farm/category/archive queries and inventory counts. Single-field indexes handle the remaining queries. Category counts come from persisted transactional counts, not partially loaded products.

## Firebase setup and deployment

1. In the existing `harvesthub-80047` Firebase project, enable Email/Password authentication, create the default Firestore database, and initialize Storage if they are not already enabled. The generated Flutter configuration is preserved.
2. Enable billing required by Cloud Functions/Storage and ensure the deployment account has the necessary project permissions. This implementation uses Node 22 functions in `us-central1`.
3. From the repository root, install backend dependencies with `npm --prefix functions ci` and deploy with:

   ```powershell
   firebase deploy --project harvesthub-80047 --only functions:harvesthub,firestore,storage
   ```

4. Complete any Firebase prompt granting Storage rules access to Firestore. Wait for composite indexes to finish building.
5. Create a dedicated email/password account in Firebase Console Authentication. Choose a private password; no default password is included. Record its UID and optionally set its display name.
6. On a trusted machine with Application Default Credentials, provision that existing UID:

   ```powershell
   node functions/provision-admin.js harvesthub-80047 EXISTING_AUTH_UID
   ```

   Alternatively, an authorized operator can create `users/{UID}` in the console with `role: admin`, `active: true`, name/email/contact fields and a Firestore `createdAt` timestamp. Never grant public write access to do this. Never put an Admin SDK key or a password into Dart, repository files or assets.

7. Sign in through the administrator portal. Use ordinary registration for farmers/customers, then add real categories, farm information and products through the app.

Deployment, live project provisioning and production sign-in have not been performed. No production credentials were created or exposed.

## Local verification

```powershell
flutter analyze
flutter test
flutter build web --release
firebase emulators:exec --project demo-harvesthub --only auth,firestore,functions,storage "npm --prefix functions test"
```

For local interactive testing, run the emulators and start Flutter with `--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1`. Android emulators use host `10.0.2.2`. The define selects `demo-harvesthub`, not production. Emulator records and credentials in tests exist only in the isolated test project.

Verified: 28 Flutter tests passed, one optional screenshot capture skipped; seven backend tests passed with Auth, Firestore, Functions and Storage emulators; static analysis passed; release web build succeeded. Tests cover direct-route denial, session revocation, existing customer/farmer layouts and checkout, wrong password, role escalation, protected reads/writes, upload permissions, invalid prices, duplicate category names, category dependencies/renames, concurrent checkout idempotency, zero stock, invalid order transitions, cancellation restock, archiving, suspension and report values.

## Scope and limits

- List search is over loaded pages; it is not a global full-text search service. Load more or refresh is available.
- Reports scan matching orders on the server and are suitable for the academic scope. A large production dataset should use maintained rollups; no revenue cache with fabricated or partial totals is used.
- Uploaded image versions are retained because old orders may reference them. An interrupted upload/save can leave an unreferenced object; automatic garbage collection is not implemented because uncertain write outcomes must not break committed records.
- Basket, wishlist and recent-search state retain the existing session-local behavior. Orders/catalog/profile changes persist. Optional notifications and pickup scheduling remain outside scope.
- Native Android/iOS/macOS/Windows builds and live Firebase configuration require platform/project checks on the deployment environment. Linux Firebase was not configured in the existing generated options.
