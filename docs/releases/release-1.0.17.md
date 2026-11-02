# HarvestHub 1.0.17 (build 18)

## Requested farmer catalog

- Published 56 new product listings across the existing Ali farmer and Hashir farms. Each requested farmer now has 29 active products across all 9 existing categories: Vegetables, Fruits, Dairy, Grains, Oats, Herbs, Pulses.., Pantry and Organic.
- Used matching bundled photographs, real farm ownership and the owner's authorized initial prices/stock. Prices follow earlier catalog values where available; all are stored in integer PKR minor units. Farmers can edit prices and stock in their existing product editor.
- Preserved all 6 previously stored product documents, including the 2 active listings, without changing their fields. Archived products were not reactivated.
- Created products and updated category counters atomically, with document creation/update-time preconditions. Verified every new image, price, stock and farm ID, as well as every category count. A private pre-change snapshot was saved.
- [Published product list, prices and stock](catalog-1.0.17.json).

## Demo browsing and cart

- Demo visitors can browse the live catalog, categories, photos and product details.
- Add to cart on product cards, product details and wishlist now offers **Keep browsing** or **Sign in / Create account**.
- Guest cart additions are rejected in the store as well as guarded in the UI. Removed the previous guest-basket handoff. Signed-in customers retain normal cart behavior.
- Guest checkout still rejects orders; existing server authentication protections are unchanged.

## Verification and delivery

- 13 focused Flutter tests passed, covering catalog pagination, guest store rejection, all three Add to cart entry points, sign-in navigation, signed-in customer cart behavior, product assets and existing order/store behavior.
- Flutter static analysis: no issues.
- Live public catalog check: 58 products across 2 pages, 9 categories; protected actions require authentication. A second read confirmed each requested farm exposes exactly 29 products across all 9 categories, and all 56 new public photos, prices, stocks and farm IDs match the publication plan.
- Release APK built successfully in 248.1 seconds; version 1.0.17/code 18 and package `com.example.untitled` verified. Existing NDK/Kotlin toolchain warnings remain.
- APK signature verified and certificate matches 1.0.16, supporting an in-place update. SHA-256: `AA865B91CC5EB6CCD5EF64C2235D4335855208CC4786DF049EB3808ABE366AB7`.
- Installed successfully on the connected Infinix X690B without uninstalling or clearing data. Device package readback confirms 1.0.17/code 18 and update time 2026-09-27 19:25:15. Android reports `MainActivity` resumed and the app process running (PID 4013). Installation/launch were verified; a manual purchase was not placed.
