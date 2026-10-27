# Feature Specification 06 — Order, Quote and Checkout

**Document ID:** BM-FEAT-06  
**Version:** 1.0  
**Status:** Proposed implementation specification; commercial decisions pending  
**Priority:** P0 — MVP  
**Dependencies:** Features 01–05; order persistence and authorization foundation

---

## 1. Purpose

Define how customers submit orders for ready-to-deliver construction-material loads, how quote-required listings are handled, and how the platform confirms the agreed commercial terms.

BUILD MATE treats an offer as **material + delivery from one seller**. An MVP order refers to one customer, one seller and one listing. The order must preserve the accepted terms, price basis, quantity/unit and delivery address even if the listing or customer profile changes later.

Checkout must be secure, understandable and idempotent. It must never trust a total, fee, seller ID, status or discount supplied by the browser.

## 2. Outcomes

- A customer can review an eligible listing and submit an order request.
- The backend revalidates listing, seller, quantity, delivery area, availability and current pricing at submission time.
- A fixed-price listing produces a server-calculated order amount under the approved price policy.
- A quote-required listing cannot be treated as a confirmed fixed-price order.
- Confirmed commercial terms and delivery address are snapshotted.
- Repeated requests caused by retries do not create duplicate orders.
- The seller receives an order request through the application and approved notification workflow.
- The customer sees a clear outcome even when the operation fails or its result is temporarily uncertain.

## 3. Scope

### Included
- Order-review and submission flow.
- Fixed delivered-price order request.
- Quote request and quote acceptance flow, if quote mode is enabled.
- Server-side total calculation using approved price rules.
- Quantity/unit/service-area/availability validation.
- Order and address snapshot creation.
- Idempotency handling.
- Initial order status and history.
- Notification outbox record for required order events.
- Clear validation, conflict and failure responses.
- Customer-facing order confirmation and recovery experience.

### Excluded
- Independent truck booking.
- Multi-seller cart or one order containing multiple listings.
- Unapproved commission, tax, discount, cancellation or refund rules.
- Production payment collection until the payment policy and provider are approved.
- Automatic promises of a confirmed delivery time where only an estimate is available.
- Seller acceptance of an offer that is already expired or unavailable.

## 4. Key product decisions

The following decisions must be approved before the corresponding behavior is released:

1. Whether account login is mandatory before order submission.
2. Whether fixed-price orders become confirmed immediately as a seller-response request, or require a separate customer confirmation.
3. Whether quote requests require customer authentication.
4. Quote expiry and revision policy.
5. Seller response deadline and what happens when it expires.
6. Payment method and payment timing.
7. Platform fee, taxes, discounts and who pays each charge.
8. Cancellation rules before and after seller acceptance.
9. Required delivery evidence and completion/claim windows.
10. Exact meaning of available capacity, reservation timing and when capacity is released.

Do not invent these values. Keep them in configuration or a documented business-policy service where appropriate.

## 5. Actors

- **Customer:** Reviews an offer, chooses quantity/address/date, and submits an order or quote request.
- **Seller:** Receives a request, then accepts or rejects it under the lifecycle policy.
- **System:** Validates eligibility, calculates price, creates snapshots, records events and triggers background notifications.
- **Admin/support:** Handles only authorized exceptions under documented policy.
- **Payment provider:** Optional; not a source of order authorization or business policy.

## 6. Order and quote terminology

### Order request
A request submitted by a customer for an eligible bundled listing. The request is persisted and given an initial status. Whether it is already a confirmed commercial contract depends on the approved order policy.

### Quote request
A request asking the seller to provide or confirm commercial terms for a `QuoteRequired` listing. It is not itself proof of an agreed final price.

### Quote
A seller-provided offer with explicit scope and terms. It must contain enough information for the customer to understand what is being offered and what happens when it is accepted.

### Confirmed order
An order for which all required acceptance steps have succeeded and the authoritative commercial snapshot has been recorded.

Do not use these terms interchangeably in labels, status codes, analytics or legal documents.

## 7. User stories

### BM-ORDER-01 — Review the offer
As a customer, I want to review material, quantity/unit, delivery location, price basis and terms before ordering.

