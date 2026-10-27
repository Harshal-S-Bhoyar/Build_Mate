# Feature Specification 17 — Analytics and Reporting

**Document ID:** BM-FEAT-17  
**Version:** 1.0  
**Status:** Proposed analytics specification  
**Priority:** P1 — Basic operational reports after core transactions  
**Dependencies:** Listings, orders, seller onboarding, support, notification outbox and approved privacy controls

---

## 1. Purpose

Provide reliable business and operational reporting so the BUILD MATE owner can evaluate whether the marketplace is working, where fulfilment is failing and whether the local pilot is economically sustainable.

Analytics must be based on genuine persisted events and clearly defined metrics. Reports must not inflate seller counts, fabricate completed orders, treat enquiries as sales or confuse platform revenue with gross transaction value.

The initial objective is operational visibility and learning—not a large data warehouse or elaborate AI analytics platform.

## 2. Objectives

- Measure real supply, demand, order conversion and fulfilment.
- Identify slow seller responses and delivery problems.
- Monitor listing freshness and search effectiveness.
- Track support/dispute load and external-provider failures.
- Estimate contribution per completed order when financial costs are available.
- Provide role-restricted dashboards and exports.
- Use consistent metric definitions across UI, API and reporting.
- Minimize personal data in analytics.
- Support a measured pilot go/no-go decision.

## 3. Scope

### P0/P1 reporting
- Active/approved seller counts.
- Active/approved listing counts.
- Search and listing-detail activity where approved analytics exists.
- Enquiries/quote requests.
- Orders by authoritative state.
- Seller response and acceptance.
- Completion, cancellation and delivery status.
- Support tickets and disputes.
- Notification/provider failures.
- Basic date/category/area summaries.

### Later reporting
- Customer acquisition cost.
- Repeat-customer behavior.
- Contribution margin per order.
- Seller retention/cohort analysis.
- Payment/refund/commission reconciliation reports.
- Controlled export and scheduled summaries.
- Advanced trend analysis after sufficient reliable data exists.

### Out of scope
- Selling personal data.
- Unrestricted tracking of customer behavior.
- Treating inferred or sampled analytics as exact transactional counts without disclosure.
- Predictive ranking/credit decisions in MVP.
- Storing full message bodies or private addresses in analytics events.

## 4. Reporting principles

1. **Authoritative transaction data first:** Orders, payments and seller records are the source of truth for transactional reports.
2. **One definition per metric:** Write the formula, inclusion rules, denominator and time window.
3. **No fabricated data:** Demonstrations must be explicitly synthetic.
4. **Metric state matters:** Created orders, accepted orders and completed deliveries are different outcomes.
5. **Privacy by design:** Aggregate whenever individual-level data is unnecessary.
6. **Reproducibility:** A report generated twice for the same data/window should follow the same calculation.
7. **Bounded queries:** Reporting must not accidentally scan or export the entire production database from a dashboard page.
8. **Access control:** Seller reports are seller-scoped; admin reports follow specific permissions.
9. **Separate business events from technical logs:** Access logs alone are not an authoritative sales ledger.
10. **Cost-aware implementation:** Start with PostgreSQL queries/views and add a separate analytics platform only when justified.

## 5. KPI definitions

The owner and engineering lead must approve the exact definitions before using the values for business decisions. The following are proposed definitions.

### 5.1 Active verified sellers
Count distinct seller profiles that:
- Have the required verification approval.
- Have an eligible operational state.
- Have at least one eligible active listing, if the metric is specifically called “active sellers with supply”.

Do not mix approved sellers with sellers who have not published an orderable offer.

### 5.2 Active listings
Count listings meeting the approved public eligibility rule at the measurement point:
- Active.
- Approved/moderated as required.
- Belonging to an eligible seller.
- Not expired/removed.
- Compliant with bundled delivery requirements.

If availability freshness is enforced, include that condition in the metric definition.

### 5.3 Qualified enquiries
Count enquiries that meet a documented minimum information criterion, such as material/listing, quantity/unit, delivery area and permitted response destination. This metric must not equate every click or blank message with a qualified enquiry.

### 5.4 Order conversion
Possible funnel metrics:
- Search-to-listing-detail: eligible listing-detail views divided by search sessions/requests under a documented analytics definition.
- Enquiry-to-order: orders created divided by qualified enquiries in a stated cohort/time window.
- Submitted-to-accepted: seller-accepted orders divided by eligible submitted orders.
- Accepted-to-completed: completed orders divided by accepted orders in the defined cohort.

