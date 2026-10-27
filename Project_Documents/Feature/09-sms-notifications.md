# Feature Specification 09 — SMS Notifications

**Document ID:** BM-FEAT-09  
**Version:** 1.0  
**Status:** Planned integration specification  
**Priority:** P1 — After core order lifecycle  
**Dependencies:** Features 06–07, notification outbox, provider-adapter foundation

---

## 1. Purpose

Provide reliable SMS notifications for selected BUILD MATE customer and seller events. SMS is a delivery channel for a platform event; it is not the system of record for an order and does not prove that a recipient read or acted on the message.

The order database remains authoritative. If SMS fails, a valid order transition must not be rolled back merely because the provider could not send a message.

## 2. Objectives

- Send appropriate transactional alerts to eligible verified destinations.
- Deliver messages through a replaceable provider interface.
- Record requested/sent/failed/unknown outcomes accurately.
- Retry transient errors safely.
- Keep OTPs, private addresses and unnecessary PII out of logs and ordinary messages.
- Avoid duplicate messages after retries.
- Make provider/configuration failures visible to authorized operations staff.
- Keep local development independent of live SMS credentials.

## 3. Scope

### Included
- `ISmsSender` application port.
- Mock/fake adapter for development and automated tests.
- Production adapter for a selected provider.
- Message-template catalogue.
- Recipient eligibility and consent/preference checks where applicable.
- Durable notification outbox integration.
- Provider result/callback handling where supported.
- Delivery status and retry handling.
- Operational monitoring and runbook.

### Excluded
- Choosing a provider before requirements/costs are reviewed.
- Marketing campaigns or bulk promotional SMS by default.
- Sending order or customer data to unapproved destinations.
- Treating “accepted by provider” as proof of delivery/read.
- Using SMS alone as sufficient identity or seller verification.
- Logging OTP values or provider secrets.

## 4. Required event catalogue

Candidate transactional events:

| Event | Recipient | Purpose |
|---|---|---|
| Verification code requested | User who initiated verification | Complete an approved authentication flow |
| Order submitted | Seller | Inform seller of a new order request |
| Seller accepted/rejected | Customer | Inform customer of seller response |
| Order cancelled | Relevant participants | Confirm the recorded cancellation outcome |
| Preparation started | Customer | Provide an order progress update |
| Load dispatched | Customer | Provide a delivery progress update |
| Marked delivered | Customer | Inform customer that seller reported delivery |
| Support ticket created/updated | Relevant user | Confirm support workflow progress |
| Payment/refund state change | Authorized customer/seller as appropriate | Report a verified financial event, only when payments are enabled |

The event catalogue is configurable. Do not enable every event by default. For each event, define a real product need, recipient entitlement, message template and duplicate policy.

Do not send a message merely because a client submitted an action; send it from the authoritative persisted event/outbox flow.

## 5. Architecture

Recommended flow:

1. A backend use case changes an order/account state.
2. The transaction writes the state change and a notification outbox item.
3. A background worker claims an eligible outbox item.
4. It validates recipient eligibility and selects the approved template.
5. `ISmsSender` sends the message through the chosen adapter.
6. Provider reference/result is stored.
7. Transient failure is retried within configured limits.
8. Exhausted/permanent failures are made visible to authorized operations.
9. Duplicate/out-of-order callbacks are handled idempotently.

Do not make a remote SMS request inside a long-running order transaction.

## 6. Template design

Create a centrally managed template catalogue. Each template needs:
- Stable template code.
- Business event.
- Locale/language.
- Approved text and allowed variables.
- Recipient eligibility.
- Applicable consent/notification preference.
- Sensitivity classification.
- Maximum permitted content length/provider constraints.
- Provider template/reference if the selected channel requires one.
- Version and approval status.

Possible template codes:
- `AUTH_VERIFICATION_CODE`
- `ORDER_SUBMITTED_TO_SELLER`
- `ORDER_ACCEPTED_TO_CUSTOMER`
- `ORDER_REJECTED_TO_CUSTOMER`
- `ORDER_CANCELLED`
- `ORDER_DISPATCHED`
- `ORDER_MARKED_DELIVERED`
- `SUPPORT_TICKET_UPDATE`

These are examples and must be registered in the implementation before use.

### Message content rules
- Use plain-language wording.
- Include only the minimum information needed.
- Prefer public order reference over unnecessary internal UUIDs.
- Do not include full delivery address by default.
- Do not include verification documents or sensitive internal notes.
- Do not include passwords or session information.
- Do not promise an arrival time unless it is genuinely confirmed under the product policy.
- Do not tell the customer an order is complete merely because an SMS was sent.

## 7. Recipient eligibility and preferences

Before sending:
- Resolve the recipient from an authorized business event, not an arbitrary client-supplied phone number.
- Confirm the destination is valid under the approved policy.
- Verify the user is entitled to receive the event.
- Check applicable opt-in, preference and opt-out rules.
- Apply rate limits and duplicate-event controls.
- Ensure the event is not stale or superseded where that matters.

Security, transactional and legally required messages may have different handling from optional notifications. Define preference behavior explicitly and have applicable messaging requirements reviewed before production.

Do not send marketing messages through this transactional feature by default.

## 8. Provider abstraction

Recommended interface responsibilities:
- Accept a validated destination, approved template/rendered body and idempotency/reference data.
- Return an explicit provider outcome.
- Return a safe provider message reference.
- Classify failure where possible as transient/permanent/unknown.
- Support cancellation/timeout where practical.
- Avoid logging the full body or phone number unnecessarily.

Keep vendor SDK types inside the infrastructure adapter. The application/outbox logic should not depend on a particular SMS provider.