Acceptance:
- Listing eligibility and current offer information are obtained from the backend.
- Fixed-price and quote-required offers are labelled differently.
- Delivery inclusions/exclusions and relevant fees are visible.
- Customer must be able to identify the total or understand that a quote is required.

### BM-ORDER-02 — Place a fixed-price order request
As a customer, I want to submit a valid order for a fixed delivered-price listing.

Acceptance:
- Server validates the current listing, seller, quantity, unit, availability, service area and address.
- The server calculates all amounts from approved rules.
- An order and initial history record are committed consistently.
- Repeated identical requests do not create duplicate orders.
- The customer receives the persisted order reference and actual resulting status.

### BM-ORDER-03 — Request a quote
As a customer, I want to request a price for a listing that requires a quote.

Acceptance:
- The listing must be eligible for enquiries.
- The request identifies the listing, requested quantity/unit, delivery destination and relevant timing.
- Seller private contact details remain protected.
- The request does not appear as a confirmed fixed-price order.
- The customer can see the request status.

### BM-ORDER-04 — Review and accept a quote
As a customer, I want to review a seller's quote and accept the exact terms offered.

Acceptance:
- The quote is available only to authorized participants.
- The quote displays quantity/unit, delivered-price basis, inclusions/exclusions, currency, validity and any required conditions.
- The backend rejects expired, withdrawn or superseded quotes.
- Acceptance is idempotent and results in a consistent order snapshot.
- The accepted terms cannot be silently changed after confirmation.

### BM-ORDER-05 — Recover from a network failure
As a customer, I want to know whether my order was submitted if my connection fails during checkout.

Acceptance:
- The client reuses the same idempotency key for a retry of the same submission.
- The API returns the original outcome for an equivalent repeated request where supported.
- A conflicting payload using the same key is rejected.
- The UI does not automatically create a second order with a new key merely because a response timed out.

## 8. Checkout workflow

Recommended fixed-price flow:

1. Customer selects an eligible listing.
2. Customer selects quantity and supported unit.
3. Customer selects a saved delivery address or enters an explicitly supported one-time address.
4. Customer chooses the requested delivery date/time when that option is available.
5. Frontend requests a review/price calculation if that API exists.
6. Customer reviews listing specification, seller display information, quantity, delivery terms, price/fees/tax treatment and cancellation terms.
7. Customer submits the request with an idempotency key.
8. Backend authenticates and authorizes the customer.
9. Backend loads current listing/seller state and validates the requested terms.
10. Backend calculates all totals under the approved commercial policy.
11. Backend persists order data, snapshots, initial status history and required audit/outbox records in a transaction where practical.
12. Backend returns the authoritative order reference, amount where applicable, and actual status.
13. Frontend renders success only after receiving the authoritative result.
14. Seller is notified through the configured durable notification workflow.

Do not send a real SMS, WhatsApp message or payment request inside a long-running database transaction.

## 9. Quote workflow

Recommended sequence when quote mode is enabled:

1. Customer submits a quote request.
2. Backend validates listing eligibility and request scope.
3. A quote-request record is created with status and timestamps.
4. Seller sees the request in the seller workflow.
5. Seller prepares a quote containing required terms.
6. Backend validates the quote fields and validity interval.
7. Customer reviews the quote.
8. If accepted before expiry and all preconditions remain valid, the backend creates/confirms the corresponding order according to the approved policy.
9. Quote and accepted-order references remain linked for audit.
10. An expired, withdrawn or superseded quote cannot be accepted.

A specific quote lifecycle enum must be defined in the relevant domain/database implementation. Do not reuse order statuses to represent every quote state.

Possible quote states for consideration:
- `Requested`
- `AwaitingSellerResponse`
- `Offered`
- `Accepted`
- `Declined`
- `Expired`
- `Withdrawn`
- `ConvertedToOrder`

Adopt and document the exact set before implementing quote APIs.

## 10. Pricing rules

