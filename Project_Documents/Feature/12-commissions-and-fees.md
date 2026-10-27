# Feature Specification 12 — Commissions and Platform Fees

**Document ID:** BM-FEAT-12  
**Version:** 1.0  
**Status:** Proposed specification; fee model pending product-owner approval  
**Priority:** Planned — before collecting platform fees  
**Dependencies:** Features 06–07 and 11, financial audit/ledger foundations

---

## 1. Purpose

Define how BUILD MATE configures, calculates, records and reports platform commissions or service fees associated with marketplace orders.

This feature does not choose the commercial model on behalf of the business owner. Its purpose is to support a clear, configurable and auditable model once the owner has approved who pays the fee, when it applies, how it is calculated and how it relates to settlement/refunds.

A fee must never appear unexpectedly at checkout, be silently changed after order confirmation or be calculated differently in the customer UI and backend.

## 2. Objectives

- Support an explicitly approved fee policy.
- Calculate applicable fees on the backend.
- Snapshot the applied fee rule on the order/financial record.
- Make the fee visible to the relevant party where required by policy.
- Prevent unauthorized fee-policy changes.
- Maintain traceable financial records for reporting and reconciliation.
- Handle cancellation, refunds and adjustments without erasing historical fee decisions.
- Keep fee calculation separate from payment collection and seller payout execution.

## 3. Scope

### Included
- Configurable fee-policy model.
- Effective dates and activation/deactivation.
- Server-side fee calculation service.
- Fee snapshot on applicable order/ledger records.
- Administrative fee management with restricted authorization.
- Fee display in appropriate checkout/summary screens.
- Refund/cancellation adjustment rules once approved.
- Audit, reporting and automated calculation tests.

### Excluded until separately approved
- A specific commission percentage.
- A specific fixed service fee.
- Automated seller payouts.
- Complex tiered subscriptions.
- Negotiated per-seller contracts.
- Promotional discounts or fee waivers without an approved policy.
- Changing fees retroactively for confirmed orders.

## 4. Commercial decisions required

Before production fees are enabled, the product owner must decide:

1. What the fee represents: commission, customer service fee, seller subscription, or another charge.
2. Who pays it: customer, seller or an explicitly defined split.
3. The fee basis: item/material amount, delivered order total, another defined base, or a combination.
4. Whether a fixed amount, percentage or combination applies.
5. Whether taxes apply to the fee and how amounts are presented.
6. When the fee is earned or payable.
7. How partial/complete cancellations and refunds affect the fee.
8. Whether different approved categories or seller groups use distinct policies.
9. How rounding works.
10. Whether fee-policy changes require additional notice/acceptance.
11. Whether a fee is invoiced, deducted from settlement, charged separately or recorded as a receivable.
12. Which staff may configure, approve and publish a new policy.

Do not hardcode a percentage in a controller, UI component, database default or AI-generated fixture.

## 5. Supported model options

The application may be designed to support one of the following after approval:

### Option A — Percentage commission
A percentage applies to a defined eligible base. The exact base and treatment of delivery/tax/discount amounts must be specified.

### Option B — Fixed platform fee
A defined amount applies under a documented set of conditions.

### Option C — Hybrid
A fixed amount and percentage both apply under an approved formula.

### Option D — Seller subscription
A seller pays a recurring fee for access or services. This introduces billing/renewal/cancellation requirements and should not be enabled without a separate subscription specification.

The initial MVP should implement only the selected model and avoid unused complexity.

## 6. Fee policy model

A proposed `fee_policies` record may contain:
- Policy ID.
- Policy name and internal description.
- Fee type.
- Optional percentage/rate.
- Optional fixed amount.
- Currency if applicable.
- Effective-from and optional effective-to timestamps.
- Active/draft state.
- Applicable order/category/seller scope if approved.
- Created/updated by user.
- Creation/update timestamps.
- Version or audit reference.

The exact schema must match the chosen formula and scope. Avoid a generic free-form JSON rule engine unless there is a demonstrated need.

## 7. Calculation requirements

- Fee calculation is server-side.
- Use C# `decimal` and PostgreSQL `numeric` with documented precision.
- Validate currency and eligible base amounts.
- Define rounding/precision centrally.
- Reject malformed or contradictory policy configurations.
- Resolve the applicable policy using effective dates and approved eligibility rules.
- Record the calculated fee and its rule/version on the order or associated ledger record.
- Ensure the customer and seller see the correct applicable values for their roles.
- Never recalculate historical orders under the newest policy.

A fee-policy snapshot should preserve enough information to explain how the recorded amount was derived.

## 8. Example calculation (illustrative only)

Suppose an owner-approved policy defines a fee as a percentage of a specifically defined order subtotal. A sample calculation can be used in tests, but all example rates and amounts must be labelled as synthetic.

The calculation service should accept normalized inputs and return:
- Fee-policy ID/version.
- Eligible calculation base.
- Currency.
- Applied fixed amount, if any.
- Applied rate, if any.
- Rounded fee amount.
- Safe calculation explanation/reference.

Do not use floating-point arithmetic or duplicate the formula in the frontend. The UI should display the returned, authoritative calculation result.

## 9. Application timing

A fee may be calculated for preview before an order is submitted, but the definitive amount must be recalculated and snapshotted by the backend at the relevant confirmation point.

