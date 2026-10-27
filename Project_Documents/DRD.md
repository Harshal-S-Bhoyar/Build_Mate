# BUILD MATE — Detailed Requirements Document (DRD)

**Document ID:** BM-DRD-001  
**Version:** 1.0  
**Status:** Engineering requirements draft  
**Last updated:** 26 October 2026  
**Applies to:** BUILD MATE web frontend, ASP.NET Core API, PostgreSQL data store and integrations

---

## 1. Purpose and relationship to other documents

This document turns the business/product requirements into detailed functional, data, privacy, integration, authorization and acceptance requirements. `BRD.md` explains why the business exists; `PRD.md` defines the product outcomes and user journeys; `Architecture.md` specifies system boundaries; `Database.md` specifies persistence conventions; API, security, integration and individual feature documents define implementation details.

AI coding agents and developers must use the same domain vocabulary and statuses across frontend, API, database, tests and logs. Open business decisions must not be silently invented. Use only defaults explicitly approved in this document or record a decision for the product owner.

## 2. Non-negotiable domain rules

1. Every orderable listing is a **ready-to-deliver load: material + truck/delivery together**, provided by one seller.
2. No separate truck booking or customer-to-driver matching workflow exists in the MVP.
3. BUILD MATE is not a public supplier directory.
4. Public listing/search APIs must not expose private customer/seller phone, email, personal WhatsApp, payout data or verification documents.
5. Communication must use platform messaging or a provider-backed masked-call flow whose privacy behavior has been verified on both sides.
6. The listing seller is accountable for listing accuracy, availability, quantity/unit, specification, lawful sourcing, and delivery under the accepted order and published terms.
7. Confirmed order terms and prices are snapshotted. Later listing edits must not change already-confirmed orders.
8. Every protected operation requires server-side authentication, authorization and resource ownership checks.
9. External integrations must be replaceable through interfaces and have mock/test implementations.
10. Provider failure must never be represented as success. Ratings, verification badges, order counts and delivery estimates must be genuine.

## 3. Roles and permissions

| Capability | Customer | Seller | Admin | Support |
|---|---|---|---|---|
| Browse approved active listings | Yes | Yes | Yes | Yes |
| Create an order | Own orders | No by default | Test/support only if explicitly enabled | No by default |
| Manage profile and saved addresses | Own only | Own customer profile if also a customer; otherwise no | Need-to-know | Assigned case only |
| Manage material listings | No | Own listings only | Yes, audited | No |
| View orders | Own customer orders | Orders for own seller account only | Yes, audited | Assigned cases only |
| Change delivery status | No | Own accepted orders, allowed transitions only | Exception override, audited | No |
| View private customer contact | Own profile | No by default | Restricted, need-to-know | Limited assigned-case access |
| View private seller contact | No | Own profile | Restricted, need-to-know | Limited assigned-case access |
| Approve sellers/listings | No | No | Authorized admin only | No unless expressly delegated |
| Change fees/refunds/payout | No | No | Restricted admin role | No |
| Read audit events | No | Own relevant events only | Restricted audit role | Assigned case only |

The UI may hide unavailable actions, but authorization must be enforced by the API. Direct API calls made by unauthorized users must be tested and rejected.

## 4. Functional requirements

### 4.1 Search and discovery

- Search accepts material category, quantity, unit, delivery area/postal code, requested date, optional price range, and allowlisted sort order.
- Return only listings that are active, approved, from eligible sellers, not expired, within a matching service area, and able to fulfil the requested quantity/date under the listing's capacity rules.
- Do not infer delivery eligibility solely from seller city; service-area rules must be explicit.
- Public DTOs contain approved display data only. Never serialize persistence entities directly.
- Pagination must be stable, validated and bounded. Clients may not request unlimited results.
- Ratings and trust signals must be based on actual eligible records. No fabricated delivery estimates or counts.

### 4.2 Seller onboarding and verification

- Verify a login contact channel before enabling sensitive seller actions.
- Seller submits profile and required verification evidence defined by platform policy.
- Verification documents use private object storage and access-controlled short-lived URLs or authenticated download handlers.
- Seller verification state is distinct from seller account status and listing moderation state.
- Only currently approved sellers can publish orderable listings.
- An admin verification decision records actor, timestamp, result and reason code. Private review notes are not public.
- Final verification evidence/checklist must be confirmed with qualified advisers where identity, business, source, or transport compliance is involved.

### 4.3 Listing management

