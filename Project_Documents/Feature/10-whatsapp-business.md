# Feature Specification 10 — WhatsApp Business Integration

**Document ID:** BM-FEAT-10  
**Version:** 1.0  
**Status:** Planned integration specification  
**Priority:** P1 — After core order and notification flows  
**Dependencies:** Features 06–09; notification outbox; provider selection and privacy review

---

## 1. Purpose

Integrate BUILD MATE with an approved WhatsApp Business messaging solution for appropriate transactional order updates and permitted support communication.

The integration must follow the selected provider's current official requirements for business setup, message templates, consent, authentication, callbacks, pricing and delivery status. Provider behavior and requirements must be verified when the integration is implemented.

WhatsApp Business messaging is separate from masked calling. Do not claim that sending a WhatsApp message conceals the sender's number or prevents participants from contacting one another outside the platform.

## 2. Objectives

- Deliver approved transactional messages to eligible recipients.
- Use a replaceable provider adapter rather than vendor-specific logic throughout the application.
- Handle templates, recipient eligibility, opt-in/opt-out and delivery statuses.
- Maintain durable retryable notification records.
- Prevent duplicate or misleading messages.
- Minimize personal and order information sent externally.
- Make provider failures visible to authorized operators.
- Allow local development and tests without live WhatsApp credentials.

## 3. Scope

### Included
- WhatsApp provider interface.
- Mock adapter and test fixtures.
- Approved template catalogue.
- Business event-to-template mapping.
- Recipient identity/eligibility checks.
- Consent and preference handling.
- Provider request/response mapping.
- Delivery-status callback processing where supported.
- Safe retries, idempotency and failure visibility.
- Provider setup/operations documentation.

### Excluded
- Bulk promotional marketing by default.
- Unsolicited contact with arbitrary phone numbers.
- Using private WhatsApp numbers as public seller directory entries.
- Assuming a message is read because it was submitted or delivered.
- Treating WhatsApp messaging as an anonymous/masked-call feature.
- Relying on WhatsApp as the only way a customer can receive order information.
- Production enablement before provider, template and consent requirements are approved.

## 4. Product principles

1. WhatsApp is a communication channel, not the source of truth for orders.
2. Persist important order state before creating a notification request.
3. Send only the data required for the message's purpose.
4. Use the approved sender/business identity.
5. Follow the provider's current template and interaction rules.
6. Honor applicable consent, opt-out and preference rules.
7. Represent message outcomes accurately.
8. Retry safely and avoid duplicates.
9. Keep credentials and private message content out of logs.
10. Keep a non-WhatsApp path for users who cannot or do not wish to use the channel.

## 5. Candidate message events

Only activate events approved by the product owner.

| Event | Suggested recipient | Purpose |
|---|---|---|
| Order request received | Seller | Notify seller that a new request requires attention |
| Seller accepted/rejected | Customer | Communicate seller decision |
| Order cancelled | Relevant authorized participants | Communicate the actual cancellation result |
| Preparation started | Customer | Provide order-progress information |
| Load dispatched | Customer | Provide a delivery-progress update |
| Marked delivered | Customer | Inform customer of the seller-reported delivery state |
| Support ticket update | Authorized ticket participant | Communicate support progress |
| Payment/refund status changed | Authorized customer/seller, if enabled | Report a verified financial event |

Avoid sending a message for every internal state mutation. Each template should serve a clear user need, avoid unnecessary repetition and follow the approved notification preferences.

## 6. User stories

### BM-WA-01 — Receive an order update
As a customer, I want an authorized transaction update through WhatsApp when that channel is enabled for me.

Acceptance:
- The event is created from an authoritative persisted business state.
- Recipient eligibility and applicable preferences are checked.
- The correct approved template/version is used.
- The application records provider outcomes.
- The message does not falsely claim that delivery/payment/order completion occurred.

### BM-WA-02 — Seller receives an order alert
As a seller, I want to be notified when an eligible order needs my response.

