# Authorized live demo-data cleanup

The owner authorized removal of confirmed demo data after the earlier audit.
The existing `harvesthub-80047` Firebase project, app IDs and security rules remain
in place. No replacement catalog, fake stock, prices, reviews or orders were added.

## Backup and scope

Before mutation, all 76 Firestore documents (including user subcollections) were
saved to `.local-backups/firebase-cleanup-2026-09-26/firestore.json`. This private
directory is excluded from Git. The file's SHA256 is
`5B75A98B99079DB136FCDC2D0740F8740D3634C440BF51E06A43793FBD630C48`.
The directory also contains the two demo Auth records, deleted document paths,
and the post-cleanup Firestore snapshot. Do not publish these backups: they
contain account data and device tokens. Auth passwords were not changed.

Removed 31 confirmed seed documents:

- 11 demo products (`p2` through `p12`).
- 4 demo farms (`golden`, `highland`, `sun`, `willow`).
- 4 fabricated orders (`ORD-7001` through `ORD-7004`).
- 6 duplicated sample market records across two collections.
- 4 legacy sample farmer records.
- 2 demo user profiles; their Auth logins were disabled, not deleted.

Deletions used document update-time preconditions so concurrent edits would fail
rather than be overwritten. All nine category counts were recalculated to zero
and stale category product references were removed. Saved/followed references to
seed records were removed from the existing preferences document.

## Preserved records

Three user-created orders remain. Their original snapshots were not rewritten.
`farms/green` was made inactive, and `products/p1` was already archived. These two
historical records remain because user-created orders reference them. They cannot
appear as purchasable stock. Inactive farms are excluded from customer farm
filters and Ola's current farm context.

Hashir's accounts, registered farm, archived product, feedback and activity logs
were preserved. Other user-entered accounts were not classified as fake based on
their names or incomplete details. This cleanup establishes seed provenance, not
independent verification of every user's identity or business.

Read-back verification found 45 documents, no deleted targets remaining, three
orders, two active user-created farms, and zero active products. An empty catalog
is expected until farmers publish genuine inventory; archived stock was not
reactivated and no prices or availability were invented.

## Live notifications and remaining service limits

The inbox and unread badge now read authorized Firestore order queries for each
role, using persisted status and timestamps. They no longer rely on an empty
notification collection populated only by undeployed functions. These are live
in-app order updates, limited to the 100 most recently created orders.

Phone push registration is disabled by default and the UI says it is unavailable.
Enable `PUSH_BACKEND_ENABLED` only after a trusted sender is deployed and tested.
The project has billing disabled and no deployed Cloud Functions. Custom email
codes and background push delivery are therefore not completed by this cleanup.
Native Firebase verification and password reset links remain the configured flow.

Restore only reviewed documents from the private backup using their original
Firestore names and typed fields; check for newer data before overwriting. Restore
demo account access only through an explicit decision to re-enable those logins.

## Verification

- Final Flutter suite: 47 passed, one optional screenshot test skipped.
- Final static analysis: no issues.
- The preceding backend emulator suite passed 14 tests; database rules and
  transaction implementation were unchanged during this cleanup.
- Live read-back verified deletion targets, category counts, and preserved orders.

The Android project retains its working NDK 27 configuration. The directory for
NDK 28 contains only incomplete installer files, and the SDK installer failed;
switching to that incomplete version was reverted. Firebase plugins emit an NDK
version warning with the existing toolchain. This does not verify behavior on a
physical Android device, live Gemini responses, or email inbox delivery.
The APK retains the project's existing debug signing identity for local device
testing; it is not a newly configured Play Store release signing setup.
