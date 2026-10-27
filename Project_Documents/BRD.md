# BUILD MATE — Business Requirements Document (BRD)

**Document ID:** BM-BRD-001  
**Version:** 1.0  
**Status:** Draft for product-owner review  
**Last updated:** 26 October 2026  
**Working brand:** BUILD MATE (provisional; verify domain, business-name and trademark availability before committing)  
**Initial target:** One selected Nagpur-area service zone, Maharashtra, India

---

## 1. Executive summary

BUILD MATE is a proposed digital marketplace for construction materials offered as **ready-to-deliver loads**. Every marketplace listing bundles the material and its truck/delivery together under one seller. Customers search and compare available offers, place an order through BUILD MATE, receive status updates, and access support through the platform.

BUILD MATE is not intended to become a public supplier directory. Seller and customer personal contact details must not be exposed on public listings or ordinary customer-facing APIs. Order-related communication should use platform messaging or a masked-calling provider only after its caller-ID/privacy behavior has been tested end-to-end.

The first release should focus on four categories—black stone/construction aggregate, sand, bricks, and murum—in one local service area. It should be a responsive website rather than separate native mobile apps. The business hypothesis must be validated with genuine paid deliveries before significant investment in advanced technology or advertising.

## 2. Business problem

### 2.1 Customer problem
Customers, contractors, and site supervisors may need to contact multiple suppliers to compare material types, quantity/load size, total delivered price, availability, and delivery timing. Quotes may use inconsistent units or omit transportation details. Customers may also lack a clear order-status trail and a central route for raising delivery or quality issues.

### 2.2 Seller problem
Material suppliers, brick manufacturers, quarry/aggregate businesses, and traders with their own or controlled delivery capacity may rely on word-of-mouth, personal contacts, and manual order coordination. They may lack a simple digital way to publish available loads, receive qualified orders, and build a transaction-based reputation.

### 2.3 Coordination problem
Material price and transport are operationally linked. A materials-only price can mislead customers when transport is charged separately or availability differs by location. BUILD MATE therefore represents a seller's offer as **material + delivery in one listing**.

## 3. Vision and value proposition

**Vision:** Make ordering construction materials for a building site more transparent, organized, and convenient, starting locally and expanding only after the operating model is proven.

**Customer value:** Find suitable construction materials with delivery included, compare offers on understandable terms, order through one platform, and receive useful updates and support.

**Seller value:** Receive qualified enquiries/orders, publish available capacity, manage order status, and build a reputation from completed deliveries.

**Platform value:** Provide search, trust controls, order coordination, messaging, support, reporting, and potential transaction-fee revenue. The value is not merely displaying seller names; it is coordinating a trustworthy transaction.

## 4. Business objectives

1. Validate whether local customers will search for and order delivered material loads online.
2. Onboard a usable supply of active, verified sellers in a defined service area.
3. Standardize material specification, quantity/unit, delivered-price presentation, delivery area and availability.
4. Protect personal contact information and route order communication through BUILD MATE.
5. Complete and document an initial set of genuine paid deliveries.
6. Measure seller acceptance, delivery completion, repeat purchase, disputes and contribution per order.
7. Use pilot evidence to decide whether to build more automation, add integrations, or expand geographically.

## 5. Stakeholders

| Stakeholder | Responsibility / interest |
|---|---|
| Business owner | Product direction, budget, business rules, seller relationships and go/no-go decisions |
| Customers | Find, compare and order delivered loads; provide delivery details and feedback |
| Sellers/vendors | Accurate listings, material quality, quantity, availability and delivery fulfilment |
| Contractors/site supervisors | Repeat orders, delivery coordination and issue resolution |
| Operations/support | Seller verification, order exceptions, customer help and disputes |
| Developer/technical lead | Secure, testable implementation, deployment and maintenance |
| External providers | Hosting, SMS, WhatsApp, telephony, payment and storage services |
| Professional advisers | Advice on business registration, tax, privacy, consumer, telecom, material sourcing/transport and financing requirements |

## 6. Operating model

### 6.1 Seller model
A seller offers the material and delivery as one complete load. The seller may own the vehicle or control delivery through an arrangement, but the marketplace order is with the seller responsible for the complete offer. A separate truck-owner marketplace is out of scope for MVP.

### 6.2 Customer model
The customer searches by material, quantity/unit, delivery location, preferred date, and supported filters. The customer compares eligible offers and submits an order or quote request. A public listing must not reveal the seller's private phone number or personal WhatsApp contact.

### 6.3 Platform model
BUILD MATE publishes eligible listings, manages order creation and seller responses, maintains order records and status history, routes approved communications, sends notifications, supports complaints, records fees, and produces operational reports. The platform does not physically own the materials or trucks by default.

## 7. Business scope

### 7.1 MVP scope
- Responsive public website and material categories.
- Search/filter of available ready-to-deliver loads.
- Listing detail showing specification, quantity/unit, delivery area, availability, and delivered price or an explicit quote requirement.
- Customer account and delivery-address management.
- Seller onboarding, verification status and listing management.
- Single-seller order creation, seller accept/reject, and order lifecycle.
- Admin console for sellers, listings, orders, support cases and reports.
- Platform-mediated customer/seller questions and controlled contact privacy.
- Notification adapter with local mock mode.
- Audit logging for sensitive actions.
- Reviews after eligible completed orders.
- Manual operational fallback during pilot where safe and documented.

### 7.2 Out of scope
- Separate truck booking or customer-to-driver matching.
- Native Android/iOS apps, live GPS tracking or route optimization.
- AI pricing, customer credit, internal wallet or loyalty program.
- Multi-city launch before the local model is validated.
- Multi-seller shopping carts.
- Guaranteed anonymous calls before provider tests prove it.
- Automated split payouts before the financial/settlement model is approved.
- Public supplier directories or unrestricted access to seller contact information.

