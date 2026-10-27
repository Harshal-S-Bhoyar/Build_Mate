# Feature Specification 11 — Payments, Refunds and Reconciliation

**Document ID:** BM-FEAT-11  
**Version:** 1.0  
**Status:** Proposed specification; commercial and payment decisions pending  
**Priority:** Planned — do not enable live payments before approval  
**Dependencies:** Features 06–07, authentication, order persistence, audit logging and integration adapters

---

## 1. Purpose

Define the financial transaction lifecycle for BUILD MATE, including payment initiation, payment status, provider webhooks, refunds, transaction records, reconciliation and operational exception handling.

A payment is a financial event associated with an order. It is not the order itself and must not replace the order lifecycle. An order may be awaiting seller response while its payment has a different state, depending on the approved payment model.

The feature must be designed so that duplicate requests, delayed callbacks, provider timeouts and reconciliation differences do not silently corrupt the order or financial records.

## 2. Outcomes

- Payment attempts are linked to the relevant order and authenticated customer.
- The server determines whether an order is eligible for payment.
- The browser redirect or client message is never treated as sufficient proof of payment.
- Provider payment events are verified and processed idempotently.
- Payment, order and refund statuses remain distinct.
- Refunds follow an explicit, auditable approval and execution workflow.
- Local records can be reconciled with provider transactions and settlements.
- Financial actions are traceable without storing prohibited payment credentials.
- Provider failure does not create a false success state.
- The system supports mock/sandbox testing without live financial side effects.

## 3. Scope

### Included
- Payment gateway abstraction.
- Payment initiation and transaction records.
- Provider callback/webhook verification.
- Payment state transitions.
- Refund requests and processing.
- Idempotency for payment/refund operations.
- Reconciliation records and exception queue.
- Financial audit trail.
- Operations reporting for failures and mismatches.
- Automated tests for success, failure, duplication and uncertain outcomes.

### Excluded until explicitly approved
- Live payment collection.
- Automatically splitting payments among platform and sellers.
- Seller payouts or escrow services.
- Internal wallet, stored value or lending.
- Unapproved cash-on-delivery/UPI handling.
- Automatic refunds based on an invented cancellation policy.
- Storing raw card numbers, CVV or other prohibited payment credentials.

## 4. Decisions required before production

The product owner must approve:

1. Supported payment methods.
2. Payment provider and business-account setup.
3. When payment is collected: order request, seller acceptance, dispatch or another defined point.
4. Whether sellers receive funds through the platform or directly through another approved arrangement.
5. Whether platform commission is deducted before settlement or collected separately.
6. Cancellation and refund eligibility, timing and limits.
7. Partial-refund policy.
8. Who may request, approve and execute refunds.
9. Handling of payment success when order creation/status update is delayed or fails.
10. Settlement, reconciliation frequency and accounting ownership.
11. Tax/accounting treatment with qualified professional advice.
12. Required receipt/invoice fields and retention.
13. Manual payment handling, if any.
14. Currency and rounding rules.

Until these decisions are approved, the implementation may build interfaces, mock adapters, status models and tests, but it must not collect real money.

## 5. Domain terminology

- **Payment attempt:** An attempt to collect a specified amount through a payment method/provider.
- **Provider transaction:** A transaction identified by the payment provider.
- **Webhook:** A provider-to-platform event about a transaction.
- **Refund request:** An internal request to return an amount to a customer.
- **Refund:** A provider operation and resulting financial record for returning funds.
- **Reconciliation:** Comparing internal financial records with provider transaction/settlement data and resolving discrepancies.
- **Settlement:** Funds being made available or transferred under the provider/commercial arrangement.
- **Idempotency:** Repeated equivalent requests/events produce one effective operation rather than duplicate financial effects.

Do not use a browser redirect, customer screenshot or unverified message as authoritative proof of a provider transaction.

## 6. Separate state models

### 6.1 Payment status

Use the canonical values documented in `Database.md`, adapted only through an approved schema/API change:

- `NotRequired`
- `Pending`
- `Authorized`
- `Paid`
- `Failed`
- `PartiallyRefunded`
- `Refunded`
- `Cancelled`

The precise meaning of `Authorized` depends on the selected payment provider and whether funds have merely been authorized or actually captured.

Provider-specific statuses must be mapped to a normalized internal state. Retain only safe provider codes/references needed for diagnostics.

### 6.2 Refund status

A proposed refund state model is:

- `Requested`
- `PendingApproval`
- `Approved`
- `Processing`
- `Succeeded`
- `Failed`
- `Rejected`
- `Cancelled`

Adopt the exact set and transition policy before implementation. Do not confuse an approved internal request with a successfully completed provider refund.