Do not mix numerator and denominator populations across incompatible time windows without explaining the method.

### 5.5 Seller response time
Measure the elapsed time between the authoritative order-request timestamp and the first valid seller response, excluding or separately reporting policy-defined cases such as expiry/cancellation without a seller response.

Report median and percentile measures where useful; a simple average can be distorted by old unresolved records.

### 5.6 Completion rate
Use a documented cohort and denominator. A possible measure is completed orders divided by accepted orders in the same defined cohort, with cancellation/dispute handling explicitly specified.

Do not silently exclude failures to make the rate look better.

### 5.7 On-time delivery rate
Only calculate this when the platform has a reliably confirmed agreed delivery window. Compare actual recorded delivery time against that window. Label estimates separately and do not claim an on-time rate when the underlying data is incomplete.

### 5.8 Cancellation rate
Count cancellations by order cohort and group by reason/actor. State whether the denominator is submitted, accepted or another order population.

### 5.9 Dispute rate
Count orders with an eligible dispute under a documented policy and use a defined denominator, such as completed orders or orders accepted in the same cohort. Include time window and treatment of reopened disputes.

### 5.10 Repeat-customer rate
Count customers with more than one qualifying completed order in a defined cohort and measurement period. Do not count repeat logins or quote requests as repeat purchases.

### 5.11 Contribution per order
Where sufficient financial data exists, calculate platform revenue attributable to an order minus defined variable costs, such as payment processing, messaging, refunds and order-level operating expense.

This is not the same as gross order value. Document which costs are included, which are excluded and the limitations of estimates.

## 6. Data sources

Potential authoritative sources:
- Identity/user records.
- Seller profiles and verification state.
- Listings and moderation state.
- Search/application analytics events where approved.
- Orders and status history.
- Payments/refunds/fee ledger, when enabled.
- Support tickets/disputes.
- Notification outbox and provider outcomes.
- Audit events for operational/security reporting.

Use a stable event or transaction reference to link reports where needed. Avoid placing private message contents, raw contact numbers or full addresses in the analytics data layer.

## 7. Event tracking

If product analytics events are implemented, define an explicit event catalogue. Candidate events:
- `search_submitted`
- `listing_detail_viewed`
- `enquiry_created`
- `quote_requested`
- `order_submitted`
- `order_accepted`
- `order_rejected`
- `order_dispatched`
- `order_marked_delivered`
- `order_completed`
- `order_cancelled`
- `support_ticket_created`

These events are examples, not proof that a product analytics provider has been selected.

### Event requirements
Each event should have:
- Stable name and schema/version.
- Timestamp.
- Environment.
- Correlation/session reference as appropriate.
- Listing/order/category reference where needed.
- Minimal, documented properties.
- Data classification.
- Source (frontend/backend/system).
- Retention period.
- Approved purpose.

Transactional events should be emitted from the authoritative backend rather than trusting the browser to report order completion.

## 8. Privacy and analytics collection

- Do not capture passwords, OTPs, cookies or auth tokens.
- Do not include private phone/email/full-address data unless a specific justified use has been approved.
- Avoid recording entire message bodies.
- Minimize or pseudonymize user identifiers where individual analysis is not required.
- Define retention and deletion/aggregation behavior.
- Evaluate whether analytics cookies or third-party trackers require consent/notice under the actual deployment and applicable rules.
- Restrict access to raw event-level data.
- Use aggregated reports for broad business monitoring whenever possible.
- Do not re-purpose operational/security logs for broad behavioral analytics without policy review.

## 9. Reporting architecture

### MVP
Start with bounded PostgreSQL queries and/or reviewed database views over authoritative transactional tables. Use efficient indexes based on measured query plans.

For recurring reports:
- Define the owner and schedule.
- Capture the report window and metric definitions.
- Avoid duplicate or overlapping totals.
- Record job status/failures.
- Keep generated exports protected and time-limited.

### Later growth
A separate analytical store or warehouse may be considered when operational reporting creates measurable performance or governance issues. Document the migration strategy and source-of-truth boundaries in an ADR.

Do not introduce a large data platform or Redis only because analytics is included in the feature list.

## 10. Proposed API/reporting surface