Acceptance:
- Only the relevant seller receives the alert.
- The message uses a safe order reference.
- The seller can open the authenticated application to review and act on the request.
- The message does not expose unnecessary customer details.

### BM-WA-03 — Manage messaging preferences
As a user, I want the platform to respect my applicable notification choices and consent.

Acceptance:
- Preference changes are authenticated and recorded.
- Provider/channel opt-out signals are handled according to the selected integration and applicable rules.
- Ineligible messages are not sent.
- Any mandatory/security-related exceptions follow a documented approved policy, not an ad hoc bypass.

### BM-WA-04 — Handle a provider failure
As an operations user, I want to identify failed notifications and safely retry eligible ones.

Acceptance:
- Provider and application errors are represented accurately.
- Transient errors are retried within configured limits.
- Permanent errors are not retried indefinitely.
- Repeated callbacks do not produce duplicate state changes.
- The associated order status is not falsified.

## 7. Provider selection and onboarding

Before selecting a provider, assess:
- Supported WhatsApp Business product/API.
- Current business-account and sender requirements.
- Template creation/approval workflow.
- Allowed message categories and interaction/window rules, where applicable.
- Authentication and secret management.
- Webhook authenticity and delivery status support.
- Supported locales and rendering.
- Pricing, rate limits and account health requirements.
- Data processing, retention and privacy terms.
- Test/sandbox availability.
- Support/escalation capabilities.
- Availability in BUILD MATE's intended operating region.

Do not assume all providers expose the same API or have identical pricing, template rules or event semantics.

The chosen provider and implementation details should be recorded in an ADR or provider decision record.

## 8. Provider abstraction

Define an application-level interface such as `IWhatsAppSender`.

Responsibilities:
- Accept a validated recipient identifier and approved template payload.
- Validate that required template variables are present.
- Send using the configured adapter.
- Return an explicit normalized result.
- Return a safe provider message reference when available.
- Classify retryability where the provider response supports it.
- Propagate cancellation/timeouts appropriately.
- Avoid exposing vendor SDK types to application/domain logic.

The infrastructure adapter is responsible for:
- Authentication.
- Provider-specific payload serialization.
- HTTP/request timeout behavior.
- Provider response interpretation.
- Callback/event verification support.
- Mapping provider status codes to the internal status model.
- Safe redacted logging.

## 9. Template catalogue

Each template should have:
- Stable internal template code.
- Business event association.
- Locale/language.
- Approved body and allowed variables.
- Provider template ID/name, where required.
- Approval status.
- Template version.
- Recipient eligibility rule.
- Sensitivity classification.
- Allowed channel/consent conditions.
- Creation/update metadata.

Potential internal codes:
- `WA_ORDER_RECEIVED_SELLER`
- `WA_ORDER_ACCEPTED_CUSTOMER`
- `WA_ORDER_REJECTED_CUSTOMER`
- `WA_ORDER_CANCELLED`
- `WA_ORDER_DISPATCHED`
- `WA_ORDER_MARKED_DELIVERED`
- `WA_SUPPORT_UPDATE`

These names are illustrative; register templates in the application and the relevant provider before use.

### Template requirements
- Only approved templates are eligible for sending where approval is required.
- Do not send a template while its status is pending/rejected/disabled.
- Keep the template content/version associated with the notification attempt.
- Validate allowed variables and lengths.
- Escape/render data according to the provider's rules.
- Avoid sensitive free-form content unless an approved message path explicitly allows it.
- Never include a password, OTP unrelated to the approved authentication flow, secret or private document URL in a general order notification.

A template update must not silently alter a pending message that depends on the previous version without a documented compatibility policy.

## 10. Recipient and consent handling

Before sending a message:
1. Identify the recipient from a trusted persisted business event.
2. Confirm the relevant account/order/thread relationship.
3. Resolve the correct permitted destination.
4. Apply the approved consent/opt-in and preference policy.
5. Check suppression/opt-out state.
6. Confirm the selected template is approved and valid.
7. Apply rate limits and duplicate-event controls.
8. Record the sending attempt.

