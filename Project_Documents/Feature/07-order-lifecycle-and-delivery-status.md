# Feature Specification 07 — Order Lifecycle and Delivery Status

**Document ID:** BM-FEAT-07  
**Version:** 1.0  
**Status:** Implementation-ready specification; operational time limits pending approval  
**Priority:** P0 — MVP  
**Dependencies:** Feature 06 — Order, Quote and Checkout

---

## 1. Purpose

Define the order lifecycle from seller response through preparation, dispatch, delivery, completion, cancellation and dispute handling.

The backend owns the lifecycle. The frontend displays available actions and current state, but users cannot force transitions by submitting arbitrary status strings.

BUILD MATE coordinates orders; it does not operate the truck fleet by default. Sellers are accountable for their accepted material-plus-delivery offer and must update status truthfully.

## 2. Outcomes

- Customer and seller see consistent order status.
- Only authorized actors can perform allowed transitions.
- Every status change is timestamped and traceable.
- Order terms and price remain stable through listing changes.
- Delivery status is not confused with payment status.
- Failed, late, cancelled or disputed orders can be handled under explicit policies.
- Notifications are produced reliably without holding database transactions open.
- Admin exceptions are permissioned and audited.

## 3. Scope

### Included
- Canonical order states.
- Seller accept/reject actions.
- Preparation, dispatch and delivery marking.
- Customer delivery confirmation where adopted.
- Completion and dispute states.
- Cancellation requests under the approved policy.
- Append-only status history.
- Authorized administrative exception handling.
- Status timeline in the customer and seller experiences.
- Order-status notification events.
- Concurrency and state-transition tests.

### Excluded
- Live GPS fleet tracking.
- Automatic route optimization.
- Driver-specific user accounts.
- Proof-of-delivery methods not yet approved.
- Automated penalty calculations or seller payouts.
- Guaranteed automatic completion after an invented time interval.
- Silent admin rewrites of order history.

## 4. Canonical states

Use the states established in `DRD.md` and `Database.md`:

- `PendingSellerResponse`
- `Accepted`
- `Preparing`
- `OutForDelivery`
- `Delivered`
- `Completed`
- `Rejected`
- `Cancelled`
- `Disputed`

Keep payment status separate, with values such as `NotRequired`, `Pending`, `Authorized`, `Paid`, `Failed`, `PartiallyRefunded`, `Refunded`, and `Cancelled`, as applicable.

If the business later requires states such as “Rescheduled” or “DeliveryFailed,” add them through a documented domain/API/database change rather than using arbitrary free-form strings.

## 5. Roles and responsibilities

### Customer
- View own order.
- Cancel where allowed.
- Confirm delivery if that step is part of the approved flow.
- Raise an eligible complaint/dispute.
- Communicate through authorized platform channels.

### Seller
- View orders belonging to their seller account.
- Accept or reject eligible pending orders.
- Update preparation, dispatch and delivery states when permitted.
- Provide required delivery evidence.
- Respond to authorized support requests.

### System/background worker
- Process configured response deadlines.
- Detect eligible overdue work.
- Schedule notifications.
- Retry transient operations.
- Record safe system-generated events.
- Never silently override a business decision or invent a delivery event.

### Admin/support
- View records within their permission scope.
- Handle assigned disputes/support cases.
- Perform explicit overrides only when policy permits.
- Record reason and audit event for privileged actions.

## 6. Proposed state transition matrix

These transitions form the baseline and must be enforced centrally. Any product-policy exception must be documented before implementation.

| Current state | Actor | Action | Next state |
|---|---|---|---|
| No order | Customer | Submit valid fixed-price order request | `PendingSellerResponse` |
| `PendingSellerResponse` | Seller | Accept | `Accepted` |
| `PendingSellerResponse` | Seller | Reject | `Rejected` |
| `PendingSellerResponse` | Customer | Cancel if policy allows | `Cancelled` |
| `PendingSellerResponse` | System/admin | Apply approved response-expiry policy | `Cancelled` or another explicitly approved outcome |
| `Accepted` | Seller | Start preparation/loading | `Preparing` |
| `Accepted` | Customer/system | Cancel under approved policy | `Cancelled` |
| `Preparing` | Seller | Dispatch the load | `OutForDelivery` |
| `Preparing` | Authorized actor | Initiate permitted exception flow | `Cancelled` or `Disputed` under policy |
| `OutForDelivery` | Seller | Mark delivered with required evidence | `Delivered` |
| `Delivered` | Customer/system | Confirm or complete under the approved completion policy | `Completed` |
| `Delivered` | Customer/support | Open an eligible issue | `Disputed` |
| Eligible non-terminal state | Authorized admin | Open a documented exception | `Disputed` |
| `Disputed` | Authorized admin | Resolve according to approved resolution policy | `Completed` or `Cancelled`, as appropriate |

