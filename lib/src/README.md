# HarvestHub source map

`lib/main.dart` boots Firebase. `app.dart` owns startup, session verification and
role navigation. Application features follow the requested role structure:

```text
features/
├── authentication/
│   ├── customer_login_register/
│   ├── farmer_login/
│   ├── admin_login/
│   ├── password_reset/
│   ├── two_step_verification/
│   ├── account_security/
│   ├── demo/
│   ├── onboarding/
│   └── shared/
├── customer/
│   ├── home/
│   ├── categories/
│   ├── search_filter/
│   ├── product_details/
│   ├── wishlist/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── profile/
│   ├── ai_assistant/
│   ├── farmers/
│   └── widgets/
├── farmer/
│   ├── dashboard/
│   ├── profile/
│   ├── products/
│   ├── add_product/
│   ├── edit_delete_product/
│   ├── inventory/
│   ├── orders/
│   ├── order_status/
│   └── reports/
├── admin/
│   ├── dashboard/
│   ├── customers/
│   ├── farmers/
│   ├── products/
│   ├── categories/
│   ├── orders/
│   ├── reports/
│   ├── users/
│   ├── content/
│   ├── reviews/
│   └── settings/
└── common/
    ├── notifications/
    ├── about_us/
    ├── contact_us/
    ├── data/
    ├── location/
    ├── markets/
    ├── products/
    ├── orders/
    ├── profile/
    ├── management/
    ├── reports/
    └── shared/
```

Screen implementations extracted from larger files use Dart `part of` so their
private state/helpers retain the same library scope. Import their owning library
(`customer/customer.dart`, `authentication/authentication.dart`, or the relevant
Common library), not a part file directly.

Where multiple roles use one implementation, role entry files explicitly export
that implementation. For example, farmer/admin products share inventory and the
product editor; role checks and permissions continue to apply. Categories use
the customer's existing category/filter screen. Add/Edit use the existing editor
with an optional product. No duplicate screen implementations are introduced.

The complete move/extraction record is `docs/architecture/role-file-moves.json`.
Flutter platform projects and build configuration stay in their required places.
The unused historical application was removed in release 1.0.16 after dependency
checks. Test fixtures remain under `test/fixtures/`; production seeding remains
disabled. Mandatory email verification applies to all roles. The removal manifest
is `docs/audits/removed-old-work-1.0.16.json`.
