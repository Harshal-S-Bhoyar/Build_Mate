# BUILD MATE — Product Requirements Document (PRD)

**Document ID:** BM-PRD-001  
**Version:** 1.0  
**Status:** Draft for product-owner and engineering review  
**Last updated:** 26 October 2026  
**Product:** Responsive marketplace for ready-to-deliver construction-material loads

---

## 1. Executive summary

BUILD MATE is a responsive web marketplace where customers discover and order construction materials as one complete **material + truck/delivery** offer. Each seller is responsible for the material and the delivery. Customers compare offers by category, quantity, service area, availability, material specification, trust signals and delivered price. BUILD MATE manages ordering, seller response, status updates, support, controlled communication, fees and reviews.

BUILD MATE must not become a public supplier directory. Seller and customer private contact details are not displayed on public listings. Communication should use platform messaging or a masked-calling provider only after caller-ID privacy has been verified end-to-end.

The MVP targets one selected Nagpur-area service zone and four initial material categories: black stone, sand, bricks and murum. It is a responsive website; native mobile apps and advanced fleet technology are deferred.

## 2. Product problem

Customers often contact several suppliers to compare material type, quantity, load size, price, transport and delivery availability. Quotes may not use consistent units, and the buying journey may lack status visibility and a central issue-resolution path. Sellers with material and delivery capacity may rely on personal networks and manual coordination.

BUILD MATE aims to reduce these frictions through comparable delivered-load listings and a controlled transaction flow. The business hypothesis must be validated through genuine enquiries and paid deliveries before significant expansion.

## 3. Product goals

1. Help customers find suitable loads by material, quantity/unit, location and preferred date.
2. Present a clear delivered price or clearly labelled quote workflow before confirmation.
3. Let eligible sellers create and manage bundled material-plus-delivery listings.
4. Keep private contact information protected while enabling useful order communication.
5. Provide a traceable order lifecycle and useful status notifications.
6. Give admins tools for seller verification, listing moderation, complaints and exceptions.
7. Measure conversion, seller acceptance, fulfilment, repeat use, disputes and contribution per order.
8. Launch locally and expand only after evidence supports it.

## 4. Non-goals for MVP

- Separate truck booking or customer-to-driver matching.
- Native iOS/Android apps, live GPS tracking or route optimization.
- AI pricing, credit, internal wallet, loyalty or advanced promotions.
- Multi-seller carts or multi-city rollout before local validation.
- Guaranteed anonymous calls before the selected provider is tested.
- Public supplier phone directory.
- Automatic split payouts before payment and accounting rules are approved.

## 5. Personas and needs

| Persona | Primary need | Product response |
|---|---|---|
| Individual/home builder | Find a reliable delivered load at a clear total price | Simple search, clear units/prices and support |
| Contractor/site supervisor | Compare options, repeat orders and coordinate site deliveries | Filters, saved addresses, order history and updates |
| Seller with material and truck | Receive qualified orders and maintain availability | Seller dashboard, listing controls and order inbox |
| Admin/operations | Maintain quality and resolve exceptions | Verification/moderation queues, order console and reports |
| Support agent (optional) | Help with assigned issues without broad data access | Case-scoped order and communication access |

## 6. Product principles

- **Bundled load first:** material and delivery are one offer from one seller.
- **Trust, not directory:** customers compare sellers without seeing private contact details.
- **Price clarity:** unit, quantity, inclusions, exclusions, taxes/fees and quote conditions are explicit.
- **Mobile-first:** core workflows work on common Android browsers and narrow screens.
- **Manual-first:** safe manual operations are acceptable during pilot; automate after validation.
- **Local liquidity:** focus on one service area with enough actual availability.
- **Privacy by design:** data minimization and server-side authorization.
- **No fabricated trust:** ratings, verification and delivery estimates must be based on real records.

## 7. MVP feature priorities