## 8. Non-negotiable business rules

1. **Bundled load:** Every orderable listing includes material and delivery together, with one seller accountable for the offer.
2. **Single-seller order:** An MVP order references one customer, one seller and one listing.
3. **Price clarity:** The displayed price states the quantity unit and delivery inclusion/exclusion; fees and taxes must be disclosed where applicable.
4. **Order snapshot:** Confirmed order terms and price cannot silently change when a seller edits a listing.
5. **Availability:** Only eligible, approved, active, available listings may be ordered for a matching area/date/quantity.
6. **Privacy:** No seller private phone/email/personal WhatsApp link in public listing pages or public API DTOs.
7. **Authorization:** Server-side permissions are required for every private operation.
8. **Seller accountability:** Seller is responsible for listing accuracy, lawful sourcing and delivery under agreed terms.
9. **Auditability:** Seller approvals, moderation, fee changes, order overrides and financial/dispute actions must be logged.
10. **Truthful trust signals:** No fabricated ratings, verification badges, completed-order counts, or delivery ETAs.
11. **Masked-call claims:** Do not state that a call is masked unless both parties' caller-ID experience has been verified with the provider.
12. **External failure visibility:** Failed SMS/calls/payments must not be shown as successful.

## 9. Revenue-model hypotheses

Possible models to validate:
- A disclosed commission or platform fee on completed orders.
- A transparent service fee where commercially and legally appropriate.
- Seller subscription only after recurring measurable value is demonstrated.
- Clearly marked promoted placements only if ranking remains transparent.

No particular rate is approved in this BRD. Validate seller margins, willingness to pay, customer price sensitivity, payment/communications cost, support cost, refunds and customer acquisition cost before selecting a model.

## 10. Business success measures

| KPI | Definition |
|---|---|
| Verified active sellers | Approved sellers with at least one available listing |
| Qualified enquiries | Requests containing material, quantity, delivery area and usable customer contact/consent |
| Enquiry-to-order conversion | Orders created divided by qualified enquiries |
| Seller acceptance rate | Accepted orders divided by orders sent to sellers |
| Completion rate | Completed deliveries divided by accepted orders |
| On-time delivery rate | Orders delivered within the confirmed delivery window |
| Cancellation rate | Cancelled orders divided by orders created, segmented by reason |
| Dispute rate | Orders with a formal complaint divided by attempted/completed orders, using a documented denominator |
| Repeat-customer rate | Customers with another completed order in the measurement period |
| Contribution per order | Platform revenue less variable payment, messaging, refund and order-level operating costs |
| Customer acquisition cost | Marketing spend divided by new customers completing a first order |
| Seller retention | Sellers remaining active during the measurement period |
| Privacy incidents | Confirmed unauthorized access or contact disclosure events |

Pilot targets are hypotheses to approve, not guarantees. Review the first 20–30 paid deliveries in one service zone before authorizing a larger technology or advertising budget.

## 11. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Insufficient local supply/demand | Choose one zone; interview customers and sellers; recruit active supply before broad marketing |
| Customer/seller bypass | Hide private contacts; deliver value through support, records, reviews, dispute handling and reordering |
| Stale price/availability | Show update timestamps; pause/expire stale listings; reconfirm before acceptance |
| Quantity/quality dispute | Clear units/specifications, evidence of delivery, documented claim window and resolution policy |
| Delivery failure | Response expectations, status timestamps, seller performance monitoring and suspension policy |
| Low contribution margin | Measure true per-order costs; adjust operations/fees before scaling |
| Privacy/security incident | Least privilege, DTO allowlists, audit logs, redaction, tests and incident process |
| External-provider dependency | Provider adapters, mock implementations, retries and manual fallback |
| Overspending before validation | Stage funding and use measurable go/no-go gates |
| Legal/financing uncertainty | Confirm obligations and scheme eligibility with qualified advisers and relevant authorities |

## 12. Assumptions and dependencies

- BUILD MATE is a provisional brand name until availability checks are completed.
- Exact Nagpur-area service zone remains a business decision.
- Initial categories are black stone, sand, bricks and murum.
- Backend is **ASP.NET Core on .NET 10 LTS**; database is **PostgreSQL**; data access uses **Entity Framework Core with a compatible Npgsql provider**.
- Frontend remains a responsive **Next.js + TypeScript** application unless changed by an approved architecture decision.
- The first release is a website, not native apps.
- Provider pricing/capabilities are verified before SMS, WhatsApp, masked calling, payment, maps or storage providers are selected.
- Financing/PMEGP eligibility is not assumed and must be confirmed independently.

## 13. Decisions before larger investment

1. Pilot zone and exact service-area rules.
2. Units and material specifications supported per category.
3. Fixed delivered price versus request-a-quote by category.
4. Guest checkout versus login required before ordering.
5. Pilot payment method and refund handling.
6. Commission/service-fee model and paying party.
7. Seller verification and material-source/transport evidence policy.
8. Order response timeout, cancellation window, delivery proof and dispute deadline.
9. SMS, WhatsApp and masked-calling providers and their actual privacy behavior.
10. Business entity, tax, terms, privacy, sourcing/transport obligations and brand clearance.
11. Source-code ownership, hosting access, secret ownership, backups and maintenance responsibilities.

## 14. Approval gate

Before a controlled pilot, the business owner and technical lead should approve the bundled-load model, pilot scope, seller verification, price and cancellation principles, private-contact policy, technical architecture, operational budget, and release acceptance checklist.

**BRD limitation:** This document describes intended business requirements. It does not prove product-market fit, profitability, legal/financing eligibility, or the capability of any external provider.
