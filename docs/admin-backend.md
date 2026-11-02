# HarvestHub admin backend — Firebase Spark plan

Production uses Firebase Authentication and Cloud Firestore only. No Cloud Functions or Cloud Storage deployment or billing upgrade is required. The old `functions/index.js` implementation is retained as a legacy reference but is absent from `firebase.json` and unused by the app. `functions/` also contains the emulator tests and the private administrator provisioning utility.

## Implemented

- Email/password login, customer/farmer registration, password recovery and password changes. Public admin registration is blocked. Session roles and active status come from Firestore, with route removal on logout/revocation.
- Admin dashboard and day/week/month reports over real orders, paged through the complete selected interval. Account/product/category counts use Firestore count queries. Monetary values are simulated order values, not payment settlement.
- Customer/farmer search, contact edits, suspension/reactivation, farmer details and farm editing.
- Category creation, duplicate-name rejection, transactional rename/reassignment, and refusal to remove a category with active products. Renames support fewer than 400 products; larger categories must be reassigned in smaller groups.
- Product creation/editing and archiving, integer minor-unit prices, nonnegative stock, category and farm relationships. Images are resized and compressed to at most 100 KB, then stored as JPEG data URIs in Firestore. Historical orders retain their image/name/price snapshots.
- Atomic checkout with rule-verified product snapshots, prices and stock reductions. Maximum **3 distinct products per checkout**, with one tracked order per product, keeps cross-document rule checks within Firebase limits even across different farms. Retry receipts prevent duplicate submissions. Failed transactions do not partially place orders.
- Sequential order statuses and cancellation/restocking in a transaction. Completed/cancelled orders cannot be reopened. Archived product stock is not restored.
- Private feedback and append-only admin activity records.
- Production never instantiates seeded preview data. `PreviewStore` is injected explicitly by tests only.

## UI

Outfit and Fraunces are bundled locally with their OFL licenses. The authentication flow uses a botanical backdrop, staggered entrances and animated form modes. App surfaces and typography use light/dark tokens; the global sun/moon control reveals the next theme with an expanding circle. The initial theme follows the device setting; manual selection lasts for the current app session. Reduced-motion settings skip the visual reveal. Charts animate actual daily order values and expose values through tap/hover tooltips.

## Main files

- `lib/src/firebase_store.dart`: session, scoped listeners, error handling and image compression.
- `lib/src/spark_backend.dart`: Firestore transactions, registration and report queries.
- `firestore.rules`, `firestore.indexes.json`: authorization and query indexes.
- `lib/src/auth.dart`, `theme.dart`, `theme_reveal.dart`, `animated_chart.dart`: auth presentation, typography, colors and motion.
- `lib/src/reporting.dart`, `operations.dart`, `profile.dart`, `orders.dart`: administrator workflows.

## Collections

`users/{authUid}` contains the immutable role and Auth email plus editable contact details/active status. `farms/{farmerUid}` is owned by that UID. Products reference a farm and a category ID; categories use base64url of the trimmed lowercase display name and a transactional product count. Orders contain immutable customer/farm/product snapshots. `checkoutRequests/{uid}_{requestId}` records retry receipts. `feedback` and `adminActivityLogs` are private to administrators. Existing per-user preferences and pickup rules are preserved.

Privileged client actions remain constrained by Firestore rules. Customers cannot edit catalog prices or order snapshots; checkout must atomically reduce stock and match the current catalog. Farmers can manage their own farm/catalog and orders. Administrators are trusted to administer business records, but clients cannot grant an admin role, change account roles, or suspend an admin account. Hard deletion of users, farms, products and orders is denied.

## Setup and administrator access

1. Enable Email/Password in Firebase Authentication and create a dedicated administrator Auth account privately.
2. Set up Application Default Credentials for an authorized project maintainer, then run `node functions/provision-admin.js harvesthub-80047 <existing-auth-uid>`. Review the utility's usage first. It stores no passwords. Never commit credentials or put an admin password in the app.
3. Deploy **only** Firestore: `firebase deploy --project harvesthub-80047 --only firestore`.
4. Run `flutter pub get`, then `flutter run` (or build the desired platform).

No existing customer should be promoted without the project owner's explicit selection. Admin account provisioning is separate from deploying rules and requires the dedicated Auth account.

## Local verification

- `flutter analyze`
- `flutter test`
- `flutter build web --release`
- `firebase emulators:exec --project demo-harvesthub --only auth,firestore "npm --prefix functions run test:spark"`
- `flutter run -d web-server --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1` for an isolated demo project.

The free-plan suite exercises registration/RBAC, contact edits, suspension, farmer product/count writes, tampered checkout rejection, atomic stock changes, order transitions/cancellation, private feedback, and checkout spanning three farms. Legacy callable/Storage tests are not the active Spark-plan acceptance suite.

Firestore listeners begin with 100 records per collection and expose Load more. Reports page in batches of 500; they read matching order documents on the client, so report cost/read usage grows with history. Images are intentionally small to fit Firestore document limits. Payment processing and server-managed Auth account deletion are not part of this academic order system.