A listing must support:
- Category and material specification/grade.
- Available quantity, unit and minimum order.
- Fixed delivered price or explicit quote-required mode.
- Delivery inclusion and any excluded/additional charges.
- Service areas, available dates/capacity and lead time.
- Truck/delivery type and capacity information relevant to the offer.
- Photos, description, cancellation terms and availability status.
- Listing and moderation status; created/updated/published timestamps.

Recommended listing states: `Draft`, `PendingReview`, `Active`, `Paused`, `Rejected`, `Expired`, `Archived`. Only active, approved listings are orderable. A listing that excludes delivery is not compliant with the MVP bundled-load model and must not be published as an orderable marketplace listing.

### 4.4 Customer profiles and addresses

- Customers can create, update and delete their own saved addresses where no retention rule prevents deletion.
- A customer may have only one default address at a time. Updating default flags must be atomic.
- Orders store an address snapshot, so later address edits do not change an existing order.
- The seller receives only the delivery information necessary for a valid order and must not gain access to unrelated saved addresses.
- Coordinate collection is optional and must be explained; use data minimization.

### 4.5 Order creation and quotes

- An MVP order belongs to one customer, one seller and one listing.
- The backend rechecks listing status, seller eligibility, quantity, unit, service area, date and current price/quote rules at submission.
- The server calculates all totals, fees and discounts; client-supplied totals are never trusted.
- Order creation uses an idempotency key or equivalent uniqueness mechanism to prevent duplicates after browser/network retries.
- Store the commercial listing snapshot, agreed quantity/unit, delivered-price basis, fee breakdown, delivery-address snapshot, seller reference and accepted terms.
- A quote request is not a confirmed order until the required seller/customer acceptance steps have occurred.
- If quote mode is released, quote expiry, revision and acceptance semantics must be explicitly configured and tested.

### 4.6 Order lifecycle

Canonical states:
- `PendingSellerResponse`
- `Accepted`
- `Preparing`
- `OutForDelivery`
- `Delivered`
- `Completed`
- `Rejected`
- `Cancelled`
- `Disputed`

Minimum transition contract:

| Current state | Actor | Action | Next state |
|---|---|---|---|
| No order | Customer | Submit valid order | `PendingSellerResponse` |
| `PendingSellerResponse` | Seller | Accept | `Accepted` |
| `PendingSellerResponse` | Seller | Reject | `Rejected` |
| `PendingSellerResponse` | System/admin | Response window expires | `Cancelled` |
| `PendingSellerResponse` | Customer | Cancel if policy allows | `Cancelled` |
| `Accepted` | Seller | Start preparation/loading | `Preparing` |
| `Accepted` | Customer/system | Cancel under policy | `Cancelled` |
| `Preparing` | Seller | Dispatch load | `OutForDelivery` |
| `Preparing` | Authorized admin | Exceptional cancellation/dispute | `Cancelled` or `Disputed` |
| `OutForDelivery` | Seller | Mark delivered with required evidence | `Delivered` |
| `Delivered` | Customer/system | Confirm delivery or apply approved completion policy | `Completed` |
| `Delivered` | Customer/support | Raise an issue within the allowed window | `Disputed` |
| Eligible non-terminal state | Authorized admin | Open documented exception | `Disputed` |
| `Disputed` | Authorized admin | Resolve under approved policy | `Completed` or `Cancelled` |

Implement transitions in a central domain policy/service, not as ad hoc checks in multiple controllers. Every change records previous/next state, actor, timestamp, reason, and correlation ID. Terminal states cannot be silently reopened; any override requires a dedicated audited admin action. Product owner approval is required for exact timeout, cancellation, refund and dispute-window rules before payments are enabled.

### 4.7 Platform messaging and masked calling

- Message threads are linked to an order or approved enquiry.
- Only authorized participants—customer, relevant seller, and authorized case support—can read/write in a thread.
- Public pages never display private contacts. User-generated message content can contain contact details unless detected/moderated; do not promise complete prevention unless controls are actually implemented and tested.
- Masked calling uses a provider adapter and an order-bound session, with provider reference and call outcome logged.
- Do not enable masked calling until testing confirms that neither party sees the other's personal number in caller ID or provider callbacks.
- Call audio recording is disabled by default. Adding recording requires legal review, disclosure/consent, access controls and retention policy.

### 4.8 Notifications