The approved policy must define the exact point when the fee becomes binding. Possible points include:
- Order confirmation.
- Seller acceptance.
- Successful payment/capture.
- Completion of delivery.

The implementation must not silently choose one.

When a fee policy changes:
- New eligible orders use the policy effective under the agreed rule.
- Existing confirmed orders preserve their prior fee snapshot.
- Pending orders are handled according to an explicit transition/acceptance policy.
- Changes are audited.

## 10. Refund and cancellation interaction

A commission or service fee does not automatically share the same refund treatment as the material amount.

Define:
- Whether a platform fee is fully refundable, partially refundable or non-refundable under each permitted scenario.
- Whether a commission is earned only after completion or at another defined event.
- Whether a chargeback/refund causes a fee adjustment.
- How negative/adjustment ledger entries are represented.
- Who approves exceptions.

When fees are adjusted:
- Preserve the original fee entry.
- Record a separate adjustment/compensating entry where appropriate.
- Associate the adjustment with the original order/fee policy.
- Store reason, actor and timestamp.
- Reconcile the adjustment with payment/settlement records.

Do not alter an old fee amount in place to hide a prior decision.

## 11. Ledger and reporting

Use the `commission_ledger_entries` concept in `Database.md`, adapting it to the approved model.

Record at minimum:
- Order reference.
- Seller reference.
- Fee policy ID/version.
- Eligible base amount.
- Fee amount/currency.
- Entry type/status.
- Creation timestamp.
- Adjustment/refund linkage where applicable.

Do not confuse a calculated fee with cash collected or a seller payout. These are different financial facts and need separate records/statuses.

## 12. Admin fee-management workflow

Recommended flow:
1. Authorized finance/admin user drafts a policy.
2. The form validates rate/amount, scope, currency and effective dates.
3. Policy preview uses synthetic/test calculations.
4. A separate authorized approval may be required for high-impact changes.
5. The policy is activated at the configured effective time.
6. An audit event records the change.
7. Applicable future order calculations use the new policy.
8. Reporting allows an authorized operator to trace an order's fee snapshot.

Where the same person is allowed to draft and approve, document that risk and compensating controls rather than implying separation of duties exists.

## 13. API outline

Potential routes:
- `GET /api/v1/admin/fees/policies`
- `POST /api/v1/admin/fees/policies`
- `GET /api/v1/admin/fees/policies/{policyId}`
- `PATCH /api/v1/admin/fees/policies/{policyId}` — only for permitted draft changes.
- `POST /api/v1/admin/fees/policies/{policyId}/activate`
- `POST /api/v1/admin/fees/policies/{policyId}/deactivate`
- `GET /api/v1/sellers/me/fees` — own permitted summary when commercial rules are active.
- A backend fee-calculation application service used by order/checkout workflows.

The API must not allow a seller or customer to submit a new fee rate through an ordinary order endpoint.

## 14. Security and audit requirements

- Restrict policy management to explicitly authorized roles.
- Validate all rates, amounts, currencies and effective dates server-side.
- Prevent overlapping contradictory policies for the same scope unless precedence is clearly defined.
- Audit draft, activation, deactivation and approval actions.
- Audit manual fee adjustments.
- Keep private financial reports restricted.
- Do not expose another seller's earnings or fees.
- Prevent client-controlled fee manipulation.
- Protect fee/settlement exports.
- Keep secrets out of audit metadata.

## 15. Error and edge cases

Handle:
- No applicable fee policy.
- More than one conflicting effective policy.
- Invalid rate/fixed amount.
- Unsupported currency.
- Expired or future policy.
- Unauthorized policy change.
- Concurrent policy activation.
- Fee computed before a policy changes.
- Refund/cancellation after fee recording.
- Fee adjustment without an original entry.
- Historical order queried under a later policy.

Where no policy exists, the system must follow the owner-approved behavior—such as no platform fee during a pilot—or explicitly block the affected operation. Do not silently invent a default commission.

## 16. Required tests

- Percentage/fixed/hybrid formula as selected.
- Decimal precision and rounding boundary cases.
- Policy effective-date selection.
- Conflicting-policy rejection.
- Unauthorized policy creation/activation.
- Fee snapshot remains unchanged after a policy update.
- Correct role-based display of fee information.
- Refund/cancellation adjustment policy.
- Duplicate adjustment/idempotency.
- Ledger/report consistency.
- Reconciliation links fee entries to actual financial events when applicable.

## 17. Acceptance checklist

- [ ] Commercial fee model is approved.
- [ ] Formula and rounding policy are documented.
- [ ] Server-side calculation is the single source of truth.
- [ ] Effective dates and policy precedence are unambiguous.
- [ ] Applied policy/fee is snapshotted.
- [ ] Historical orders are not retroactively recalculated.
- [ ] Financial adjustments preserve an audit trail.
- [ ] Admin fee changes require explicit permission.
- [ ] Customer/seller displays show the correct amount and basis.
- [ ] Automated calculation, permission and regression tests pass.

## 18. Completion gate

The feature is production-ready only when the platform owner has approved a fee model, the formula and payer are unambiguous, the applied rule is traceable, and the fee/financial workflow passes calculation and authorization tests. No fee rate should be assumed from this specification.
