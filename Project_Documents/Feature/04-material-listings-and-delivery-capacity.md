# Feature Specification 04 — Material Listings and Delivery Capacity

**Document ID:** BM-FEAT-04  
**Version:** 1.0  
**Status:** Implementation-ready specification, subject to unit/pricing policy decisions  
**Priority:** P0 — MVP  
**Dependencies:** Features 01 and 03; initial catalog/configuration

---

## 1. Purpose

Allow eligible sellers to create and maintain marketplace offers for construction materials with delivery included in the same offer. The listing is the core product entity that connects a material specification, seller, load/quantity, delivered price or quote workflow, delivery capacity, service area and availability.

**Non-negotiable business rule: Every orderable listing bundles material and truck/delivery from one seller.**

BUILD MATE is not a marketplace for separately booking trucks. A seller may own or control the delivery vehicle through an arrangement, but the listing and responsibility remain with one seller.

## 2. Outcomes

- Sellers can draft, submit, edit and pause their own listings.
- Listings clearly describe material specification, quantity/unit and delivery terms.
- Sellers can publish fixed delivered-price offers or quote-required offers, based on the approved policy.
- Listings are discoverable only after the required seller eligibility and moderation checks.
- Availability and quantity are not silently overstated.
- Confirmed order snapshots remain unchanged when the underlying listing is edited.
- Public listing responses exclude private contacts and internal data.

## 3. Scope

### Included
- Initial material categories.
- Material specifications/attributes.
- Seller-owned listing CRUD.
- Quantity and unit validation.
- Bundled delivery fields.
- Fixed delivered price and quote-required modes.
- Service areas and availability.
- Capacity and freshness information.
- Listing images using the media feature's storage/security controls.
- Moderation and listing-state transitions.
- Public listing DTO.
- Listing eligibility and concurrency integration.

### Excluded
- Independent truck-owner accounts and truck booking.
- Customer-to-driver matching.
- Live GPS and route optimization.
- Automated vehicle telematics.
- Dynamic AI pricing.
- Automatic claims that a specific material is legally certified or of a guaranteed grade.
- Multi-seller listings/orders.
- Unsupported quantity units or unapproved material attributes.

## 4. Initial categories

Initial category codes:
- `BLACK_STONE`
- `SAND`
- `BRICKS`
- `MURUM`

Category codes are stable internal identifiers. User-facing labels and detailed attributes should be configurable.

Do not assume all sand/aggregate/brick/murum products are interchangeable. Specification fields should capture relevant differences such as grade, size or type where the product owner defines them. The approved category schema must specify which attributes are required, optional, searchable and user-visible.

## 5. Listing data model

Use the conceptual schema in `Database.md`. A listing should include:

- `id`
- `seller_id`
- `category_id`
- Optional `specification_id`
- `title`
- `description`
- `available_quantity`
- `quantity_unit`
- `minimum_order_quantity`
- `price_mode`
- Optional `delivered_unit_price`
- `currency`
- `delivery_included`
- Included/excluded charge explanations
- Service-area definition
- Availability start/end, where applicable
- Estimated lead time, if configured
- Relevant truck/delivery type and capacity
- Listing state and moderation state
- Last availability confirmation timestamp
- Version/concurrency field
- Created/updated/published timestamps

Use fixed-point numeric types for prices and fractional quantities. Precision and unit compatibility must be configured explicitly.

## 6. Listing state model

Recommended listing statuses:
- `Draft`
- `PendingReview`
- `Active`
- `Paused`
- `Rejected`
- `Expired`
- `Archived`

Recommended moderation statuses:
- `Pending`
- `Approved`
- `Rejected`
- `Flagged`
- `Removed`

Do not collapse listing lifecycle and moderation into a single ambiguous status.

### Eligibility rule
A listing is publicly orderable only when all required conditions hold, including:
- Listing lifecycle state is `Active`.
- Moderation state is `Approved`.
- Seller is operationally eligible and verification approval is valid according to policy.
- Category/specification is active.
- Listing is not expired or otherwise blocked.
- Quantity/unit/price rules are valid.
- Delivery is bundled.
- Requested service area/date/quantity is supported by the listing.

The backend enforces these conditions on public search, listing detail and order submission. Frontend visibility is not sufficient.

## 7. Pricing modes

### 7.1 Fixed delivered price
A fixed-price listing must clearly state:
- Currency.
- Price basis (for example, per tonne, per unit or per defined load).
- Quantity unit.
- Delivery inclusion.
- Any legitimate exclusions or separately applied charges.
- Applicable price/availability conditions.

The server validates the price and computes the order total using the approved price rules. The browser must not be trusted to calculate the final amount.

### 7.2 Quote required
A quote-required listing explicitly states that the customer must request and accept a quote before the transaction is confirmed.

