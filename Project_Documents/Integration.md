# BUILD MATE — External Integration Specification

**Document ID:** BM-INTEGRATION-001  
**Version:** 1.0  
**Status:** Proposed integration baseline  
**Last updated:** 26 October 2026

---

## 1. Purpose

Define how BUILD MATE connects to external services without coupling its business logic to one vendor. Potential integrations include SMS, WhatsApp Business, masked calling, payments, email, media storage, maps/geocoding, monitoring and optional analytics.

The core marketplace must remain testable when all external providers are unavailable or unconfigured. Do not select a provider solely because it appears in an example, and do not claim a provider supports a capability until the relevant official documentation and actual configuration have been verified.

## 2. Integration principles

1. Core order/business logic is provider-independent.
2. External services are accessed through application interfaces/ports.
3. Infrastructure implements vendor-specific behavior.
4. Local development and automated tests use deterministic mock/fake adapters.
5. Production credentials are never committed or exposed to frontend code.
6. Provider responses and webhooks are treated as untrusted input.
7. Retry-sensitive side effects are idempotent.
8. Timeouts/failures are explicit and visible.
9. Personal data shared with a provider is minimized.
10. Each integration has an owner, configuration guide, failure plan and disable/rollback procedure.

## 3. Integration inventory and status

| Capability | MVP status | Notes |
|---|---|---|
| PostgreSQL / EF Core | Required | Core transactional database |
| Authentication/session | Required | Use approved ASP.NET Core implementation |
| Object storage | Required when file uploads ship | Separate private documents from public listing images |
| Email | Optional for initial pilot | May be used for transactional messages/account support |
| SMS | Planned | Provider and applicable registration/configuration must be confirmed |
| WhatsApp Business | Planned | Provider, template and consent policy must be confirmed |
| Masked calling | Planned, privacy gate applies | Must verify both parties' caller-ID behavior |
| Payments | Pending business decision | Choose payment flow, refunds, fees and reconciliation rules first |
| Maps/geocoding | Optional | Begin with locality/postal-code service areas if sufficient |
| Error monitoring | Recommended | Redact PII/secrets |
| Product analytics | Recommended carefully | Define event scope, consent and data minimization |

Do not mark a service as integrated when only an interface or mock exists. Track lifecycle status such as `Proposed`, `InDevelopment`, `ConfiguredInStaging`, `Verified`, `ProductionEnabled`, `Disabled`.

## 4. Logical integration architecture

Application/domain use cases call interfaces. Infrastructure implements them.

Suggested interfaces:
- `ISmsSender`
- `IWhatsAppSender`
- `IMaskedCallProvider`
- `IPaymentGateway`
- `IEmailSender`
- `IObjectStorage`
- `IGeocodingProvider`
- `IClock`

Each integration should define:
- Input/output DTOs.
- Configuration/secret requirements.
- Timeout policy.
- Retryability classification.
- Idempotency method.
- Webhook/callback behavior.
- Logging/redaction policy.
- Test fakes.
- Operations and disable instructions.

Do not reference vendor SDK classes throughout controllers and domain services.

## 5. Integration configuration

Maintain safe environment-specific settings. Example configuration structure:

```json
{
  "Integrations": {
    "Sms": {
      "Enabled": false,
      "Provider": "Mock",
      "TimeoutSeconds": 10
    },
    "WhatsApp": {
      "Enabled": false,
      "Provider": "Mock",
      "TimeoutSeconds": 10
    },
    "MaskedCalling": {
      "Enabled": false,
      "Provider": "Mock",
      "TimeoutSeconds": 15
    },
    "Payments": {
      "Enabled": false,
      "Provider": "Mock",
      "TimeoutSeconds": 20
    }
  }
}
```

This is illustrative configuration, not a required exact schema. Adapt it to the actual .NET configuration model.

Rules:
- Local defaults should use mocks or disabled providers.
- Secrets are supplied through environment variables or a proper secret manager.
- Do not include API keys in checked-in JSON.
- Fail startup validation when a feature is marked enabled but required production configuration is missing.
- Make production enablement an explicit operations action.
- Never enable a live-payment feature by simply flipping a flag before webhook and reconciliation tests pass.

## 6. Timeouts, retries and circuit behavior

Every remote request requires an explicit timeout and cancellation behavior.

Retry only errors likely to be transient, such as certain timeouts, connection failures or provider rate limits. Do not blindly retry validation/authentication failures.

A retry policy should include:
- Bounded number of attempts.
- Exponential backoff and jitter where useful.
- Respect for provider retry-after instructions where applicable.
- Idempotency for operations with side effects.
- A clear terminal failure state.
- Logs/metrics that show repeated failure without leaking private data.

Avoid holding a database transaction open while waiting on a slow external provider. Prefer recording an outbox/operation intent, completing the local transaction, and processing the provider action asynchronously.

A circuit breaker may be added if measured reliability needs justify it; it is not mandatory for the first small pilot.

## 7. Notification event pattern

