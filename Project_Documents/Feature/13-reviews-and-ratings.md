# Feature Specification 13 — Reviews and Ratings

**Document ID:** BM-FEAT-13  
**Version:** 1.0  
**Status:** Proposed specification  
**Priority:** P1 — After completed orders  
**Dependencies:** Features 03, 06, 07 and admin moderation

---

## 1. Purpose

Allow eligible customers to share feedback about a seller after a genuine completed BUILD MATE order. Reviews help future customers assess fulfilment experiences, but the system must not fabricate ratings, overstate verification, or imply that every review proves material quality.

Reviews should be traceable to real order history and subject to a documented moderation and privacy policy.

## 2. Outcomes

- Eligible customers can rate a completed order/seller.
- Each order follows a documented review-counting rule.
- Public ratings are computed from eligible, non-hidden records.
- Review content is moderated under a documented process.
- Sellers can see permitted feedback about their own transactions.
- No user can create a review for an unrelated order.
- Rating statistics are consistent and testable.
- Private order/customer details are not accidentally revealed by a review.

## 3. Scope

### Included
- Rating submission.
- Optional text review.
- Review eligibility validation.
- Review persistence linked to an order and seller.
- Public approved-review listing.
- Seller's own review summary.
- Moderation/reporting workflow.
- Rating-average/count calculation.
- Duplicate and unauthorized submission protection.
- Tests for eligibility, privacy and aggregation.

### Excluded
- Anonymous review system without an approved identity model.
- Paid or incentivized review manipulation.
- Publicly exposing private customer profiles.
- Automatically treating a high rating as proof of material certification.
- AI-generated reviews presented as genuine customer opinions.
- Unmoderated review edits/deletions without a documented rule.
- Reviews unrelated to a completed marketplace transaction.

## 4. Review eligibility

A review may be created only when:
- Caller is authenticated.
- The order exists and belongs to the customer.
- Order is in the approved completed state.
- The seller is the seller associated with that order.
- Review eligibility window, if any, remains open.
- No review already exists for the same order under the one-review-per-order policy.
- The order was not a test/fake record excluded by the review policy.

Use server-side checks. Do not trust a client-submitted `sellerId` or claim that an order is completed.

The baseline recommendation is one customer review per completed order. If edits are allowed, define the edit window, moderation implications and audit behavior.

## 5. User stories

### BM-REV-01 — Submit a review
As a customer who completed an order, I want to rate my seller and optionally leave feedback.

Acceptance:
- Rating is an integer from 1 to 5.
- Review text is optional and length-limited.
- The backend checks order ownership and eligibility.
- Duplicate reviews are rejected or handled under the approved update rule.
- Submission receives a real persisted status.

### BM-REV-02 — Read public reviews
As a prospective customer, I want to see genuine approved feedback associated with a seller.

Acceptance:
- Only approved/publicly eligible reviews are shown.
- Reviewer identity is displayed under an approved privacy-safe policy.
- Private address/order notes are not exposed.
- Summary rating/count reflects the correct eligible records.

### BM-REV-03 — Report a review
As a user, I want to report a review I believe is abusive, fraudulent or inappropriate.

Acceptance:
- The report identifies the review and reason.
- Reporting does not itself silently prove that the content is false.
- An authorized moderator can investigate.
- The decision is recorded.

### BM-REV-04 — View seller feedback
As a seller, I want to see feedback relevant to my completed transactions.

Acceptance:
- Seller can view only permitted review information for their own seller profile.
- Customer private contact data is not revealed.
- Seller response, if added later, follows a separate moderation/length policy.

## 6. Data model

Use the conceptual `reviews` table in `Database.md` with fields such as:
- Review ID.
- Order ID, unique under the baseline one-review-per-order rule.
- Customer user ID.
- Seller ID.
- Rating.
- Optional review text.
- Moderation status.
- Created/updated timestamps.

Add relevant fields if an approved edit/moderation process requires them:
- Submitted/edited version.
- Review visibility state.
- Moderator/reviewer reference.
- Report count or linked reports.
- Moderation decision timestamp and safe reason code.

Do not store a free-form internal moderation note in a field that is returned to the public.

## 7. Rating aggregation

Define the public rating from eligible review records only.

Recommended default:
- Include only reviews in the public approved state.
- Exclude rejected/hidden/pending reviews.
- Use a consistent rounding/display rule.
- Display rating count alongside the average.
- Show no rating or an explicit “No reviews yet” when there are no eligible records.

The product owner should confirm how a seller's historical rating behaves when a review is hidden, appealed, or restored. The aggregation and visible counts must follow that rule consistently.

Avoid cached summary fields unless their update/repair strategy is tested. If an aggregate is stored on the seller profile for performance, provide a reliable recalculation path and ensure it cannot drift silently.