- Do not display an estimated/example number as a confirmed price.
- Define the quote lifecycle in feature 06.
- A quote must identify its scope, quantity/unit, delivery terms, total/currency, expiry and acceptance conditions as approved.
- The order becomes confirmed only after the required acceptance rules are satisfied.

### 7.3 Delivery inclusion
For every orderable MVP listing, `delivery_included` must be true. If a valid business case later requires a special delivery arrangement, it must be modeled and labelled through an approved product change—not by silently allowing a materials-only listing into the default marketplace.

## 8. Capacity and availability

Capacity must be explicit enough to prevent impossible offers.

Recommended concepts:
- Total available quantity.
- Quantity unit.
- Minimum order.
- Optional maximum order.
- Load/truck capacity and unit, where meaningful.
- Service area.
- Available date range or schedule.
- Lead time.
- Last availability confirmation.
- Reservation/consumption behavior after order acceptance.

### Key design decision
The product owner and engineering lead must specify whether `available_quantity` means:
1. Remaining deliverable material for the listing over the availability period; or
2. Maximum quantity per dispatch/load; or
3. Another clearly defined capacity model.

Do not overload one database field with several meanings. If total inventory and per-load capacity differ, model them separately.

The quantity unit and truck capacity unit must be compatible or linked through an explicit conversion rule. Do not assume every truck capacity is comparable to every material quantity.

### Freshness
- Provide a mechanism for sellers to confirm/update availability.
- Define the maximum freshness interval only after operational review.
- Listings that fail the approved freshness rule can be hidden, paused or require reconfirmation.
- Do not invent a freshness interval and present it as an approved business policy.

## 9. Service area

The listing must identify where its delivery offer is available.

Possible representations:
- Explicit supported postal codes/localities.
- Normalized service-area records.
- A validated area structure with documented semantics.
- More advanced geography only when required.

Select one representation and document it consistently in `Database.md`, search queries and API contracts.

Do not conclude that an offer serves a delivery address merely because the seller and customer share a city name. The backend must apply the chosen service-area policy. If location cannot be validated confidently, return a quote/manual-confirmation path rather than falsely promising availability.

## 10. Seller listing workflow

1. Seller is authenticated.
2. Backend checks seller profile, status and verification eligibility.
3. Seller creates a draft.
4. Seller chooses category and enters required specification.
5. Seller enters available quantity, unit, minimum order and any capacity details.
6. Seller specifies fixed delivered price or quote-required mode.
7. Seller confirms delivery is included and defines included/excluded charges.
8. Seller configures service area and availability.
9. Seller adds approved-format media, if desired.
10. Backend validates the listing.
11. Seller submits for moderation when required.
12. Authorized moderator approves/rejects the listing.
13. Only eligible approved listings become publicly orderable.
14. Seller can pause/update an eligible listing; changes that affect material commercial terms may trigger re-review according to policy.

## 11. Proposed API contract

Expected route family:
- `GET /api/v1/sellers/me/listings`
- `POST /api/v1/sellers/me/listings`
- `GET /api/v1/sellers/me/listings/{listingId}`
- `PATCH /api/v1/sellers/me/listings/{listingId}`
- `POST /api/v1/sellers/me/listings/{listingId}/submit`
- `POST /api/v1/sellers/me/listings/{listingId}/pause`
- `POST /api/v1/sellers/me/listings/{listingId}/resume`
- `GET /api/v1/material-categories`
- `GET /api/v1/material-categories/{code}`
- `GET /api/v1/listings`
- `GET /api/v1/listings/{listingId}`

Admin moderation endpoints are defined in `API.md` and the admin/moderation feature specification.

### API rules
- Verify seller ownership server-side.
- Use request DTOs and explicit public listing DTOs.
- Reject invalid status transitions.
- Allow only approved, defined enum values.
- Enforce bounded title/description/media inputs.
- Apply rate limits and size limits to uploads.
- Never accept a client-provided seller verification status.
- Do not let the seller set moderation state directly.
- Use concurrency control for simultaneous listing updates.

## 12. Validation requirements

Validate at minimum:
- Category exists and is active.
- Specification belongs to the selected category.
- Required category attributes are present.
- Quantity and minimum order are positive.
- Minimum order does not exceed allowable per-order capacity.
- Supported unit and precision are valid.
- Price mode is valid.
- Fixed price has an acceptable positive amount.
- Quote mode does not imply a confirmed fixed price.
- Currency is supported.
- Delivery is included.
- Service area has a valid structure.
- Availability dates are ordered and compatible with policy.
- Lead time/capacity values are within configured limits.
- Only approved media is published.
- Seller is eligible for the requested transition.

## 13. Price and snapshot integrity

