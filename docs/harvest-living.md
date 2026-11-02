# Harvest Living — UI audit and implementation notes

## Starting point

Reviewed the complete 22-page HarvestHub SRS v1.0 and the supplied 52-section design brief. The checkout initially contained one Material inventory screen, an unused generated Firebase configuration, and one smoke test. There were no repositories, authentication flows, domain models, role routes, photography assets, or customer/farmer/admin screens to preserve. `lib/dummy_data.dart` was deleted externally during inspection; that deletion is preserved.

The starter used repeated pale-green surfaces, default type, placeholder workspace information, unlabelled inventory icons, and a layout vulnerable to narrow-screen overflow. It lacked transactional states, accessible role navigation, stock enforcement, and a coherent component system.

## Scope and boundaries

This implementation is a complete, interactive **UI development preview**. Sample catalog, people, and orders are isolated in a preview repository and identified in the interface. They are never represented as live Firebase records. Production authentication and data services were absent in this checkout. Firebase configuration is preserved; no remote schema, rules, credentials, or data are modified. Sign-in and registration screens validate input and explain service unavailability rather than pretending to authenticate. Preview actions last for the session and never place real orders or send feedback.

The SRS's contradictory pickup, push notification, restock-alert, and farmer-follow requirements are optional capabilities, disabled by default. Order statuses retain the SRS's Ready for Pickup label; this does not enable scheduling. No payment collection is present. The assistant uses a small explicitly identified reference library, permitted by the SRS.

## Design direction

Warm cream canvas, deep forest actions, editorial serif headlines, legible Manrope UI type, produce photography, thin rules, and restrained honey accents. Avoid decorative metrics, unnecessary cards, and category icon repetition. Role-specific navigation keeps shopping, farm operations, and administration distinct.

| Foundation | Decision |
|---|---|
| Canvas / surface | #FAF7EF / #FFFFFF |
| Text / secondary | #172019 / #667069 |
| Primary / selected | #153D2E / #2F6B46 |
| Tinted surface / border | #E8EFE1 / #DEE4DA |
| Warm accent | #F0B84D |
| Display / UI | DM Serif Display / Manrope, bundled locally |
| Spacing | 4, 8, 12, 16, 20, 24, 32, 40, 48, 64 |
| Radius | 12 controls, 16 buttons, 20 cards, 28 hero |
| Motion | 140ms response, 200ms state, 300ms routes |
| Touch targets | Minimum 48 logical pixels |

## Navigation and flows

- Shared: initialization mark → role choice → sign in/register or explicit preview; profile editing, account settings, about, contact, sign out.
- Customer: Home / Explore / Assistant / Orders / Profile. Search and filters → product → farmer → basket → address and order review → simulated confirmation → order detail. Saved products accessible from the header and profile.
- Farmer: Dashboard / Products / Orders / Reports / Profile. Searchable inventory → validated product editor → stock and removal confirmations. Order detail → status sheet. Period reports derived from actual preview orders.
- Administrator: Dashboard / Users / Catalog / Orders / More. Role-filtered people → details and suspension controls; product/category management; order status controls; platform reports.

## State and accessibility rules

Every transaction validates before mutation, including stock at checkout. Order lines snapshot names and prices so later catalog edits cannot rewrite history. Empty collections have useful recovery actions. Errors have explicit retry or dismissal. Image failures show a labelled neutral fallback. Role switching preserves preview data but changes access scope. Text and icons accompany status colors. Safe areas and scrollable forms keep actions reachable with the keyboard and larger text. Motion respects the system's reduce-motion setting.

## Reference provenance

UI UX Designer's mobile-app-ui and design-system-builder skills informed hierarchy, touch targets, states, and token layering. Mobbin search was attempted but returned a paid-plan requirement; no Mobbin screens were available or copied. Font sources: [DM Serif Display](https://fonts.google.com/specimen/DM+Serif+Display), [Manrope](https://fonts.google.com/specimen/Manrope). Photography is illustrative preview content, not evidence about real farms or products.

## Integration handoff

The preview store is deliberately separate from widgets. A production adapter must supply authenticated profiles, catalog, order, wishlist and basket persistence, server-enforced roles, stock transactions, approved support contact details, and error/offline state. Preview role selection is not authorization. Do not expose preview switching as an administrator login in a production deployment.