### Mock adapter
The local/test adapter must:
- Produce deterministic outcomes.
- Clearly identify itself as a mock.
- Avoid sending actual messages.
- Support success, failure and timeout test cases.
- Never imply that a real mobile device received the SMS.

## 9. Delivery states

Use a documented internal notification state model, such as:
- `Pending`
- `Processing`
- `Sent` or `SubmittedToProvider`
- `Delivered` where the provider provides a verified delivery receipt
- `Failed`
- `DeadLettered`
- `Cancelled`

Keep `SubmittedToProvider` distinct from `Delivered` if the provider returns that distinction. Do not fabricate a delivery receipt where one is not available.

Provider statuses should be mapped to an internal normalized model with the original safe code/reference retained where useful.

## 10. Retry and idempotency behavior

- Retry only errors classified as transient.
- Use bounded exponential backoff and respect applicable provider retry guidance.
- Use an event/outbox ID as part of a safe idempotency/reference strategy where appropriate.
- Deduplicate provider callbacks.
- Prevent two workers from processing the same outbox item concurrently.
- Use an atomic claim/lease or equivalent worker-claim strategy.
- Stop retrying permanent invalid-destination/template/authentication failures until corrected.
- When an operation times out and the provider result is unknown, do not blindly send duplicates; use provider lookup/reconciliation if supported or mark the outcome uncertain for controlled handling.

Exact retry counts/backoff values must be configured and justified for the selected provider.

## 11. Security, privacy and compliance

- Store provider credentials in a secure configuration/secret store.
- Never place API keys in the frontend.
- Redact OTPs and message content from logs.
- Minimize phone-number exposure and restrict any diagnostic display.
- Verify callbacks using the provider's documented authenticity mechanism.
- Validate request size/schema and deduplicate callback event IDs/references.
- Respect recipient preferences and required consent.
- Verify current Indian messaging registration/template requirements and the chosen provider's applicable rules before launch.
- Do not assume a provider's successful API response establishes compliance.
- Define retention for message metadata and recipient identifiers.

## 12. Proposed data model

Use `notification_outbox` as described in `Database.md`, with fields such as:
- Outbox/event ID.
- Event type and aggregate reference.
- Recipient user reference.
- Channel.
- Template code/version.
- Minimal payload.
- Delivery state.
- Attempt count and next-attempt timestamp.
- Safe last-error code.
- Created/sent timestamps.

A separate notification-attempt table may be useful if multiple attempts/provider responses must be retained. If added, define retention, indexes and provider-reference uniqueness. Do not store unnecessary full SMS body copies unless a clear audit/support need exists.

## 13. Operations dashboard

Authorized operations staff should be able to inspect:
- Pending outbox count.
- Oldest pending item age.
- Failure counts by safe provider/error category.
- Retry count and next retry.
- Provider availability/health summary.
- Dead-lettered events requiring review.
- Safe message reference and associated business event.

Avoid exposing full phone numbers or full message bodies in general-purpose dashboard lists. Any reveal/export capability must be explicitly authorized and audited.

## 14. Failure scenarios

Handle:
- Missing/invalid provider credentials.
- Provider unavailable.
- Network timeout with unknown send result.
- Invalid destination.
- Unsupported/unapproved template.
- Rate limit.
- Provider accepts request but later reports failure.
- Delivery receipt is absent.
- Duplicate callback.
- Outbox worker crash.
- Database unavailable during result recording.
- Recipient preference prevents optional notification.

Do not cancel a valid order just because an SMS failed. The order and notification delivery have separate lifecycles.

## 15. Required tests

### Unit tests
- Template selection/rendering.
- Recipient eligibility.
- Preference handling.
- Status mapping.
- Retryability classification.
- Idempotency/deduplication behavior.
- PII redaction.

### Integration/contract tests
- Outbox event is created with the business transaction.
- Worker claims work once under concurrency.
- Mock success is recorded accurately.
- Transient failure is retried within limits.
- Permanent failure is not retried indefinitely.
- Provider timeout is represented as uncertain where appropriate.
- Duplicate callback has no duplicate effect.
- Invalid callback is rejected.
- Missing credentials fail safely.
- Logs do not contain OTP/body/secrets.
- A notification failure does not revert a valid order transition.

### Staging tests
- Actual test destination receives expected approved message.
- Template/language renders correctly.
- Provider callback/signature behavior is verified.
- Real delivery outcome maps correctly to internal status.
- Opt-out/preference behavior works.
- Provider billing/usage monitoring is operational.

## 16. Required configuration

The implementation must define safe settings for:
- Provider and enabled state.
- Request timeout.
- Template catalogue.
- Rate limits.
- Retry policy.
- Outbox polling/batch size.
- Provider callback verification.
- Logging/redaction.
- Credentials through secure configuration.

Do not commit actual provider credentials or assume a provider name before selection.

## 17. Acceptance checklist

- [ ] Transactional events are explicitly defined.
- [ ] Provider interface and deterministic mock exist.
- [ ] Outbox flow is durable and retryable.
- [ ] Templates are versioned/approved as required.
- [ ] Recipient eligibility and preferences are checked.
- [ ] Provider result is represented honestly.
- [ ] Retries and callbacks are idempotent.
- [ ] PII/OTP/secrets are redacted.
- [ ] Provider requirements are verified before production.
- [ ] Failure dashboard/runbook is available to authorized staff.
- [ ] Tests cover outage, timeout, duplicates and preference restrictions.

## 18. Completion gate

SMS integration is production-ready only when the selected provider has been configured and verified, the allowed messaging policy is approved, delivery outcomes and failures are accurately recorded, and retry/consent/privacy behavior passes the acceptance tests.