Listing price and data can change. An already-confirmed order must preserve its accepted terms.

When an order is created/confirmed:
- Snapshot material category/specification.
- Snapshot listing title/description fields relevant to the agreement.
- Snapshot seller display name or relevant seller reference.
- Snapshot quantity/unit.
- Snapshot unit-price and price mode as appropriate.
- Snapshot delivery inclusion/exclusions.
- Snapshot accepted quote/terms if used.
- Snapshot delivery-address data according to the order feature contract.

Listing edits must not mutate old order snapshots. A material price change may require re-moderation or buyer reconfirmation for future orders, but never silently revise an already-confirmed order.

## 14. Concurrency and availability integrity

Potential race: multiple customers request the last available quantity at the same time.

Required design:
- Define when capacity is reserved or consumed.
- Validate quantity and availability inside a database consistency boundary.
- Use a concurrency token, transaction/locking strategy or another proven mechanism.
- Use order idempotency for client retries.
- Release reserved capacity correctly for eligible cancellations.
- Prevent repeated status actions from consuming capacity twice.
- Add integration tests with concurrent requests.

Do not rely exclusively on a frontend quantity check or an earlier search response.

## 15. Moderation and change rules

- New listings may require moderation before first publication.
- Edits to commercial or potentially misleading fields may require re-review based on the approved policy.
- A paused/removed/expired listing must not remain orderable through a direct API call.
- Seller suspension must affect listing eligibility even if listing rows still say `Active`.
- Listing removal should preserve records needed for audit and historical orders.
- Public moderation reasons should be safe and appropriate; internal notes remain private.
- All privileged moderation overrides are audited.

## 16. User interface requirements

### Seller listing dashboard
Show listing title, category, load quantity/unit, delivered-price/quote mode, current status, last updated time and available actions.

### Listing editor
Group form fields into material, quantity/capacity, pricing, delivery, service area, availability and media. Label every field; explain units and delivery pricing basis.

### Preview
Before submission, show the customer-facing presentation and identify missing information. Preview must not expose private data.

### Public listing detail
Show approved material/specification, quantity, pricing mode, unit, delivery inclusion, service area, availability and truthful seller trust information. Do not show private contact data.

## 17. Error cases

Handle:
- Seller not approved.
- Seller suspended or closed.
- Category/specification inactive.
- Invalid quantity/unit.
- Invalid price or missing price for fixed mode.
- Delivery excluded.
- Unsupported service area.
- Listing submitted while already under review.
- Listing paused/expired during checkout.
- Concurrent update conflict.
- Capacity exhausted.
- Media upload failure.
- Moderation rejection.
- Seller status changes after publication.

Use clear error codes so the UI can explain required action without displaying internal exceptions.

## 18. Required tests

### Unit tests
- Required field and unit validation.
- Fixed-price versus quote-required rules.
- Seller/listing eligibility.
- Listing lifecycle and moderation transitions.
- Delivery-included rule.
- Category/specification compatibility.
- Capacity-boundary conditions.

### Integration tests
- Seller can create/edit their own listing.
- Seller cannot edit another seller's listing.
- Ineligible seller cannot create/orderably publish a listing.
- Pending/rejected listing is not publicly discoverable.
- Paused/expired listing cannot be ordered.
- Public DTO excludes private contact/document fields.
- Fixed-price calculations use backend values.
- Concurrent edits are handled predictably.
- Capacity cannot be oversold under tested concurrency.
- Existing order snapshot stays unchanged after listing edits.

### Browser tests
- Seller creates draft and submits a valid listing.
- Validation errors are understandable.
- Seller pauses an active listing.
- Approved listing appears in public search.
- Rejected/paused listing is not shown as orderable.
- Public listing detail shows quantity, unit and delivery terms accurately.
- Responsive listing cards work on narrow mobile screens.

## 19. Acceptance checklist

- [ ] Initial categories are configured.
- [ ] Category-specific required attributes are documented.
- [ ] Listing schema distinguishes quantity from per-load capacity.
- [ ] Delivery is bundled for all orderable MVP listings.
- [ ] Price modes are explicit.
- [ ] Seller ownership and eligibility are enforced.
- [ ] Moderation is separate from listing lifecycle status.
- [ ] Public listing DTO is allowlisted.
- [ ] Service area/availability rules are consistent with search and checkout.
- [ ] Snapshot and capacity integrity are tested.
- [ ] Media uses the approved access-control model.
- [ ] Automated tests pass for negative and concurrent cases.

## 20. Completion gate

A listing is complete when a qualified seller can publish an accurate, validated, moderated material-plus-delivery offer and the backend reliably determines whether it is available and orderable. No listing may bypass required seller, moderation, unit, price or delivery constraints.