Do not accept an arbitrary destination phone number supplied by a public request and send it a privileged order message.

Distinguish:
- Transactional notifications.
- Authentication/security messages.
- Customer support communication.
- Promotional/marketing communication.

Do not send marketing content through this feature by default. If promotional messaging is introduced, it requires a separate policy, consent/opt-out handling and abuse controls.

The exact rules for opt-in, templates, recipient eligibility and provider interaction windows must be confirmed against the selected provider's current official documentation and applicable policy before production.

## 11. Notification architecture

Use the same durable event pattern as `09-sms-notifications.md`.

1. Business use case commits order/state changes.
2. Outbox event is created in the same transaction where practical.
3. Background worker claims pending work.
4. Notification service checks recipient eligibility/preferences.
5. Approved template is resolved and rendered.
6. `IWhatsAppSender` makes the provider request.
7. Provider reference and result are persisted.
8. Callback events update delivery state using authenticated, idempotent processing.
9. Retryable failures are rescheduled within limits.
10. Permanent/exhausted failures are surfaced to operations.

Do not hold a database transaction open while waiting for the provider.

## 12. Delivery-state model

Use an internal status model that distinguishes submission and final delivery where the provider supports those distinctions.

Possible states:
- `Pending`
- `Processing`
- `SubmittedToProvider`
- `Delivered`
- `Read` — only if a genuine provider event supports this state and it is useful to the product.
- `Failed`
- `DeadLettered`
- `Cancelled`
- `Unknown` or an equivalent representation for uncertain outcomes.

Not every provider provides every event. The implementation must not invent a `Read` state without evidence.

Do not equate:
- API request accepted.
- Message queued.
- Message submitted to provider.
- Message delivered.
- Message read by a user.

Only show the level of certainty the provider's actual event supports.

## 13. Retry and idempotency

- Use bounded retry/backoff for transient failures.
- Respect the selected provider's current rate-limit and retry guidance.
- Do not retry invalid template/destination/permission failures indefinitely.
- Store a safe correlation/provider reference for deduplication.
- Apply uniqueness/deduplication to callbacks where appropriate.
- Make worker claims concurrency-safe.
- Reconcile uncertain outcomes before repeating side effects if the provider supports lookup.
- Surface exhausted retries to an authorized operations user.
- Do not turn a successful order into a failed order because WhatsApp was unavailable.

The exact retry count, backoff and dead-letter behavior should be configured and tested against actual provider behavior.

## 14. Data model and persistence

Use `notification_outbox` and associated notification metadata described in `Database.md`.

Persist only what is needed:
- Outbox event ID.
- Event/template code and version.
- Recipient reference.
- Channel.
- Aggregate/order reference.
- Delivery state.
- Attempt count.
- Safe provider reference.
- Next attempt timestamp.
- Safe last-error code.
- Created/sent/delivery timestamps where applicable.

A separate attempt table may be useful for detailed history. If introduced, document the schema, uniqueness rules, retention and indexes.

Avoid storing full message bodies indefinitely merely for convenience. If message payload retention is needed, restrict access and define a retention policy. Never store secrets in the notification record.

## 15. Privacy and security

- Store provider credentials in a secure server-side secret/configuration facility.
- Never expose credentials through Next.js public variables or browser bundles.
- Restrict access to destination identifiers and provider metadata.
- Minimize content sent to the provider.
- Avoid sending full customer delivery addresses by default.
- Do not include private seller phone numbers or payout details.
- Redact message bodies, tokens and unnecessary phone data from logs.
- Validate callback signatures/authenticity using the provider's current mechanism.
- Validate callback payloads and request limits.
- Deduplicate repeated events.
- Apply privacy/retention rules to provider metadata and support access.
- Document incident response and credential rotation.

## 16. Failure scenarios