Use a transactional outbox or equivalent durable event record for important notifications.

Example order:
1. A business use case changes the order.
2. The API transaction persists the state change and notification intent.
3. A background worker claims eligible outbox items.
4. It selects the correct provider adapter.
5. The adapter attempts delivery.
6. The event is updated with provider reference, attempt count and result.
7. Retryable errors are scheduled again within limits.
8. Exhausted events become visible to authorized operations staff.

The user-facing order state must not imply that a message was delivered simply because the order was updated.

Recommended notification event types include:
- Order submitted.
- Seller accepted/rejected.
- Order cancellation.
- Preparation started.
- Dispatched/out for delivery.
- Delivered/completed.
- Support ticket created/updated.
- Approved payment/refund status changes.

Send only the minimum necessary data. Avoid sending full delivery addresses or sensitive verification details through ordinary notification content.

## 8. SMS integration

### Purpose
Send approved transactional alerts and verification messages where the product requires SMS.

### Requirements
- Implement `ISmsSender`.
- Support mock and real-provider adapters.
- Store safe provider request identifiers and delivery outcomes.
- Handle accepted/submitted, delivered, failed, rejected and unknown states according to actual provider semantics.
- Apply request throttling and verification-code abuse controls.
- Support template/configuration requirements applicable to the provider and Indian messaging rules.
- Do not log OTP values.
- Keep recipient information protected.
- Make permanent versus transient failure actionable.

Before production:
1. Verify current provider API and authentication requirements.
2. Confirm sender identity, template and applicable registration prerequisites.
3. Confirm delivery callback semantics and signing/authentication.
4. Test valid, invalid, throttled and timeout cases.
5. Document consent and retention expectations.
6. Configure operational credits/billing and delivery monitoring.

Do not invent sender IDs, templates, registration details or provider response formats.

## 9. WhatsApp Business integration

### Purpose
Send permitted transactional updates and support messages using an approved WhatsApp Business solution.

### Requirements
- Define `IWhatsAppSender`.
- Use the provider's current official API/SDK and approved authentication method.
- Implement consent/opt-in and opt-out behavior as applicable.
- Use approved message templates when required by the actual channel/interaction category.
- Record message/provider references and delivery outcomes.
- Respect template/content restrictions and current provider policy.
- Avoid duplicate messages after retries.
- Handle recipient failure, blocked/invalid destination and provider outage.
- Keep private contact data out of logs and unnecessary template variables.

Before production, confirm the chosen provider, current business-account prerequisites, templates, conversation/message billing model, webhook authenticity and delivery semantics. These can change; verify at implementation time.

WhatsApp Business messaging must not be described as masked calling. It is a different channel with different visibility and privacy behavior.

## 10. Masked calling and telephony

### Purpose
Allow authorized order participants to communicate without disclosing their protected phone numbers, if the provider supports that use case.

### Required application behavior
- An authenticated participant requests a call for a specific order.
- API verifies that the caller is an authorized participant.
- System checks order eligibility and rate limits.
- Provider creates a time-limited call/session using its supported model.
- Application stores the provider reference and safe event metadata.
- Provider events are authenticated and correlated to the call/order.
- The call outcome is recorded according to actual provider feedback.

### Privacy verification gate
Before enabling:
- Test calls from both sides with real test numbers/devices.
- Inspect caller ID as displayed by each carrier/device.
- Verify provider dashboards and callbacks do not expose protected numbers to unauthorized parties.
- Confirm behavior for missed/failed calls and expired sessions.
- Ensure no fallback directly reveals a participant's phone number.
- Confirm applicable notice/consent and telephony obligations.

Call recording is off by default. Adding recording requires legal/privacy review, explicit disclosure, appropriate consent, access controls, retention/deletion rules and secure storage.

If the provider cannot meet the privacy requirement, keep the feature disabled and use platform messaging/support instead.

## 11. Payment gateway integration

### Purpose
Allow customers to pay under a product-owner-approved payment model.

This integration must remain disabled until the business has approved:
- Payment timing and methods.
- Who pays the platform fee.
- Cancellation/refund rules.
- Settlement/payout responsibilities.
- Reconciliation process.
- Tax/accounting treatment with qualified advisers.
- Handling for COD/UPI/manual payments if offered.
- Support escalation when a payment succeeds but an order update fails.

### Required controls
- Implement `IPaymentGateway`.
- Use verified server-side gateway interactions.
- Never trust a browser redirect alone as proof of payment.
- Verify webhook signatures/authenticity.
- Deduplicate provider events.
- Keep payment state separate from order state.
- Store only the provider references and minimum data needed.
- Never store raw card data.
- Apply idempotency to payment/refund operations.
- Record failed, pending, successful, partially refunded and refunded states as supported.
- Reconcile gateway reports against local payment and ledger records.

Never hardcode a real payment provider's undocumented signatures or webhook formats. Use current official provider documentation and sandbox tests.

## 12. Object storage and media

