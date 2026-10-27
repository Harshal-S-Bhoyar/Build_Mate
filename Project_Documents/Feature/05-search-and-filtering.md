# Feature Specification 05 — Search and Filtering

**Document ID:** BM-FEAT-05  
**Version:** 1.0  
**Status:** Implementation-ready specification, subject to service-area policy  
**Priority:** P0 — MVP  
**Dependencies:** Feature 04 — Material Listings and Delivery Capacity

---

## 1. Purpose

Enable customers to find eligible ready-to-deliver construction-material loads using material category, requested quantity/unit, delivery area, preferred date and supported optional filters.

Search must produce actionable, trustworthy results. It must not expose private seller details or imply that a seller can fulfil a delivery when the service-area, quantity or availability rules do not support that conclusion.

## 2. Outcomes

- Customers can discover eligible listings on mobile and desktop.
- Search results match supported material, quantity/unit, delivery-area and availability rules.
- Filters and sort options are validated and bounded.
- Public listing DTOs remain privacy-safe.
- Results have stable pagination and clear loading/empty/error states.
- Search behavior is consistent with listing eligibility and subsequent order validation.

## 3. Scope

### Included
- Public material-category list.
- Listing search endpoint.
- Category filter.
- Quantity/unit filter, where a meaningful supported rule exists.
- Delivery area/postal-code filter.
- Requested date filter, if availability scheduling is implemented.
- Price range filter for compatible fixed-price offers.
- Allowlisted sort options.
- Pagination.
- Public listing DTO and detail link.
- Empty/loading/error/permission-neutral states.
- Search unit and integration tests.

### Excluded
- AI recommendations.
- Personalized ranking based on private user data.
- Live GPS tracking or route optimization.
- Map-based discovery unless approved separately.
- Arbitrary-distance delivery guarantees.
- Seller-contact lookup/directory.
- Search across unapproved, paused, rejected or expired listings.
- Complex multi-item/multi-seller cart search.

## 4. Search design principles

1. Search only eligible public offers.
2. Be explicit about price basis and unit.
3. Show quote-required offers as quote-required, not fixed-price.
4. Apply delivery-area semantics defined by the platform.
5. Keep filter meaning consistent between the UI and API.
6. Use a consistent sort and pagination contract.
7. Do not return unbounded result sets.
8. Do not query private seller data for display.
9. Avoid false certainty where location, date or capacity cannot be confirmed.
10. Revalidate eligibility during order submission even if a search result appeared available moments earlier.

## 5. Canonical listing eligibility

A result may be returned as orderable only if all required conditions hold:
- Listing lifecycle status is `Active`.
- Listing moderation status is `Approved`.
- Seller is eligible and not suspended/closed.
- Category and required specification are active.
- Listing has not expired or been blocked.
- Material and delivery are bundled.
- Quantity, unit and price-mode data are valid.
- Service area and requested delivery date/quantity match the supported eligibility rules.
- Listing freshness rules, once approved, are satisfied.

Apply the eligibility policy centrally or through a shared query/specification that is consistent with order submission. Do not maintain separate, contradictory rules in multiple controllers.

Public listing detail must not reveal a listing as orderable merely because it can be retrieved by a known UUID.

## 6. Search inputs

### 6.1 Category
Filter by a known, active category code. Initially:
- `BLACK_STONE`
- `SAND`
- `BRICKS`
- `MURUM`

The backend validates the code; unknown/inactive categories must produce a clear validation outcome.

### 6.2 Delivery area
Use a normalized delivery-area representation approved for the pilot, such as locality/postal-code service areas. Search must not assume that a seller can deliver to an arbitrary address simply because the seller operates in the same city.

A geospatial query or map provider is optional. If service eligibility is not determinable from the available information, the UI must not claim guaranteed delivery. It may allow a qualified enquiry or quote flow if the product rules support it.

### 6.3 Quantity and unit
Quantity filters must compare compatible units only.

- Validate positive values and maximum permitted ranges.
- Use documented supported units.
- Reject or clarify incompatible units rather than silently converting them.
- If a listing defines maximum per-load capacity separately from remaining available quantity, filter against the correct field.
- Treat exact unit conversion as a domain rule with tests; do not hardcode a casual conversion inside the UI.

### 6.4 Requested delivery date
Only apply a requested-date filter if the listing's availability data is meaningful and consistently populated.

- Validate date/time formats.
- Define timezone semantics in API documentation.
- Do not interpret a date-only value as a random server-local time.
- Exclude unavailable offers if the listing's explicit availability rules determine the requested date is not serviceable.
- If sellers have not supplied reliable date availability, do not claim date-confirmed results.