### 6.3 Order status
Order statuses continue to follow feature 07. A payment callback must not arbitrarily change the order from `PendingSellerResponse` to `Completed`, or otherwise bypass the order state machine.

## 7. Payment workflow

Recommended provider-backed workflow:

1. Customer requests payment for an eligible order.
2. API authenticates the customer and verifies order ownership.
3. Backend validates the order state, amount, currency and payment eligibility.
4. Backend calculates the amount using authoritative persisted terms.
5. Backend creates a payment attempt with a unique idempotency key.
6. Backend calls the selected provider through `IPaymentGateway`, or schedules an approved async initiation path.
7. The provider returns a safe reference and a documented initial outcome.
8. The customer completes the provider's approved payment experience.
9. A verified webhook/provider status query determines the authoritative result, according to the provider's documented contract.
10. The system applies the payment-state transition exactly once.
11. Financial audit/reconciliation records are created.
12. The customer sees the status known to the platform.
13. Any necessary order-related action is performed by a separate validated application/domain workflow.

Do not hold a database transaction open while waiting for a customer to complete a hosted checkout or for a long-running provider operation.

## 8. Payment initiation API

Proposed route:

`POST /api/v1/orders/{orderId}/payments`

Requirements:
- Caller is authenticated.
- Caller owns the customer-side order or is explicitly authorized by the approved workflow.
- Order is eligible for payment.
- Amount/currency are calculated or loaded from authoritative server data.
- Client cannot override amount, payee, order owner or payment state.
- Idempotency is enforced.
- Provider response is safely mapped to a frontend DTO.
- Provider secrets and raw transaction credentials never reach the browser.
- Disabled or unconfigured payment integration returns a clear safe error.

Potential read route:

`GET /api/v1/orders/{orderId}/payments`

The response must be restricted to authorized parties and include only permitted payment-summary data.

Do not expose arbitrary provider payloads or internal risk/credential information.

## 9. Webhook and provider-event handling

A payment webhook is untrusted until verified.

Required processing:
1. Accept only the documented provider route/content type.
2. Enforce request size and timeout limits.
3. Verify signature/authenticity according to the provider's current official specification.
4. Validate the payload schema.
5. Validate provider transaction/reference and relevant amount/currency as appropriate.
6. Deduplicate the event with a unique provider event ID/reference or equivalent strategy.
7. Record the verified event safely.
8. Apply only legal state transitions.
9. Commit state changes and the processed-event marker consistently where practical.
10. Return the provider-appropriate response.
11. Queue additional work through an outbox if needed.

### Required edge cases
- Duplicate webhook delivery.
- Out-of-order events.
- Invalid signature.
- Missing/unknown payment reference.
- Unexpected amount or currency.
- Provider callback arrives before the browser redirect.
- Browser redirect claims success but no verified provider success exists.
- Database fails during processing.
- Provider succeeds but application times out before recording the result.
- Reconciliation later discovers a discrepancy.

Never mark payment as `Paid` based solely on a client redirect or a forged callback.

## 10. Refund workflow

Recommended flow:

1. Customer/support/admin initiates a refund request through a permitted route.
2. Backend loads the order and payment history.
3. Eligibility is checked against the approved refund policy.
4. The requested amount is checked against the refundable balance.
5. Required authorization/approval is verified.
6. A refund record is created with an idempotency key and reason code.
7. Provider refund operation is initiated.
8. The provider result or verified callback updates the refund record.
9. Payment aggregate/refund summary is recalculated consistently.
10. Audit and reconciliation records are updated.
11. Customer and relevant operators receive truthful status information.

A refund request must not be shown as completed merely because an admin clicked “Approve.”

### Refund controls
- Never refund more than the eligible amount.
- Account for completed, pending and in-flight refund requests.
- Prevent concurrent requests from refunding the same remaining balance.
- Require a reason code.
- Restrict refund approval and execution permissions.
- Preserve the original payment/order history.
- Keep provider references for reconciliation.
- Handle partial refunds explicitly if supported.
- Never silently alter a previous refund record to disguise a failed attempt.

## 11. Reconciliation

Reconciliation compares internal payment/refund/ledger records with provider transaction reports and settlements.

### Minimum requirements
- Identify internal payments with no matching provider event where one is expected.
- Identify provider transactions missing internally.
- Compare amount and currency.
- Compare payment/refund status.
- Identify duplicate or unmatched references.
- Identify provider-reported settlements that do not match expected totals.
- Track fees and net settlement only if the provider/commercial contract exposes the required data.
- Create an exception record for mismatches.
- Record manual investigation/resolution actions and audit them.