### 10.1 Server is authoritative
The browser may display estimates or request a review calculation, but the server performs the final validation and calculation. Ignore or reject client-supplied values for:
- `totalAmount`
- `subtotalAmount`
- `deliveryAmount`
- `platformFeeAmount`
- `taxAmount`
- `discountAmount`
- Commission or seller payout amounts.

### 10.2 Fixed delivered price
Calculate using the listing's current approved pricing basis and validated quantity/unit. Ensure the price basis and quantity are compatible.

Use decimal arithmetic with PostgreSQL `numeric` and C# `decimal`. Do not use binary floating-point arithmetic for money.

### 10.3 Fees, taxes and discounts
The product owner must approve the exact rules before they are enabled. At minimum, store the breakdown needed to explain the total and reconcile it later.

Each applied rule must be traceable to the confirmed order. A later fee-policy change must not alter an old order's snapshot.

### 10.4 Quote-required listing
If the listing uses quote mode:
- Do not calculate a fabricated final total.
- Do not display `0` as if it means free.
- Do not create a fixed-price confirmed order until the quote acceptance conditions are satisfied.
- Clearly communicate the state to customer and seller.

### 10.5 Currency and rounding
INR is the initial supported currency. Store an explicit currency code. Define rounding and precision rules once, centrally, and apply them consistently in API responses, receipts and ledger calculations.

## 11. Order commercial snapshot

Persist a snapshot of the accepted terms so subsequent edits do not rewrite the historical agreement.

Snapshot fields/concepts should include:
- Customer reference.
- Seller reference and relevant seller display identity at confirmation.
- Listing reference.
- Material category and specification.
- Listing title/description details relevant to the offer.
- Confirmed quantity and unit.
- Price mode and unit-price basis.
- Currency.
- Subtotal, delivery amount where applicable, platform fee, discount, tax and total as approved.
- Delivery inclusion/exclusion terms.
- Delivery-address snapshot.
- Requested delivery timing and relevant accepted terms.
- Accepted quote ID/version if quote mode was used.
- Timestamp and version of the policy or offer where useful for audit.

Use structured, versioned snapshot data where necessary. Do not rely solely on querying the current listing row to reconstruct a historic order.

## 12. Proposed API contract

Expected routes are defined in `API.md`:

- `POST /api/v1/orders`
- `GET /api/v1/orders`
- `GET /api/v1/orders/{orderId}`
- `POST /api/v1/quote-requests`
- `GET /api/v1/quote-requests/{quoteId}`
- `POST /api/v1/quote-requests/{quoteId}/accept`

Additional seller quote endpoints must be defined when the quote feature is implemented. Do not expose a generic endpoint that allows a seller to set arbitrary order states.

### Order request
A request may include:
- `listingId`
- `quantity`
- `quantityUnit`
- `deliveryAddressId` or explicitly supported address snapshot input
- `requestedDeliveryAt`
- `customerNote`
- Optional idempotency key in the agreed header.

The client must not provide trusted seller ID or financial totals.

### Response
Return a response DTO containing:
- Order UUID and public order reference.
- Actual current order status.
- Payment status where relevant.
- Currency and authoritative amount if final price is known.
- Created timestamp.
- Clear quote/pending state when price or acceptance is not yet final.

## 13. Database and transaction requirements

Use a single transaction where practical to commit:
- Order record.
- Commercial and delivery-address snapshots.
- Initial order-status history.
- Relevant audit record.
- Notification outbox event.
- Idempotency record/result association.

The transaction must preserve data integrity if any required write fails.

Do not call a remote provider while holding a transaction open. A background worker processes the outbox after commit.

For idempotency:
- Scope the key by authenticated actor and operation.
- Store a request hash or equivalent equivalence check.
- Return the original result for an equivalent duplicate.
- Reject the same key when reused with a different payload.
- Use database uniqueness constraints to protect against concurrency.

## 14. Capacity and concurrent checkout

The backend must define when capacity is reserved:
- At order-request creation, or
- At seller acceptance, or
- At another approved point in the workflow.

Whichever policy is selected, implement it transactionally and test races.

A correct solution must handle two customers attempting to order the same remaining capacity concurrently. It must not allow both to consume capacity if the business rules prohibit overselling.