### 6.5 Price range
For fixed delivered-price offers, filter based on the documented normalized price basis.

Do not compare prices from incompatible quantity units as if they were the same amount. Do not include quote-required offers in numeric price ordering unless the UI clearly separates them and the ordering semantics are defined.

### 6.6 Sort options
Use an explicit allowlist, such as:
- `newest`
- `price_asc`
- `price_desc`

Optional relevance/popularity ranking needs an approved and documented score. Do not use private personal data or fake popularity values.

## 7. Proposed API contract

### Categories
- `GET /api/v1/material-categories`
- `GET /api/v1/material-categories/{code}`

### Search
- `GET /api/v1/listings`

### Detail
- `GET /api/v1/listings/{listingId}`
- `GET /api/v1/listings/{listingId}/availability` — only if a meaningful public availability summary exists.

Example request:

```http
GET /api/v1/listings?category=SAND&postalCode=440001&page=1&pageSize=20&sort=newest
Accept: application/json
```

Potential query parameters:
- `category`
- `quantity`
- `unit`
- `postalCode`
- `locality`
- `deliveryDate`
- `minPrice`
- `maxPrice`
- `sort`
- `page`
- `pageSize`

These parameters must be enabled only after their semantics are implemented. Do not add a parameter to OpenAPI merely because it appears in this example.

## 8. Response contract

Return an explicit public search DTO with:
- Listing ID.
- Approved public title and description summary.
- Category/specification display data.
- Minimum order quantity and unit.
- Relevant available quantity/capacity information if public and meaningful.
- Price mode.
- Delivered unit price and currency for fixed-price listings.
- Delivery inclusion and permitted charge summary.
- Public seller display name and allowed trust indicators.
- Approved listing-media references.
- Service-area and availability summary.
- Genuine rating data only if eligible records exist.

Do not include:
- Private seller phone/email/personal WhatsApp.
- Private verification documents or storage keys.
- Payout data.
- Internal moderation notes.
- Full customer address records.
- Internal admin flags or secret risk scores.

### Pagination response
Use a consistent structure, for example:
- `items`
- `page`
- `pageSize`
- `totalItems` if calculated reliably and economically
- `hasNextPage`

The exact contract must match `API.md` and the implementation.

## 9. Search processing

Recommended backend flow:
1. Parse and validate query parameters.
2. Apply the canonical public listing/seller eligibility criteria.
3. Normalize the requested service area according to the approved representation.
4. Apply compatible category, unit, quantity, date and price predicates.
5. Apply an allowlisted sort.
6. Apply stable ordering with a unique tie-breaker.
7. Apply bounded pagination.
8. Project directly into an explicit public DTO.
9. Return the result and safe pagination metadata.

Use EF Core parameterized queries and translated query predicates. Do not concatenate caller-provided filter or sort strings into raw SQL.

Do not retrieve unrestricted entity graphs and then rely on ad hoc in-memory filtering for large result sets.

## 10. Stable pagination

- Page numbers start at 1 if page-based pagination is selected.
- Page size has a server-enforced maximum.
- Invalid negative/zero values are rejected or normalized according to one documented policy.
- Sort fields are allowlisted.
- Use deterministic tie-breakers, such as listing ID, to avoid unstable ordering of records with equal sort values.
- Consider cursor pagination later if growth or high listing churn demonstrates the need.

Do not return unlimited results when `pageSize` is omitted. Define a safe default and maximum in configuration.

## 11. Sorting and price comparison

For fixed delivered-price listings:
- Sort only when the compared prices use a compatible basis.
- Show the unit next to a unit price.
- State whether taxes/fees are included where applicable.
- Keep transport/delivery inclusion visible.

For quote-required listings:
- Display “Request a quote” or the approved equivalent.
- Do not sort them as zero-cost offers.
- Do not compare unknown quote amounts as fixed values.

If some results cannot be compared reliably, separate them into a clearly labelled group or omit that sort option until the comparison logic is well-defined.

## 12. Frontend requirements

### Search controls
- Material category selector.
- Requested quantity and unit if applicable.
- Delivery-area input.
- Requested date if supported.
- Optional price filters with correct unit semantics.
- Search and clear/reset actions.

All controls require labels and accessible error feedback.

### Results view
- Listing cards share a consistent layout.
- Material image/specification is visible.
- Quantity/unit and delivered-price basis are clear.
- Quote-required items are distinguished from fixed-price items.
- Seller privacy is maintained.
- Pagination or load-more behavior is understandable.
- Active filters are visible/removable.