Handle:
- Missing or invalid credentials.
- Disabled/misconfigured provider.
- Template pending/rejected/deactivated.
- Invalid destination.
- Recipient ineligible or opted out.
- Rate limit.
- Network timeout with uncertain result.
- Provider accepted request but later delivered a failure event.
- Missing delivery receipt.
- Duplicate/out-of-order callback.
- Worker crashes after send but before recording result.
- Database outage while recording callback.
- Provider account suspension or outage.
- Locale/template mismatch.
- Invalid variable value or length.

Use safe messages and operations diagnostics. Do not automatically send SMS to an unapproved or unrelated number as a fallback. Any multi-channel fallback must be separately defined and use the same eligibility/privacy rules.

## 17. Frontend and user experience

- Show WhatsApp as an available channel only when configured and enabled for the relevant event/user.
- Do not promise instant delivery.
- Allow users to understand which contact channel is being used.
- Respect the preference/consent UI for the approved policy.
- Provide an in-app order timeline as the source of truth.
- Distinguish a provider failure from an order failure.
- Avoid showing private message bodies in notification dashboards or generic status views.
- If a notification is delayed, the order detail should still show the authoritative order state.

## 18. Required tests

### Unit tests
- Event-to-template mapping.
- Template variable validation.
- Recipient eligibility and preferences.
- Status mapping.
- Retryability classification.
- Idempotency/deduplication.
- Safe error mapping and redaction.

### Integration/contract tests
- Outbox is created with the business event.
- Mock adapter records a deterministic result.
- Missing provider configuration fails safely.
- Pending/rejected template is not sent.
- Ineligible recipient is suppressed.
- Duplicate outbox handling does not generate repeated sends beyond policy.
- Invalid callback is rejected.
- Duplicate callback is idempotent.
- Out-of-order callback does not regress a newer status improperly.
- Retry exhaustion becomes visible.
- Logs do not include credentials or unnecessary private content.
- Order state remains valid when messaging fails.

### Staging tests
- Selected provider successfully sends to controlled test accounts.
- Templates render correctly in supported locales.
- Approval/configuration state is verified.
- Opt-in/opt-out behavior is demonstrated.
- Provider delivery callbacks authenticate correctly.
- Delivered/read distinctions match actual provider events.
- Billing/rate limits and provider dashboard are operationally understood.
- Disablement and credential rotation are tested.

## 19. Operational controls

Provide authorized operations users with:
- Pending/failed WhatsApp counts.
- Queue age.
- Error categories.
- Retry counts and next-attempt times.
- Safe provider references.
- Template status and version.
- Provider health/configuration state.
- Dead-lettered notifications requiring action.

Do not provide broad export of phone numbers/messages by default. A sensitive reveal/export action requires explicit permissions, a purpose and appropriate audit.

Maintain a provider runbook covering setup, template lifecycle, credentials, callback configuration, common errors, safe retry, billing/limits, disablement and escalation.

## 20. Acceptance checklist

- [ ] Provider choice and current official requirements are documented.
- [ ] Provider adapter is separate from business logic.
- [ ] Mock adapter supports deterministic tests.
- [ ] Templates are defined, versioned and appropriately approved.
- [ ] Recipient eligibility/consent/preferences are enforced.
- [ ] Delivery states match actual provider capabilities.
- [ ] Outbox and callbacks are durable, bounded and idempotent.
- [ ] Provider failure does not falsify order state.
- [ ] PII and credentials are protected/redacted.
- [ ] Operational failure visibility and disablement exist.
- [ ] Staging tests pass using controlled accounts.
- [ ] Marketing messaging remains out of scope unless separately approved.

## 21. Completion gate

WhatsApp Business is production-ready only when the selected provider is configured and verified, template and consent requirements are met, delivery callbacks are handled safely, provider outcomes are accurately represented, and the integration passes its privacy and failure-handling tests.

**MVP recommendation:** Implement the adapter interface, outbox integration and mock tests first. Enable real WhatsApp sending only after the product owner approves the notification catalogue, provider choice, consent behavior and operational budget.
