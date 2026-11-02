# Administrator implementation plan

Audit: the existing ChangeNotifier store is a session-only fixture; Firebase is configured for harvesthub-80047 but unused. No persisted schema, rules, repositories, or working authentication existed. Existing screens, role enum, integer minor-unit prices, order line snapshots, and farm market names will be retained. Existing uncommitted work is the baseline.

1. Extract shared store interface; keep seeded fixtures only for explicitly injected tests.
2. Initialize Firebase and restore sessions from authenticated users/{uid} profiles; guard the entire navigator on revocation/logout. No public admin provisioning.
3. Add scoped Firestore listeners and paginated lists. Introduce users, farms, products, categories, orders using existing model fields.
4. Add trusted transactional callable mutations for accounts, farms, products, categories, checkout and order transitions, plus audit logs. Preserve snapshots and archive products.
5. Await all UI mutations, show loading/errors/retry and confirmation, connect edits and photos.
6. Fetch complete report summaries separately from paginated screen records; derive trends, farmer rankings and market summaries from actual orders.
7. Deny direct client business writes in rules. Authenticate and authorize every callable. Validate object IDs, values, transitions and related records transactionally.
8. Test backend invariants, emulator access boundaries, Flutter domain/widgets, analyze and build. Document deployment and bootstrap steps truthfully.