## 8. Review content and moderation

### Content rules
- Enforce a documented maximum text length.
- Treat text as untrusted input and render it safely.
- Disallow executable HTML/script behavior.
- Provide a reporting path for abuse or personal information.
- Avoid exposing telephone numbers, email addresses, private addresses or unrelated customer details.
- Publish a concise review policy defining prohibited content and moderation criteria.

Do not automatically delete legitimate critical feedback merely because it is negative.

### Proposed moderation states
- `Pending`
- `Approved`
- `Rejected`
- `Hidden`

The implementation must define whether review publication is immediate or pending moderation by default. Choose one policy and document the trade-offs. Do not mix both behaviors without a clear rule.

## 9. API contract

Potential routes:
- `POST /api/v1/orders/{orderId}/reviews`
- `GET /api/v1/sellers/{sellerId}/reviews`
- `GET /api/v1/customers/me/reviews`
- `POST /api/v1/reviews/{reviewId}/reports`
- `PATCH /api/v1/reviews/{reviewId}` — only if customer edits are approved.
- Restricted admin routes for review moderation.

API requirements:
- Authenticate write operations.
- Verify order ownership and eligibility.
- Validate rating and review text on the server.
- Return approved public DTOs only.
- Use stable pagination and bounded page sizes.
- Prevent a client from changing the seller/order relationship.
- Restrict moderation actions to authorized roles.
- Create audit records for privileged moderation decisions.

## 10. Public review DTO and privacy

Public reviews may show:
- Rating.
- Approved review text.
- Approved display name or privacy-preserving reviewer label.
- Review date/time in the selected format.
- Whether moderation/publication is complete, if relevant and appropriate.

Do not display:
- Customer phone/email.
- Full address or site coordinates.
- Private message threads.
- Full delivery details.
- Payment data.
- Internal support/dispute notes.
- Private document references.

A review may be linked to a verified completed order internally without publicly exposing the order reference or its sensitive details.

## 11. Seller response policy

A public seller reply is optional and should not be included unless a product owner approves:
- Whether replies are allowed.
- Maximum reply count/edit rules.
- Moderation and reporting controls.
- Private-information prohibitions.
- How replies appear on the public listing.

If seller replies are implemented, they must not expose the customer's private contact information or publish unrelated delivery details.

## 12. Abuse and fraud controls

Consider:
- One review per eligible order.
- Order completion eligibility.
- Rate limiting.
- Duplicate detection.
- Report workflow.
- Moderation audit trail.
- Review edit controls.
- Monitoring for suspicious patterns.
- Clear handling of cancelled, refunded or disputed orders.

Do not invent an automated fraud score or automatically suppress users solely on an undocumented heuristic.

## 13. Error and edge cases

Handle:
- Order not found.
- Order belongs to another customer.
- Order not completed.
- Review window expired if configured.
- Review already exists.
- Rating outside 1–5.
- Review text too long.
- Duplicate request.
- Review later hidden/rejected.
- Seller changes account status.
- Aggregate refresh fails.
- Report submission repeated.
- Public review endpoint unavailable.

A failed moderation/aggregation update must not produce a false public rating.

## 14. Required tests

### Unit tests
- Rating bounds.
- Review-text validation.
- Eligibility policy.
- Public aggregation calculations.
- Moderation-state transitions.
- Privacy-safe DTO mapping.

### Integration tests
- Eligible customer can submit one review for a completed order.
- Unrelated customer cannot review the order.
- Incomplete/cancelled order is rejected unless approved policy explicitly allows it.
- Duplicate review is handled correctly.
- Hidden/rejected review is excluded from public aggregate.
- Seller cannot alter customer ratings directly.
- Review report is restricted and audited.
- Public DTO excludes private order/customer fields.
- Aggregate count/average remain correct after moderation changes.

### Browser tests
- Customer sees review option for an eligible order.
- Customer submits a valid review.
- Ineligible orders show no usable submission action.
- Review validation errors are accessible.
- Public seller page displays the actual approved aggregate.
- No fake rating or “verified purchase” claim appears without supporting data.

## 15. Acceptance checklist

- [ ] Reviews require an eligible completed order.
- [ ] Rating range and text limits are enforced server-side.
- [ ] Duplicate/edit policy is documented.
- [ ] Moderation states are defined and consistently applied.
- [ ] Aggregate includes only eligible public reviews.
- [ ] Public display uses safe reviewer identity rules.
- [ ] Reports and moderation are permissioned.
- [ ] No fake reviews/rating statistics are generated.
- [ ] Privacy and abuse tests pass.
- [ ] Seller/customer views display accurate data.

## 16. Completion gate

Reviews are complete when only eligible, genuine transaction-linked reviews can influence public ratings, the aggregation matches moderation policy, and public display does not reveal private customer/order data.