### P0 — Required for controlled pilot
- Responsive homepage and material-category navigation.
- Search/filter by material, quantity/unit, delivery area/date and supported sorting.
- Listing detail showing specification, delivered-price/quote basis, availability and delivery inclusion.
- Customer account/login strategy and address management.
- Seller onboarding and verification status.
- Seller ability to create, edit, pause and manage listings.
- Single-seller order submission and immutable terms/price snapshot.
- Seller accept/reject and allowed order-status transitions.
- Admin console for users, sellers, listings, orders and complaints.
- Server-side access control and private-contact protection.
- Platform-mediated enquiry/support flow.
- Audit logs for sensitive operations.
- Automated tests for core domain rules and privacy boundaries.

### P1 — Add after P0 passes
- SMS via a provider adapter and compliant templates.
- WhatsApp Business notifications with appropriate permissions/opt-in.
- Masked calling after provider caller-ID tests.
- Payment gateway, refunds, reconciliation and payout workflow.
- Ratings/reviews from eligible completed orders.
- Proof-of-delivery uploads and downloadable order receipts/invoices where appropriate.
- Basic seller performance and operational reports.

### P2 — Deferred
- Live GPS, routing, native apps, AI pricing, map-heavy search, multi-city scaling, loyalty, credit, advanced seller plans and complex settlement automation.

## 8. Page and screen requirements

### 8.1 Homepage
Suggested headline: **“Construction Materials Delivered to Your Site.”**
- Material, quantity/unit, delivery-location and preferred-date search controls.
- Category tiles for black stone, sand, bricks and murum.
- Primary CTA: **Search Available Loads**.
- Trust strip: verified sellers, delivery included, transparent delivered price, updates and platform support.
- Seller sign-up CTA and links to help, terms and privacy.

### 8.2 Search results
Each card includes material photo/specification, seller display name, approved verification badge, quantity/load size, unit, delivered price or “Request a quote”, availability, service area, delivery window and genuine rating data if available. Actions include View Details, Order/Request Quote and Ask a Question. “Call via Platform” is shown only after masked calling is active and validated. Never render seller phone, private email or personal WhatsApp links.

### 8.3 Listing detail
Show material specification, images, load size, supported unit, delivered-price basis, included/excluded charges, service area, minimum order, lead time/date availability, cancellation terms, seller trust information and platform-mediated support.

### 8.4 Customer area
- Profile and verified login channel.
- Saved delivery locations.
- Current/past orders and order-detail timeline.
- Price/terms snapshot, receipt and delivery evidence where applicable.
- Message/support, eligible review and complaint actions.
- Reorder flow that revalidates current listing price and availability.

### 8.5 Seller area
- Verification status and required next actions.
- Listing statuses: draft, pending review, active, paused, rejected, expired.
- Add/edit/pause listing form.
- Incoming orders and response deadline.
- Order details and allowed status actions.
- Completed-order and feedback summary.
- Fee/earnings information only when commercial rules are approved.

### 8.6 Admin area
- Seller verification queue and document review.
- Listing moderation/report queue.
- User and seller account controls.
- Order search, status history, delayed orders, cancellations and disputes.
- Fee/commission configuration with restricted permissions and audit logs.
- Notification/provider failures and retry visibility.
- Operational KPIs and privacy-controlled exports.

## 9. Primary customer journey

1. Choose material, quantity/unit, delivery area and desired date.
2. Backend returns only active, approved, available loads that can serve the requested area/quantity/date.
3. Compare offers and open a listing.
4. Review material, delivered price, delivery inclusions, cancellation terms and seller trust data.
5. Authenticate/verify if required and submit order or quote request.
6. Backend recalculates price and validates listing availability; a single-seller order is created with a commercial snapshot.
7. Seller accepts/rejects; customer receives status.
8. Seller marks preparation/loading, out-for-delivery and delivered.
9. Customer confirms delivery or raises an issue under the published policy.
10. Eligible completed order can be reviewed and reordered.

## 10. Primary seller journey

