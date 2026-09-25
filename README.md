# HarvestHub customer app

Customer-only Flutter screens based on the HarvestHub SRS. No administrator or farmer management interface is included. Farmer profiles are public customer browsing screens.

## Run

Use the Flutter SDK matching `pubspec.yaml`, then run:

```sh
flutter pub get
flutter run -d chrome
```

Choose **Explore customer demo** on the welcome screen. Demo visitors can browse/search products, save/remove favorites, and follow favorite farms. Adding to the basket, checkout, orders, pickup management, and account changes require customer access.

## Customer screens

- Welcome, sign in, registration, password reset
- Home, category browsing, search, advanced filters and sorting
- Product details, wishlist, basket and simulated checkout
- Order confirmation, order history, order details
- Pickup scheduling, rescheduling and cancellation per farm
- Grower directory, public farm profiles and followed farms
- Profile, edit contact/address details, change password
- In-app notifications, farm product assistant, about and contact/feedback

The sample catalog includes 24 products (4 per main category) from 6 farms. Home and Explore both display the full collection.

The layout uses bottom navigation on mobile and a navigation rail on desktop. Illustrations are drawn locally and do not require image downloads.

## Firebase and sample data

The app initializes Firebase and uses email/password authentication. Registration saves a customer profile to `users/{uid}` before granting access. Profile changes, cart/favorites/follows, simulated orders, pickup changes and feedback use Firestore under that user's document. Passwords are handled by Firebase Auth and are never stored in Firestore. Save failures are displayed. Guest favorites use local preferences; guests cannot create carts or orders.

The configured project remains `harvesthub-80047`. The CLI account checked during implementation only listed a different HarvestHub project, `harvesthub-31be8`. Live account creation and writes have NOT been verified. The intended project needs Email/Password authentication enabled, a Firestore database and compatible security rules. `firestore.rules` is a proposed customer-scoped ruleset; it has not been deployed. Review and merge it with existing project rules before deploying to the confirmed project, especially if other panels share that database.

Catalog, prices (PKR), distances, inventory and pickup availability remain sample data. Orders are simulated purchases without payment or real stock reservation. Order history listens to Firestore updates; background push/restock notifications are not implemented. The assistant uses predefined answers. Support contact details are pending.

Existing tests use explicitly constructed in-memory customer fixtures; the running app only grants customer access after Firebase authentication and profile loading. `customer_forms_test.dart` was removed at the user's request. Test files do not run as part of the app and do not block Firebase writes.

## Code map

- `lib/customer/app.dart`: app bootstrap only
- `lib/customer/screens/`: one screen per file, with its private State kept alongside it; sign in, registration and password reset each have their own file
- `lib/customer/widgets/`: individual reusable widgets, illustrated assets and shared form fields
- `lib/customer/models/`: one data model per file
- `lib/customer/state/customer_store.dart`: session state and shopping operations
- `lib/customer/data/`: sample catalog and pickup availability
- `lib/customer/theme/customer_theme.dart`: shared colors and theme
- `lib/customer/validation/`: customer input rules and first-error scrolling
- `lib/customer/utils/`: navigation and display formatting

## Form validation

Customer rules follow the bookstore project's validation approach:

- Names: 2-100 characters, international letters, spaces, apostrophes and hyphens; numeric or punctuation-only names are rejected.
- Email: validates local-part and domain structure, including length limits and malformed dots/domain labels.
- Phone: 7-15 digits with optional country code and common formatting; letters are rejected and saved profile numbers are normalized.
- Address: 12-500 meaningful characters; feedback: 10-2000 meaningful characters.
- New passwords: 8-128 characters including a lowercase letter and a number. Registration includes confirmation; changes also reject reusing the current password.
- Sign in/current password: required, with an upper length bound; does not impose new-password strength rules on existing credentials.
- Checkout pickup and feedback subject: must match an available option.

Inline errors update after interaction. Submit checks all fields and scrolls to the first invalid field. Form fields stay mounted while scrolling, so offscreen input cannot bypass validation. Confirmation is revalidated when its source password changes. These are client-side validations; live credential checks use Firebase Auth.

## Validation

```sh
flutter analyze
flutter test
flutter build web
```

Tests cover demo access guards, all demo entry points, preserved favorites, direct protected routes, validator boundaries, stock limits, order snapshots, per-farm pickup validation, search/wishlist interactions, checkout and customer screen layouts at 320, 390 and 1280 pixels. A desktop home screenshot is written to `build/customer-preview/home-desktop.png` by the visual review test.

Implementation assistance: OpenAI Codex. Review the code and demo limitations before using this as a project submission.
