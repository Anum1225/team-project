# HarvestHub customer app

Customer-only Flutter screens based on the HarvestHub SRS. No administrator or farmer management interface is included. Farmer profiles are public customer browsing screens.

## Run

Use the Flutter SDK matching `pubspec.yaml`, then run:

```sh
flutter pub get
flutter run -d chrome
```

Choose **Explore customer demo** on the welcome screen. No credentials are needed for the demo.

## Customer screens

- Welcome, sign in, registration, password reset
- Home, category browsing, search, advanced filters and sorting
- Product details, wishlist, basket and simulated checkout
- Order confirmation, order history, order details
- Pickup scheduling, rescheduling and cancellation per farm
- Grower directory, public farm profiles and followed farms
- Profile, edit contact/address details, change password
- In-app notifications, farm product assistant, about and contact/feedback

The layout uses bottom navigation on mobile and a navigation rail on desktop. Illustrations are drawn locally and do not require image downloads.

## Preview boundaries

This change implements customer screens and interactive demo state, not production backend integration. Catalog, prices (PKR), locations, distances and pickup availability are sample data. Cart, wishlist, followed farms, edited profile, orders and notices are kept in memory and reset on app restart or demo logout. Checkout is simulated; no payment or delivery service is involved.

Login, registration, password reset/change, support submission, real-time inventory and push notifications require live services. The forms validate input and explicitly explain that no authentication or message delivery occurs. Passwords are not persisted. The assistant uses predefined answers and sample inventory, not a live AI API.

The existing Firebase configuration references `harvesthub-80047`; the CLI account checked during implementation listed a different HarvestHub project, `harvesthub-31be8`. Firebase configuration and remote data were not modified. Confirm access to the intended project before implementing authentication and durable storage.

The SRS mentions pickup/notifications in its customer requirements but excludes them in its constraints. Their customer UI and session-based simulated interactions are included; external pickup and notification services are not implemented.

## Code map

- `lib/customer/app.dart`: app, welcome/auth forms, responsive customer navigation
- `lib/customer/catalog.dart`: browsing, products, wishlist, public grower screens
- `lib/customer/shopping.dart`: cart, checkout, orders and pickups
- `lib/customer/account.dart`: account, notifications, assistant, about and contact
- `lib/customer/store.dart`: sample models and session state
- `lib/customer/ui.dart`: shared theme, components and farm illustration

## Validation

```sh
flutter analyze
flutter test
flutter build web
```

Tests cover stock limits, order snapshots, per-farm pickup validation, search/wishlist interactions, checkout and customer screen layouts at 320, 390 and 1280 pixels. A desktop home screenshot is written to `build/customer-preview/home-desktop.png` by the visual review test.

Implementation assistance: OpenAI Codex. Review the code and demo limitations before using this as a project submission.