1. Register and verify login contact channel.
2. Provide seller profile and required verification information.
3. Receive admin approval as required.
4. Publish a bundled material+delivery listing with correct unit, price basis, service area, capacity and availability.
5. Receive an order and accept/reject it.
6. Update status and provide delivery evidence when required.
7. Review completed orders, fees and feedback.

## 11. Canonical product states

Recommended listing states: `Draft`, `PendingReview`, `Active`, `Paused`, `Rejected`, `Expired`, `Archived`.

Recommended order states: `PendingSellerResponse`, `Accepted`, `Preparing`, `OutForDelivery`, `Delivered`, `Completed`, `Rejected`, `Cancelled`, `Disputed`.

Payment status is independent: `NotRequired`, `Pending`, `Authorized`, `Paid`, `Failed`, `PartiallyRefunded`, `Refunded`, `Cancelled`.

All states and transitions must be defined centrally in the backend. UI controls must reflect the current state but cannot replace server-side validation.

## 12. Pricing and order integrity

- Use fixed-point decimal values for amounts and quantities where fractional values are allowed.
- Use INR as the initial currency, but keep currency explicit in persisted price records.
- Backend calculates totals, fee and discounts; ignore client-supplied totals.
- Confirmed order snapshots include the listing identity, seller, material details, quantity/unit, price basis, delivery terms, fee/tax breakdown, delivery address and applicable terms.
- Listing edits cannot silently affect a confirmed order.
- If quote mode is used, quote expiry, revisions and acceptance semantics must be specified before release.

## 13. Security, privacy and trust

- Private phone numbers, email addresses and personal WhatsApp links are never included in public DTOs.
- API authorization is server-side and resource-scoped.
- Exact delivery address is disclosed only to authorized parties for the specific order under the published policy.
- Verification documents remain private, with access-controlled delivery.
- Admin actions are audited; logs redact secrets and unnecessary personal information.
- Masked calling and WhatsApp behavior are tested with real test accounts/devices before the product promises number privacy.
- Terms, privacy, seller, cancellation/refund and complaint policies must be published before pilot.

## 14. Notifications and integrations

Use domain/application events and a durable outbox or equivalent retryable mechanism. Start with mock providers in local development. Core events: order received, seller accepted/rejected, cancellation, preparing/loading, out-for-delivery, delivered/completed, support ticket received and payment status changes. OTPs and sensitive addresses/documents must not be sent in ordinary notification bodies.

A provider failure must be visible and must not be reported as success. Production messaging requires provider configuration and applicable Indian messaging registration/template checks.

## 15. Monetization hypotheses

The primary hypothesis is a disclosed platform fee or commission on completed orders. Alternatives such as service fees or seller subscriptions can be tested later. Fee amount and paying party are not finalized. The implementation must support a configurable policy and record the exact fee applied to each order once the business owner approves the model.

## 16. Metrics

Track search-to-detail rate, qualified enquiry-to-order conversion, seller acceptance rate/response time, completion/on-time rates, cancellations, disputes, repeat customers, active verified sellers, listing freshness, contribution per order, customer acquisition cost and privacy incidents.

## 17. Release acceptance criteria

MVP may enter a controlled pilot when:
- Customer can search and order an eligible bundled load from a mobile browser.
- Seller can manage listings and update permitted order states.
- Order price/terms snapshots remain stable after listing changes.
- Cross-customer/cross-seller access tests pass.
- Public responses do not leak private contact fields or verification documents.
- Admin can moderate sellers/listings and inspect order history.
- External providers have mock adapters, and failures remain visible.
- Core rules have automated tests and critical journeys have browser E2E tests.
- Support, cancellation and privacy policies are ready.

## 18. Product-owner decisions

Approve: service zone; supported units/specifications; fixed price vs quote per category; guest checkout/login requirement; pilot payment method; fee model and payout timing; verification evidence; seller response timeout; cancellation/dispute windows; providers for SMS/WhatsApp/calling/payments; and source-code/hosting ownership.

**PRD role:** This document describes what the product should accomplish and what users should experience. It does not claim the product is implemented or that the market opportunity is proven.