- Business events create durable notification requests through an outbox or equivalent retryable mechanism.
- Provider adapters expose explicit success/failure and provider reference.
- Local/test environments use mock adapters and must not require live secrets to build or test core features.
- Retry transient failures with bounded exponential backoff. Exhausted failures become visible to authorized operations users.
- Avoid sensitive information in SMS/WhatsApp bodies; do not put OTPs, private documents or unnecessary full addresses in logs.
- Production SMS must follow applicable Indian registration/template and provider requirements.

### 4.9 Payments and fees

- Payment and order status are separate state machines.
- Monetary values use fixed-point decimal types, not binary floating point.
- Verify payment webhook authenticity and process events idempotently.
- Never store raw card details or provider secrets in application tables.
- Fee/commission is calculated server-side under a configured policy and snapshotted to the order/ledger.
- Pilot payment method, COD/UPI manual handling, cancellation, refunds, payouts and reconciliation require written approval before production financial integration.

### 4.10 Admin, reporting and audit

Audit seller approvals/suspensions, listing moderation, fee changes, order overrides, refunds/payout changes, private-document access and sensitive exports. Audit metadata must exclude credentials and unnecessary personal data. Admin/support permissions should be narrower than broad “admin can do everything” access wherever feasible.

## 5. Validation and data rules

- Use strongly typed request/response DTOs; never expose raw EF Core entities.
- Validate lengths, numeric ranges, quantity/unit compatibility, dates, enums, identifiers, addresses and state transitions at application boundaries.
- Use server-generated IDs and UTC timestamps.
- Use `decimal`/PostgreSQL `numeric` for money and quantities that need decimal precision.
- Store timestamps as PostgreSQL `timestamptz`; represent intended delivery local time/time zone explicitly when needed.
- Define enums centrally in C# and keep their API/database representation consistent.
- Use database constraints for integrity and application/domain services for cross-entity business rules.
- Protect concurrent listing-capacity and order updates with transactions and a concurrency strategy.

## 6. External integration requirements

| Integration | Required behavior |
|---|---|
| SMS gateway | Adapter interface, templates, delivery status, retry and visible errors |
| WhatsApp Business | Approved provider workflow, opt-in/consent and template rules as applicable; verify contact privacy |
| Cloud telephony | Order-bound masked call sessions and both-side caller-ID tests |
| Payments | Verified webhooks, idempotency, refunds and reconciliation records |
| Maps/geocoding | Optional; service-area/postal-code selection may be used first |
| Email | Transactional/account-support messages if required |
| Object storage | Public approved listing media separated from private verification documents |

## 7. Non-functional requirements

- Responsive and accessible UX on mobile/desktop.
- HTTPS for all production traffic.
- Least-privilege application/database identities.
- Structured logs with correlation IDs and redaction.
- Health/readiness checks that do not disclose secrets.
- Secure, size-limited and type-checked uploads.
- Rate limits for authentication, OTP, search, message and order endpoints.
- Generic safe error responses in production; no stack traces/SQL in client messages.
- Versioned EF Core migrations tested in CI.
- Separate local/staging/production credentials and secrets.
- Backup/restore process documented and tested before production.

## 8. Acceptance criteria

The controlled MVP is accepted only when:
1. A customer can search eligible delivered-load listings and submit an order on a mobile browser.
2. Seller can create/edit/pause listings with material and delivery bundled.
3. Confirmed order snapshots remain stable after listing changes.
4. Unauthorized cross-customer and cross-seller resource access is denied by the API.
5. Public listings/search never return private contact details or private document keys.
6. Illegal state transitions and client-supplied price manipulation are rejected.
7. Admin can verify sellers, moderate listings and inspect audited order history.
8. Core use cases run with mocked providers and no live credentials.
9. Provider errors are visible and never displayed as fake success.
10. Critical business/security rules have automated tests; primary flows have browser E2E tests.

## 9. Release gates

- **Gate A — Local:** documented setup works; migrations and seed data run; tests pass.
- **Gate B — Internal:** role checks, transitions, pricing snapshots, privacy and integration mocks pass.
- **Gate C — Controlled pilot:** sellers, policies, support, provider settings and privacy notices are ready.
- **Gate D — Expansion:** fulfilment/repeat-use/contribution evidence supports scaling and no critical security/privacy issues remain.

## 10. Product-owner decisions

Approve launch zone; units/specifications; fixed-price versus quote rules; login/guest checkout; seller verification evidence; seller response timeout; cancellation/dispute windows; delivery proof; pilot payment approach; commission/service fee; chosen providers; privacy/retention rules; and operational authority for refunds/overrides.
