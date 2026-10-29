# Authentication form merge

Sign-in, registration and password recovery use the OneDrive customer project forms. Customer browsing, following, pickup and notifications are now integrated as described below. They use the source form layout, scoped theme, fonts, validation, password visibility and separate screen files. No role selector appears on the login form. Existing Firebase model registration is preserved. On sign-in, the persisted active account role decides which existing panel opens, regardless of the welcome entry point.

The shared visual theme and administrator panel are preserved. Existing customer screens receive only the controls and links needed for the added features; authenticated catalog data continues to come from Firestore. Public administrator registration remains disabled. The server verifies credentials and reads the profile before authenticated navigation.

This form merge does not deploy Cloud Functions. Existing operations that use them (such as checkout and management writes) retain the prior backend deployment requirement; the earlier Blaze blocker is not resolved by a form/style merge.

## Customer features added after scope confirmation

The customer design is retained, with additional navigation for Following and Notifications under Profile and pickup management in order details. Login now always offers Create account (the administrator entry creates a customer account, never an administrator) and Explore customer demo. The demo has 24 products and six farms imported from the OneDrive customer project, isolated from live inventory. Demo users can browse and favorite, but store guards and route guards block cart, checkout, orders and account changes.

Guest favorites persist on the device. Signed-in favorites, followed farms and notification read state persist in `users/{uid}/private/preferences`. Pickup windows persist in `users/{uid}/pickups/{orderId}`; rules require ownership of an active order. A customer can select, change or cancel a sample window, without claiming a real farm capacity reservation. Notifications show in-app order status and pickup updates; background push/restock alerts remain outside this merge.

Checkout selects a pickup window per farm and saves it after the existing backend places the order. If pickup saving fails, the order remains placed and the app asks the customer to retry from order details. The existing Cloud Functions checkout and administrator operations still require backend deployment; the earlier billing blocker has not been resolved by this merge. Demo data is never written into the production catalog.

The new preference/pickup rules were deployed to harvesthub-80047. Live temporary-account checks verified favorites/follows/read state, pickup save/reschedule/cancel, denial of cross-account access and denial of changes on completed orders. Temporary test records were cleaned up.

## Startup, route access and mobile layout

Unauthenticated launch now runs Splash -> shared Login -> the saved account role's panel. Existing authenticated sessions restore their own panel. Create account, recovery and customer demo remain available from Login. Customers and guests cannot open inventory, product editing, management reports or dashboards; administrator-only screens require an authenticated administrator even when opened directly. Session changes reset the live navigator.

All app bars disable automatically implied back controls, and explicit customer back arrows have been removed. Platform back navigation remains available. Greeting/date and catalog summary rows wrap on narrow phones without changing panel colors or styling. Layout coverage includes 320, 360, 393 and 430 logical-pixel widths, plus larger text for detail screens.

## Customer flow corrections

Splash now stays visible for six seconds, including reduced-motion mode; its animation completes before the timed hold ends. Login/signup controls use full-width rounded buttons with explicit gaps and roomier field spacing. The shared login offers customer registration only for now; successful Firebase registration loads the saved profile and opens that role's panel. No new farmer screens were added.

Customer detail pages use a nested navigator inside AppShell, retaining Home, Explore, Assistant, Orders and Profile. Selecting a tab closes detail routes and dismisses the keyboard, while preserving cached tab state. Platform back pops the nested detail route. A local ScaffoldMessenger keeps feedback messages above the detail screen's bottom actions.

Home search opens the actual produce search with keyboard focus. Search supports trimmed, case-insensitive product/category/farm/location terms, submit, clear and empty-result reset. Regression checks cover six-second startup, customer signup routing, search -> product -> tab switching, platform back and the basket/checkout flow using fixtures. Real checkout still depends on the previously documented Cloud Functions deployment.