This table is a proposed baseline, not a substitute for final commercial/legal policy. In particular, response deadlines, cancellation rights and the resolution of disputes must be confirmed before production.

## 7. Transition enforcement

Implement transitions in a central domain/application policy rather than repeating conditionals across controllers.

Each command should:
1. Authenticate the actor.
2. Load the order within the allowed access scope.
3. Check actor ownership and role.
4. Check the source state.
5. Validate operation-specific requirements.
6. Check relevant cancellation/response/dispute policy.
7. Apply the state change transactionally.
8. Append history with old/new state and actor.
9. Write required audit/outbox records.
10. Return the authoritative new state.

Do not accept an arbitrary `newStatus` from the browser and persist it directly.

## 8. Order history

Maintain an append-only status history record for every transition.

Recommended fields:
- History record ID.
- Order ID.
- Previous state, if one exists.
- New state.
- Actor user ID or explicit system actor.
- Actor role/category.
- Reason code.
- Internal note, if authorized and needed.
- Timestamp.
- Correlation ID.

Rules:
- Ordinary users cannot edit/delete history.
- Internal notes must not be shown to customers.
- Public timelines should use safe event labels and timestamps.
- An administrative override adds a new history event; it must not erase the original trail.
- Keep PII and unnecessary free text out of the status record.

## 9. Seller response and response deadlines

The product owner must approve:
- Whether a response deadline exists.
- The deadline duration and applicable operating hours.
- Whether reminders are sent.
- The outcome when the deadline expires.
- Whether the customer can cancel before the seller responds.
- Whether a seller can request more time.

When enabled:
- Persist the response deadline on the order.
- Use UTC for stored timestamps.
- Run the expiry policy through idempotent background processing.
- Ensure a late seller acceptance cannot race with expiry and produce conflicting states.
- Record the system action and reason.
- Notify relevant parties through the outbox.

Do not hardcode an arbitrary number of minutes or hours in a controller.

## 10. Preparation, dispatch and delivery

### Preparing
The seller indicates that fulfilment preparation/loading has started. Do not expose this action before the order is accepted.

### Out for delivery
The seller indicates that the load has been dispatched. If the product requires a dispatch timestamp, vehicle reference or evidence, define that contract before implementation.

### Delivered
The seller indicates that the material load reached the delivery destination. If delivery evidence is required, validate its presence and store it securely.

### Completed
Completion follows the approved rule, such as customer confirmation or an explicitly approved completion policy. Do not mark a delivery completed solely because a notification was sent or a provider reported a message delivery.

### Evidence requirements
The product owner must decide what proof is required—for example, a receipt, photo or customer confirmation—and how it is retained. Evidence must be linked to the order, access-controlled, validated and handled under the privacy/retention policy.

## 11. Cancellation

Cancellation rules must be explicitly approved for each relevant order state.

The policy must cover:
- Customer cancellation before seller response.
- Customer cancellation after acceptance.
- Seller inability to fulfil.
- Listing no longer available.
- Response timeout.
- Delivery delay/failure.
- Payment authorized/paid cases if payments are enabled.
- Capacity release/reservation cleanup.
- Fee/refund effects.
- Required reason codes and notifications.

Implementation requirements:
- Validate the current order/payment state.
- Check who can initiate cancellation.
- Record the requested/approved outcome and reason.
- Do not silently erase the order.
- Apply capacity release exactly once where capacity was reserved.
- Create refund work only when the approved financial policy requires it.
- Make retries idempotent.
- Provide the caller with a clear result.

## 12. Disputes and exceptions

A dispute or complaint should record:
- Order reference.
- Initiating actor.
- Reason/category.
- Description.
- Relevant evidence.
- Current dispute state.
- Assigned authorized support/admin.
- Resolution and reason.
- Timestamps and audit history.

The exact dispute window, evidence retention, resolution options and refund/compensation policy must be approved. Do not automatically assign fault or calculate penalties using an unapproved rule.

During a dispute:
- Preserve the original order snapshot.
- Restrict sensitive case material to authorized parties.
- Allow operationally required support actions.
- Do not delete history or overwrite the original status trail.
- Communicate the actual status; avoid falsely claiming the issue is resolved.

## 13. Concurrency and idempotency

Concurrent actions can occur when:
- Seller accepts while the expiry worker attempts cancellation.
- Customer cancels while seller begins preparation.
- Seller submits delivery twice.
- Customer submits delivery confirmation more than once.
- Admin resolves a case while another authorized operator is acting.