### States
Implement:
- Initial state.
- Loading.
- Successful result list.
- Empty results.
- Invalid filter input.
- Server/network failure.
- Partial data/media failure.
- Listing no longer available.
- Expired session for actions requiring login.

Do not show a blank page or an infinite spinner as the only failure behavior.

## 13. Search freshness and order revalidation

A search result is a snapshot at the time of the query, not a guarantee that a listing will remain available.

- Listings can be paused, expired or sold out after search.
- Availability freshness behavior must follow the approved policy.
- Listing detail should show an appropriate current state.
- Order submission must revalidate seller eligibility, listing status, capacity, quantity, service area, date and current price/quote rules inside a consistency boundary.
- If the offer becomes ineligible, return a clear response directing the user to refresh/search again.
- Never confirm an order using stale price information without the required server-side validation and user acceptance.

## 14. Performance and database considerations

Start with indexes aligned to real predicates and measured query plans.

Potential index dimensions include:
- Listing lifecycle/moderation/category.
- Seller ID and listing state.
- Fixed price for supported price sorts.
- Normalized service-area lookups.
- Expiry/availability fields when frequently used.

Do not create every possible composite index automatically. Examine actual query plans, result sizes and update overhead. If service-area data is stored in JSONB, confirm indexing/query semantics are appropriate; a normalized area table may be preferable for frequent filtering.

Use `EXPLAIN ANALYZE` on representative non-production data before significant optimization decisions. Do not add Redis or another cache without measured need and a plan for staleness/invalidations.

## 15. Errors and edge cases

Handle:
- Unknown category.
- Incompatible quantity/unit.
- Invalid price range.
- `minPrice` greater than `maxPrice`.
- Unsupported sort.
- Invalid page/page size.
- Unsupported delivery-area format.
- Invalid delivery date or timezone semantics.
- Listing paused/expired/unapproved during a user journey.
- Seller suspended after the listing was created.
- No results.
- Database timeout/unavailability.
- Invalid/unknown listing ID.
- A query that would produce an excessive result set.

Do not turn internal database failures into a successful empty-result response. Distinguish “no eligible results” from “search failed.”

## 16. Required tests

### Unit tests
- Query-parameter validation.
- Allowlisted sort values.
- Quantity/unit matching rules.
- Price-mode comparison rules.
- Service-area eligibility predicates.
- Listing eligibility policy.

### PostgreSQL integration tests
- Approved active listing appears.
- Paused/expired/rejected listing is excluded.
- Unapproved/suspended seller listings are excluded.
- Material/delivery bundling is required.
- Quantity/unit filters behave correctly.
- Price filters exclude quote-required or incompatible records according to policy.
- Pagination is bounded and stable.
- Public DTOs exclude private fields.
- Category/specification joins return correct results.
- Search query maps correctly to PostgreSQL behavior.

### Browser tests
- Customer searches by category and delivery area.
- Filters can be applied/reset.
- Search returns relevant cards and clear empty states.
- Fixed-price and quote-required listings are presented accurately.
- Pagination is functional and accessible.
- Narrow mobile layout is usable.
- Errors do not imply that no materials exist when the service actually failed.
- Opening a listing that became unavailable shows a safe current-state message.

## 17. Observability and metrics

Measure:
- Search request count and latency.
- Result count distribution.
- Zero-result rate by supported category/area.
- Popular validated filters.
- Listing-detail click-through.
- Search-to-enquiry/order conversion where lawful and privacy-appropriate.
- Search errors/timeouts.
- Percentage of results failing subsequent order revalidation.
- Stale-listing incidence.

Use these metrics to identify supply gaps and stale offers, not to create fake popularity or trust claims. Apply privacy and retention controls to analytics.

## 18. Acceptance checklist

- [ ] Search only returns eligible public listings.
- [ ] Material categories are configurable and active-state-aware.
- [ ] Quantity/unit comparison is explicit and tested.
- [ ] Service-area logic is documented and consistent.
- [ ] Price filters/sorts compare compatible pricing bases.
- [ ] Quote-required listings are represented honestly.
- [ ] Pagination is bounded and deterministic.
- [ ] Public response DTO contains only allowlisted fields.
- [ ] Search UI supports loading, empty and failure states.
- [ ] Order submission revalidates the search result.
- [ ] PostgreSQL integration tests cover eligibility and privacy.
- [ ] Query performance is measured before large-scale optimization.

## 19. Completion gate

Search is complete when customers can discover eligible, correctly described material-plus-delivery offers; filters and pagination behave predictably; private fields remain protected; and the order flow does not treat search results as a guarantee of continuing availability.