Potential restricted routes:
- `GET /api/v1/admin/reports/overview`
- `GET /api/v1/admin/reports/orders`
- `GET /api/v1/admin/reports/listings`
- `GET /api/v1/admin/reports/sellers`
- `GET /api/v1/admin/reports/support`
- `GET /api/v1/admin/reports/notifications`
- `GET /api/v1/sellers/me/reports/overview` — seller-scoped, if approved.
- Export endpoints only when privacy/access and retention rules are approved.

Every report must:
- Validate date range and filters.
- Apply explicit permission checks.
- Use bounded result sizes.
- Return the metric definition/time window.
- Avoid sensitive fields not necessary for the report.
- Identify incomplete/unavailable data instead of silently rendering zero.

## 11. Dashboard requirements

### Owner/admin overview
Focus on operational questions:
- Is there enough live supply for the pilot area?
- Are customers searching and submitting meaningful requests?
- Are sellers responding?
- Are orders being accepted and completed?
- Are cancellations/disputes rising?
- Are notifications or providers failing?
- Is the business contribution positive under the approved cost model?

### Seller reports
May include:
- Own listing state.
- Own incoming-order counts.
- Own response/acceptance/completion summaries.
- Own eligible reviews.
- Own permitted fee/settlement summaries when financial features are enabled.

Sellers must not see another seller's private performance or order/customer data.

### Support reports
May include counts by category, status, priority, response time and resolution time. Restrict access to actual ticket contents and personal details.

## 12. Date, timezone and cohort behavior

- Store timestamps in UTC.
- Accept and validate explicit reporting periods.
- Display the timezone used for human-readable reports.
- Define whether date boundaries are inclusive/exclusive.
- Use a consistent reporting timezone for operational day/week summaries.
- Specify cohort logic when numerator/denominator events happen on different days.
- Avoid double-counting reopened/retried events.
- Do not assume a record belongs in a period solely because an asynchronously generated report ran during that period.

## 13. Data quality and reconciliation checks

Monitor conditions such as:
- Completed orders missing required status history.
- Listing active while seller eligibility is invalid.
- Notification outbox items stuck in an unexpected state.
- Duplicate transaction/provider event references.
- Financial totals that do not reconcile.
- Invalid/missing timestamps or units.
- Public KPI aggregation includes unapproved/rejected records.
- Analytics event appears successful but authoritative transaction state is not successful.

Treat data-quality errors as visible exceptions. Do not silently patch the source records to make dashboard charts look consistent.

## 14. Performance

- Paginate table/report endpoints.
- Bound requested date ranges and export size.
- Use indexes and reviewed queries.
- Avoid recalculating expensive global aggregates on every dashboard refresh if pilot traffic grows.
- Cache only when measured need and a clear invalidation strategy exist.
- Use background jobs for large export/report generation.
- Time out or cancel expensive requests safely.
- Restrict queries by seller/user scope before returning results.
- Use read-only database access for reporting where the architecture supports it.

## 15. Error handling

Handle:
- Invalid date range.
- Excessive period/query.
- Unauthorized report.
- Incomplete underlying data.
- Database timeout/unavailability.
- Background report job failure.
- Export expiry.
- Report schema/version changes.
- Provider/financial data not enabled.
- Missing or contradictory KPI inputs.

If a report cannot be computed reliably, return an explicit error/availability state rather than a plausible-looking zero.

## 16. Required tests

- KPI formulas with known synthetic data.
- Status/state inclusion rules.
- Denominator/cohort correctness.
- Duplicate/reopened event behavior.
- Seller report isolation.
- Admin/report authorization.
- Date-boundary and timezone behavior.
- Empty/incomplete data handling.
- Export size/access limits.
- Private data absent from report DTOs.
- Query pagination and representative query performance.
- Financial/ledger reports reconcile with authoritative source records when enabled.

## 17. Acceptance checklist

- [ ] KPIs have documented formulas and denominators.
- [ ] Transactional counts use authoritative sources.
- [ ] Search/behavior events have approved schemas if enabled.
- [ ] Privacy minimization and retention are defined.
- [ ] Admin and seller reports are appropriately scoped.
- [ ] Date/timezone/cohort rules are explicit.
- [ ] Dashboard handles missing/incomplete data honestly.
- [ ] Financial metrics separate gross transaction value from platform contribution.
- [ ] Reports are bounded and performance-tested.
- [ ] Access/export controls pass security tests.
- [ ] Operational data-quality alerts are defined.

## 18. Completion gate

Analytics is complete when key reports are reproducible, metrics use documented definitions, role boundaries are enforced, and decision-makers can distinguish real completed business outcomes from clicks, requests, estimates and synthetic test data.