Required controls:
- Use a transaction and a concurrency token, conditional update or suitable locking strategy.
- Require the expected source state.
- Use idempotency for retry-sensitive commands as needed.
- Define stable conflict responses.
- Do not write duplicate history/outbox events for a single transition.
- Ensure one accepted command has one authoritative outcome.

## 14. API contract

Expected route family:
- `GET /api/v1/orders`
- `GET /api/v1/orders/{orderId}`
- `POST /api/v1/orders/{orderId}/cancel`
- `GET /api/v1/sellers/me/orders`
- `GET /api/v1/sellers/me/orders/{orderId}`
- `POST /api/v1/sellers/me/orders/{orderId}/accept`
- `POST /api/v1/sellers/me/orders/{orderId}/reject`
- `POST /api/v1/sellers/me/orders/{orderId}/start-preparation`
- `POST /api/v1/sellers/me/orders/{orderId}/dispatch`
- `POST /api/v1/sellers/me/orders/{orderId}/mark-delivered`
- `POST /api/v1/orders/{orderId}/confirm-delivery` — if enabled
- `POST /api/v1/orders/{orderId}/disputes`

The route list is a target contract. Implement only routes with defined permissions and behavior. Do not create a generic seller endpoint that permits arbitrary state edits.

## 15. Customer and seller UI

### Customer order timeline
Show safe, human-readable milestones such as:
- Order submitted.
- Seller accepted.
- Preparation started.
- Load dispatched.
- Delivered.
- Completed.
- Cancelled.
- Under review/dispute.

Include the timestamp, using consistent display-time formatting. Avoid exposing internal system notes or another participant's private data.

### Seller order view
Show relevant:
- Public order reference.
- Material and quantity/unit snapshot.
- Agreed terms and price details the seller is entitled to view.
- Delivery location needed for the order.
- Requested timing.
- Current state and permitted next actions.
- Response deadline, if enabled.
- Required delivery evidence action.
- Platform communication/support entry point.

Seller lists must not expose unrelated customer addresses or unrelated seller orders.

### Admin view
Show state/history and permitted exception actions. Require confirmation and a reason for high-impact overrides. Privileged actions must be audited.

## 16. Notifications

Generate domain events/outbox items for important state transitions. Suggested events:
- Order received.
- Seller accepted/rejected.
- Order cancelled.
- Preparation started.
- Dispatched.
- Marked delivered.
- Completed.
- Dispute opened/resolved.

Notification delivery must be decoupled from the transaction. A provider timeout must not roll back a valid order transition unless the business operation explicitly requires an external confirmation as a precondition.

## 17. Required tests

### Unit tests
- Every valid transition.
- Every invalid transition in the canonical matrix.
- Actor/role policy.
- Cancellation rules and reason codes.
- Response-timeout policy.
- Completion policy.
- Dispute resolution policy.
- Capacity reservation/release interactions.

### Integration tests
- Seller can update only their own order.
- Customer can access only their own order.
- Unauthorized state changes are rejected.
- Repeated action does not duplicate history/outbox effects.
- Expiry-worker race with acceptance produces one valid outcome.
- Delivery cannot be marked without required evidence.
- Terminal states cannot be silently reopened.
- Administrative override requires permission and audit.
- Order snapshot remains stable.
- Notification failure does not falsely change order state.
- Payment and order states remain independent.

### Browser tests
- Customer sees seller acceptance and later status updates.
- Seller can accept/reject a pending request.
- Seller sees only permitted actions for the current state.
- Delivery evidence flow works when enabled.
- Customer sees a clear dispute/cancellation result.
- Error/conflict states are understandable and do not suggest a transition succeeded when it did not.

## 18. Acceptance checklist

- [ ] Canonical state model implemented centrally.
- [ ] Role, ownership and state checks run server-side.
- [ ] Transition history is append-only for ordinary application roles.
- [ ] Response deadlines are configured only after approval.
- [ ] Delivery evidence follows the approved policy.
- [ ] Cancellation and dispute rules are explicit.
- [ ] Concurrency/idempotency prevent duplicate/conflicting actions.
- [ ] Notification events are durable and decoupled from provider calls.
- [ ] Payment state is separate from order state.
- [ ] Customer/seller/admin screens show correct permitted actions.
- [ ] Unit, integration and browser tests cover negative cases.

## 19. Completion gate

The feature is complete when the order's state can be changed only by authorized actors through valid transitions, every change is auditable, and customers/sellers receive accurate progress information without compromising private data.