Cancellation/rejection must release any reservation exactly once if the chosen capacity model reserves it.

## 15. Delivery address and privacy

- Verify that a selected saved address belongs to the customer.
- Snapshot address data according to the order confirmation contract.
- Do not expose the saved address book to the seller.
- The seller receives only the specific address needed for an accepted/eligible delivery and at the policy-defined point.
- Do not send full addresses in SMS/WhatsApp by default.
- Do not include private address data in application logs or analytics.
- Define how address changes after confirmation are handled: they must use an explicit order-change workflow if permitted, not an untracked edit to the saved address.

## 16. Error and recovery behavior

Handle:
- Unauthenticated customer.
- Invalid/unknown listing.
- Seller/listing no longer eligible.
- Insufficient capacity or incompatible unit.
- Unsupported service area/date.
- Address belongs to another user.
- Fixed-price listing has invalid pricing data.
- Quote is expired/withdrawn/superseded.
- Idempotency key reused with a different request.
- Concurrent order/capacity conflict.
- Database unavailable.
- Notification service failure after order creation.
- Payment service failure if later enabled.
- Client loses connectivity after sending the request.

A failed notification after a successfully committed order should not automatically cancel the order. Record the notification failure separately and allow safe retry.

## 17. UI requirements

Order-review page must show:
- Material and specification.
- Seller display name.
- Quantity and unit.
- Delivery address summary.
- Requested delivery date/time, if supported.
- Fixed delivered price or quote-required state.
- Applicable fees/taxes/discounts.
- Total and currency when known.
- Delivery inclusions/exclusions.
- Applicable cancellation/terms summary and links.
- Clear submit/quote-request action.

After submission:
- Display the real order/quote reference.
- Display actual state and timestamp.
- Provide a path to order/quote detail.
- Avoid displaying “payment successful” or “seller confirmed” unless true.
- Provide a safe way to check the result after a timeout.

## 18. Required tests

### Unit tests
- Price calculation and rounding.
- Fixed-price versus quote behavior.
- Quantity/unit compatibility.
- Quote expiry and acceptance.
- Snapshot mapping.
- Idempotency decision rules.
- Capacity reservation/release policy.

### PostgreSQL/API integration tests
- Valid order creation.
- Client-supplied total is ignored/rejected.
- Wrong-owner address is rejected.
- Seller/listing state is revalidated.
- Duplicate identical request returns a consistent outcome.
- Mismatched idempotency request returns a conflict.
- Required records are committed atomically.
- Transaction failure does not leave a partial order.
- Concurrent requests respect capacity constraints.
- Listing edits do not change the saved snapshot.
- Quote acceptance creates at most one valid order.
- Quote expiry prevents acceptance.
- Notification failure does not falsely change the order to failed.

### Browser tests
- Review and submit a fixed-price order.
- Request a quote from a quote-required listing.
- Review and accept a valid quote when enabled.
- Correctly display validation/conflict messages.
- Retry after a simulated network timeout without creating a duplicate.
- Verify the displayed order status matches the backend.
- Verify private data is shown only to the correct participant.

## 19. Acceptance checklist

- [ ] Checkout validates current eligibility on the server.
- [ ] One MVP order contains one seller/listing/customer.
- [ ] Bundled delivery is enforced.
- [ ] Financial totals are server-calculated.
- [ ] Quote mode is distinct from fixed-price order mode.
- [ ] Accepted terms and delivery address are snapshotted.
- [ ] Idempotency and database constraints prevent duplicate creation.
- [ ] Capacity concurrency behavior is defined and tested.
- [ ] Initial order history/audit/outbox writes are consistent.
- [ ] Private addresses are disclosed only under policy.
- [ ] Provider failures do not falsely mark the order as failed/successful.
- [ ] Main success and failure paths have automated tests.
- [ ] Unapproved fee/payment/cancellation rules remain disabled.

## 20. Completion gate

This feature is complete when the backend can create a reliable, auditable order or quote workflow with correct pricing and privacy guarantees, and the customer can understand the true status of the request. A UI confirmation alone does not constitute a successful checkout.