### Reconciliation workflow
1. Obtain provider transaction/settlement data through an approved export/API.
2. Validate and normalize the input.
3. Match by stable provider reference and relevant internal payment ID.
4. Compare state, gross amount, refund amount, fees and settlement values where applicable.
5. Record match/mismatch outcomes.
6. Assign unresolved exceptions to an authorized operations/finance owner.
7. Investigate and resolve the mismatch with evidence.
8. Preserve the original discrepancy and resolution history.

Do not auto-correct a financially material mismatch without a documented rule and approved authority.

### Reconciliation schedule
The cadence (for example, daily) must reflect the selected provider's settlement behavior and operational risk. It must be approved and configurable rather than hardcoded from a generic example.

## 12. Data model

Use the `payments`, `refunds`, order and ledger concepts in `Database.md`.

Ensure records can distinguish:
- Internal payment ID.
- Order ID.
- Provider code/reference.
- Amount/currency.
- Payment method.
- Payment status.
- Initiation/confirmation timestamps.
- Failure code.
- Idempotency key.
- Refund amount/status/provider reference.
- Reconciliation batch/record and exception outcome where implemented.

Add uniqueness constraints that prevent duplicate provider events/refunds as supported by the chosen provider. Protect financial records from casual deletion; corrections should create traceable compensating or resolution records where appropriate.

## 13. Security and compliance

- Never store raw card numbers/CVV or prohibited payment credentials.
- Keep payment secrets in a secure server-side secret store.
- Verify provider webhooks.
- Enforce role/resource authorization.
- Use idempotency and transaction boundaries.
- Redact provider payloads before logging.
- Restrict financial/admin exports.
- Audit fee/refund/payment overrides.
- Validate all amount/currency values server-side.
- Keep gateway secrets out of frontend builds and source control.
- Obtain qualified advice on accounting, tax, consumer and payment-related obligations before production collection.

## 14. Failure handling

Handle:
- Provider disabled/misconfigured.
- Provider timeout/unknown result.
- User abandons checkout.
- Payment fails or is cancelled.
- Duplicate payment initiation.
- Duplicate or out-of-order callback.
- Mismatched amount/currency.
- Refund rejected by provider.
- Refund outcome uncertain.
- Provider unavailable during reconciliation.
- Financial exception not automatically resolvable.

Use safe pending/unknown states where the real outcome is uncertain. Avoid retrying a payment/refund mutation with a new key simply because the first response timed out. Investigate using the original reference or approved reconciliation process.

## 15. Required tests

### Unit tests
- Payment state transitions.
- Refund state transitions.
- Refundable-balance calculations.
- Amount/currency validation.
- Idempotency behavior.
- Provider status mapping.
- Reconciliation matching rules.

### Integration tests
- Only authorized order owner can initiate payment.
- Client-supplied totals cannot control payment amount.
- Duplicate initiation is handled safely.
- Invalid webhook signature is rejected.
- Duplicate webhook has one effective result.
- Out-of-order events do not improperly regress state.
- Unknown provider outcome is not represented as success.
- Over-refund and concurrent refund attempts are rejected.
- Refund failure does not erase previous payment history.
- Financial records and audit events are created consistently.
- Reconciliation identifies missing/duplicate/mismatched records.
- Logs do not contain sensitive payment credentials.

### Sandbox/staging tests
- Payment succeeds and the verified state is recorded.
- Payment failure/cancellation is recorded accurately.
- Webhook authenticates and deduplicates correctly.
- Refund request, provider result and final state are tested.
- Reconciliation matches provider data.
- Production-disable/rollback procedure is verified.

## 16. Monitoring and operations

Monitor:
- Pending payments beyond expected duration.
- Provider failures/timeouts.
- Webhook signature failures.
- Duplicate and out-of-order events.
- Refund requests pending too long.
- Failed/uncertain refunds.
- Reconciliation mismatch count and age.
- Provider settlement differences.
- Errors in payment/ledger state transitions.

Use correlation IDs and safe references. Full financial details/exports must be restricted to authorized roles.

## 17. Acceptance checklist

- [ ] Commercial/payment policy is approved.
- [ ] Provider and current API contract are verified.
- [ ] Payment state is separate from order state.
- [ ] Server validates amount and eligibility.
- [ ] Webhook authenticity and idempotency are implemented.
- [ ] Refund balance and approval rules are enforced.
- [ ] Reconciliation creates traceable results and exceptions.
- [ ] Financial actions are permissioned and audited.
- [ ] Credentials and sensitive payloads are protected.
- [ ] Mock/sandbox tests pass.
- [ ] Operations have a mismatch investigation/disablement process.
- [ ] Live payments remain disabled until all required release approvals pass.

## 18. Completion gate

This feature is production-ready only after the selected provider, payment timing, fee/refund model, authorization, callback validation and reconciliation procedure are approved and tested end-to-end. A successful frontend redirect or mock-provider result alone is not proof of financial correctness.