Use separate logical storage areas and policies:
- Approved listing images: public delivery through a controlled image-serving path/CDN, after moderation.
- Seller verification documents: private storage with server-side authorization.
- Internal support evidence: private access according to support/case policy.

Requirements:
- Generate storage keys server-side.
- Validate file size/type/content.
- Avoid user-controlled filesystem/object paths.
- Do not publish private document keys.
- Apply access control before creating time-limited download URLs.
- Use expiration on temporary URLs where supported.
- Redact private URLs in logs.
- Define deletion/retention behavior.
- Consider metadata stripping and scanning appropriate to file type/threat.

If an upload succeeds in storage but DB persistence fails, or vice versa, provide a safe cleanup/reconciliation path rather than leaving uncontrolled orphaned private objects indefinitely.

## 13. Email integration

If email is enabled:
- Keep provider-specific code behind `IEmailSender`.
- Use verified sending domains and the provider's current authentication requirements.
- Use templates with appropriate escaping.
- Do not include sensitive information in subject lines/body unnecessarily.
- Protect reset/verification links and enforce expiry/one-time semantics where applicable.
- Track provider delivery/bounce/failure outcomes where available.
- Avoid treating provider acceptance as proof that the user read a message.

Use test/sandbox modes during development.

## 14. Maps and geocoding

Maps are optional for MVP if locality/postal-code service areas are sufficient.

If enabled:
- Define a minimal location precision requirement.
- Obtain only the location data necessary for delivery eligibility.
- Explain why precise location is requested.
- Protect API keys and separate browser-safe versus server-only credentials.
- Restrict any public browser keys to approved domains and capabilities.
- Avoid storing third-party geocoding data beyond permitted terms.
- Use explicit service-area rules; do not treat a geocoded point as proof that a seller can deliver there.

Do not add live truck tracking, routing or automatic delivery ETA merely because a map provider is available.

## 15. Monitoring and error reporting

Monitor:
- Provider success/failure rates.
- Timeout and retry rates.
- Queue/outbox backlog.
- Rate-limit/rejection patterns.
- Payment/webhook verification failures, if applicable.
- Object upload/download failure.
- API exception rate and latency.

Use correlation IDs and safe provider references. Apply PII/secrets redaction before sending telemetry to a third party. Define retention and access permissions for logs/error reports.

## 16. Webhooks and inbound provider calls

All webhooks must:
- Be bound to an explicit route and supported provider.
- Verify signatures or equivalent provider authenticity controls.
- Validate timestamp/replay behavior where supported.
- Apply event-ID/provider-reference deduplication.
- Validate payload size/schema.
- Avoid broad exception leaks.
- Persist processing outcome safely.
- Return the provider-appropriate response only after the intended handling policy is satisfied.
- Be tested for invalid signature, duplicate, out-of-order, malformed and transient-failure cases.

Do not assume a webhook URL is secret enough to establish authenticity.

## 17. Provider selection checklist

Score each candidate on:
- Required capability and actual privacy behavior.
- Current official documentation/SDK quality.
- Availability in the intended Indian operating context.
- Template/consent/registration requirements.
- API reliability, retry and webhook semantics.
- Cost per useful completed transaction, not merely per request.
- Data location, retention and access terms.
- Security controls and support responsiveness.
- Test/sandbox availability.
- Vendor lock-in and exit strategy.
- Operational and reconciliation complexity.

Record the final selection and trade-offs in an ADR or provider decision record.

## 18. Integration testing checklist

For each provider, test:
- Correct configuration.
- Missing/invalid credentials.
- Successful request.
- Rejected request.
- Timeout/network failure.
- Rate limit.
- Duplicate request.
- Invalid webhook/callback.
- Duplicate/out-of-order webhook.
- Provider outage.
- Retry exhaustion.
- Safe log redaction.
- Deactivation/rollback.
- Data retention and access control.

Automated tests use mocks/fakes; sandbox/contract tests verify provider behavior; only approved production-safe checks use live provider accounts.

## 19. Operational runbook per provider

Maintain a short provider runbook containing:
- Provider/service name and owner.
- Enabled environment(s).
- Secret configuration references (not secret values).
- Dashboard/health location.
- Timeout/retry/idempotency behavior.
- Failure codes and common remedies.
- How to disable the feature.
- How to retry safely.
- How to rotate credentials.
- How to investigate delivery/reconciliation issues.
- Support escalation contact/process.
- Known limitations and tested privacy behavior.

## 20. Release gate

An integration is production-ready only when:
- Business need and provider are approved.
- Current official specifications were verified.
- Secrets are configured securely.
- Adapter and fake implementations exist.
- Failure/retry/idempotency behavior is tested.
- Webhook authenticity is verified where applicable.
- Data sharing and privacy are reviewed.
- Operational alerts/runbook exist.
- Integration-specific acceptance tests pass.
- UI language accurately describes what the provider can do.

**Important:** A mock provider, sandbox transaction or unverified provider capability must never be represented as a real production integration.
