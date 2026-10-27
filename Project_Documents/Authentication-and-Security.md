# BUILD MATE — Authentication and Security Specification

**Document ID:** BM-SEC-001  
**Version:** 1.0  
**Status:** Mandatory proposed security baseline  
**Last updated:** 26 October 2026  
**Backend:** ASP.NET Core on .NET 10 LTS  
**Data store:** PostgreSQL through EF Core/Npgsql

---

## 1. Purpose

Define identity, session security, authorization, customer/seller privacy, secure file handling, application hardening, external integration security, audit requirements and release security gates.

Security is a product requirement, not a final polishing task. The implementation must use server-side authorization, explicit resource ownership checks, privacy-safe API DTOs and automated tests against common abuse scenarios.

## 2. Security objectives

1. Prevent unauthenticated access to private resources.
2. Prevent customers from accessing other customers' records.
3. Prevent sellers from accessing unrelated sellers' listings, orders or private customer information.
4. Prevent public leakage of phone numbers, email addresses, personal WhatsApp links and verification documents.
5. Protect authentication credentials and browser sessions.
6. Prevent order/price manipulation, unauthorized status changes, duplicate transactions and unsafe refunds.
7. Protect webhooks and external-provider credentials.
8. Record sensitive administrative actions without placing secrets in audit logs.
9. Detect and respond to security incidents.
10. Make secure behavior testable and reproducible by humans and coding agents.

## 3. Threat model

| Threat | Required control |
|---|---|
| Unauthenticated user requests a private resource | Authentication middleware and endpoint policy |
| Customer changes an ID in a URL to read another order | Resource ownership checks and integration tests |
| Seller accesses another seller's order | Seller-scoped query and ownership authorization |
| Client submits a fake price or fee | Backend recalculation and immutable commercial snapshot |
| Seller changes an order directly to `Completed` | Central transition policy and role checks |
| Public listing API leaks phone/email | Explicit response DTO allowlist and serialization tests |
| User attempts to download another seller's document | Private storage and authorization before issuing access |
| Cross-site request abuses a browser session | CSRF protections, SameSite cookies and origin controls |
| Credential stuffing or OTP abuse | Rate limiting, attempt limits, monitoring and safe error responses |
| Malicious uploaded file | Size/type validation, private quarantine/processing and safe serving |
| Forged payment webhook | Provider signature verification, replay defence and idempotency |
| Replayed order/payment request | Idempotency keys, unique constraints and transaction boundaries |
| Admin account misuse | Least privilege, stronger authentication where available and audit logs |
| PII leaks through logs | Structured logging, redaction and access restrictions |
| Provider outage causes false success | Explicit outcomes, retry controls and visible failed-event state |

Use OWASP guidance as a security engineering reference, but do not assume checklist completion alone proves the application is secure.

## 4. Identity architecture

### 4.1 Identity implementation
Use ASP.NET Core Identity as the default account and credential framework, unless an approved ADR selects a maintained alternative.

- Do not create an independent password store alongside Identity.
- Do not store passwords in plaintext or use reversible encryption for passwords.
- Use framework-managed password hashing and supported password-reset/verification mechanisms.
- Normalize email and phone values before applying uniqueness checks.
- Treat a verified phone/email as a verified communication channel, not proof of legal identity or business registration.
- Separate account state, seller verification state, seller status and listing moderation state.
- Keep identity data access behind backend services rather than exposing identity persistence directly.

### 4.2 Registration policy
The exact sign-up flow must be approved before release. At minimum:
- Validate and normalize identifiers.
- Require the selected verification flow before sensitive account actions.
- Apply registration and verification rate limits.
- Avoid detailed responses that allow attackers to enumerate private accounts.
- Prevent unapproved self-assignment of privileged roles.
- Record acceptance of applicable terms/privacy notices according to the approved policy.
- Provide a controlled account-recovery process.

### 4.3 Password policy, if password login is enabled
Use ASP.NET Core Identity's maintained password hashing and configuration facilities. Set a documented password policy appropriate to the user base. Do not invent a custom hashing algorithm.

- Enforce a minimum length approved by the security owner.
- Permit password managers and paste.
- Avoid forced periodic changes without a risk-based reason.
- Require a secure, expiring reset token.
- Invalidate relevant sessions/tokens after password reset or account-recovery events.
- Apply rate limits and monitoring to login/reset attempts.
- Use a generic authentication error rather than disclosing whether a specific account exists.

### 4.4 OTP/passwordless login, if enabled
- Generate codes using a cryptographically secure random generator.
- Store only a protected representation of the verification secret where practical.
- Give codes a short, configured lifetime.
- Limit attempts per challenge, account, verified destination and other appropriate abuse dimensions.
- Enforce one-time use atomically.
- Do not log OTP values.
- Do not include OTP values in analytics, URLs or browser storage.
- Apply cooldowns and abuse controls to sending codes.
- Define behavior for expired, replaced, consumed or invalid challenges.
- Do not treat delivery of an SMS as proof the person has a legal identity.
- Implement a recovery route when phone/SMS delivery is unavailable.

The exact OTP lifetime, attempt count and cooldown values must be selected, documented and security-tested before production.

## 5. Session and token handling

### 5.1 Browser session default
For the Next.js browser application, prefer a server-managed session with cookies configured as appropriate:
- `Secure` in production.
- `HttpOnly`.
- Appropriate `SameSite` setting based on the deployed origin model.
- Restrictive cookie path/domain.
- Defined lifetime and expiration behavior.
- Server-side invalidation/revocation where supported by the session design.

Never store long-lived access tokens, session tokens or refresh tokens in `localStorage` or expose them to ordinary client-side JavaScript without a documented security decision.

### 5.2 CSRF controls
Cookie-authenticated state-changing requests must be protected against CSRF. Use an appropriate anti-CSRF token pattern and/or a framework-supported approach, alongside safe origin checks.

- Do not use GET requests for state-changing actions.
- Use safe, configured SameSite cookies as a defence-in-depth measure, not as the only security control where additional protection is needed.
- Define behavior for requests from same-origin and cross-origin deployments.
- Test the selected CSRF strategy with the actual browser/API topology.

### 5.3 CORS
- Configure explicit allowed origins per environment.
- Do not combine wildcard origins with credentialed requests.
- Allow only required methods and headers.
- Do not echo arbitrary `Origin` values into access-control headers.
- Keep local development origins separate from production.
- CORS is not authentication or authorization.

### 5.4 Bearer tokens
If a future non-browser/service integration requires bearer tokens:
- Use short-lived credentials and an approved issuer/audience model.
- Validate signature, issuer, audience, expiration and relevant claims.
- Restrict scopes/permissions.
- Rotate/revoke credentials where supported.
- Keep secrets out of source control and browser bundles.
- Document key rotation and emergency revocation.

Do not introduce JWT complexity merely because it is familiar. Use the approach approved in the architecture.

## 6. Authorization model

Use role-based authorization combined with resource- and action-based policy checks.

### 6.1 Suggested application roles
- `Customer`
- `Seller`
- `Support`
- `Admin`
- `SecurityAdmin` or another restricted role for especially sensitive administration, if justified.

A single identity may have more than one business role if the product intentionally supports it. The role model must not allow public requests to self-assign roles.

### 6.2 Authorization rules
- Customer reads and edits only their own profile and saved addresses.
- Customer reads only their own orders, payments/receipts and authorized support records.
- Seller manages only their seller profile and listings.
- Seller reads and updates only orders belonging to that seller, and only through allowed transitions.
- Seller receives only the delivery details necessary for a permitted order.
- Support access is restricted to assigned cases and documented operational requirements.
- Admin capabilities are separated by policy when a broad privilege would create unnecessary risk.
- Verification documents and sensitive exports have separate access rules.
- Fee configuration, refunds and payout-related actions require explicit permission.
- All resource authorization is enforced in the API/application service.

### 6.3 Anti-IDOR requirements
Insecure Direct Object Reference (IDOR) vulnerabilities must be actively tested.

For each private route:
1. Authenticate as User A.
2. Create/read User A's resource.
3. Authenticate as User B.
4. Attempt to use User A's resource ID.
5. Verify the API denies access and does not return sensitive content.
6. Repeat for customer, seller, support and admin permission boundaries.

Use resource-scoped database queries where appropriate. Never assume UUIDs alone prevent IDOR.

## 7. Contact privacy and communication controls

This is a critical BUILD MATE requirement.

### 7.1 Public responses
Public listing/search endpoints must not include:
- Seller's private phone number.
- Seller's personal email address.
- Personal WhatsApp link or number.
- Private residential address, unless it is expressly approved public business information needed by policy.
- Payout details or banking information.
- Verification document names/keys/URLs.
- Internal verification notes.
- Private order/customer details.

Use an explicit public seller-summary DTO. Do not serialize the complete seller entity and then attempt to hide selected fields in the frontend.

### 7.2 Order-specific private information
A seller may need a delivery address to fulfil a valid order. Disclosure must be limited to the specific order and permitted lifecycle stage. Other customer addresses must remain private.

Support/admin access to contact details must have a defined purpose and be permissioned. Prefer masked values in general-purpose lists and reports.

### 7.3 Message privacy
- Each message thread has an explicit set of authorized participants.
- Check thread membership for every message read/write request.
- Do not expose thread IDs as authorization secrets.
- Restrict moderation and export access.
- Apply limits to message length and attachment uploads.
- Do not promise that all attempted contact exchange is prevented unless content controls exist and have been tested.
- Establish moderation/escalation procedures for fraud, harassment, threats and inappropriate content.

### 7.4 Masked calling
A masked-call integration must remain disabled until real tests show that both caller and recipient do not see the other party's protected number in caller ID, logs, callbacks or provider UI.

Required controls:
- Order-bound authorization.
- Short-lived call session or provider token.
- Valid participant verification.
- Rate limits and abuse monitoring.
- Provider request/signature validation where relevant.
- Minimal call metadata.
- No audio recording by default.
- Clear error handling when a provider number/session is unavailable.
- No fallback to revealing direct numbers.

Masked calling is a provider capability, not something the website can guarantee by hiding a phone-number field.

### 7.5 Email/SMS/WhatsApp privacy
- Send only messages the recipient is entitled to receive.
- Record consent/opt-in where required by the selected channel and approved policy.
- Do not include full private addresses, verification documents or unnecessary personal data in ordinary notification bodies.
- Use approved templates/provider configurations where required.
- Protect provider callbacks and record final delivery status.
- Respect opt-out and notification preferences where applicable.
- Do not use personal contact details for marketing without an approved lawful basis and required consent.

## 8. Input and output security

### 8.1 Request validation
Validate all data at the backend boundary:
- Type, length and requiredness.
- Numeric ranges and decimal precision.
- Supported enum values.
- Quantity/unit compatibility.
- Dates and timezone interpretation.
- Ownership of referenced IDs.
- File type/size and upload authorization.
- State transitions and operation-specific preconditions.
- Text length and content constraints.
- Allowlisted sorting/filtering fields.

Never trust browser validation or hidden controls as the only gate.

### 8.2 SQL/data access
- Use EF Core parameterized queries and safe query composition.
- Do not build raw SQL by concatenating user-supplied text.
- If raw SQL is necessary, parameterize all values and document the reason.
- Apply bounded pagination.
- Avoid exposing database exception details to users.
- Use least-privilege database identities.

### 8.3 Output encoding
Use framework-appropriate output encoding. Avoid rendering user-generated text as executable HTML. If rich content is ever approved, sanitize it with a maintained library and an explicit allowlist.

### 8.4 Server-side requests and URLs
Avoid arbitrary server-side URL fetching based on user input. If URL fetch is required for an approved feature, implement allowlists and protections against loopback/private-network access, redirects to prohibited targets and metadata endpoints. Do not create an open proxy.

## 9. Order and financial integrity

- Price, fee, tax and discount totals are calculated server-side.
- Confirmed order snapshots are immutable through ordinary listing edits.
- Each order references one customer, one seller and one listing in the MVP.
- Only allowed state transitions can succeed.
- Use idempotency for retries and external effects.
- Protect capacity/availability from concurrent overbooking.
- Verify webhook authenticity and deduplicate provider events.
- Separate order, payment and refund states.
- Do not log full provider payloads without redaction.
- Never store raw card data.
- Refunds, fees and payout changes require authorization, audit and reconciliation records.
- Do not activate real payment collection before the financial policy and failure/reconciliation paths are approved.

## 10. File-upload security

Treat file uploads as untrusted input.

- Enforce size limits at reverse proxy/host, API and storage layers where possible.
- Allow only necessary file types.
- Validate file signatures/content where feasible, not just extensions.
- Generate random server-owned storage keys.
- Do not use user-controlled names as storage paths.
- Keep seller verification documents private.
- Keep approved public listing imagery separate from confidential documents.
- Consider quarantine and scanning where available and justified.
- Strip image metadata when appropriate.
- Serve downloads with safe content disposition and content type.
- Reject HTML/SVG or active content from public image uploads unless a reviewed sanitization/serving strategy exists.
- Apply authorization before generating any temporary download URL.
- Redact storage keys/URLs from logs.

## 11. HTTP and browser hardening

Configure and test appropriate headers for the deployed architecture:
- HTTPS with a valid certificate.
- HSTS in production where correct for the domain/deployment.
- Content Security Policy suitable for the actual Next.js pages/providers.
- `X-Content-Type-Options: nosniff`.
- Suitable clickjacking protection through CSP `frame-ancestors` and/or compatible headers.
- A restrictive `Referrer-Policy`.
- A deliberate `Permissions-Policy`.
- Secure cookie settings.
- Request size limits and timeouts.
- Proper error handling without stack traces in production.

Do not copy a restrictive Content Security Policy without testing application functionality; document any required script/style/connect source exceptions.

## 12. Rate limiting and abuse detection

Apply different controls to different risks:
- Registration/login.
- Password recovery and OTP.
- Search and public listing scraping.
- Message creation.
- Order/quote creation.
- Call initiation.
- Uploads.
- Support ticket creation.
- Payment initiation.
- Webhooks, using provider authentication plus replay/deduplication controls.

Rate limits should consider relevant identities and operation behavior, not just IP address. Use monitoring for repeated denials, OTP abuse, scraping patterns, suspicious account changes and unusual refunds. Avoid exposing internal thresholds that would help an attacker bypass controls.

## 13. Secrets and configuration

- Never commit API keys, database passwords, SMTP passwords, telephony credentials, signing keys or production certificates.
- Maintain a `.env.example` or documented appsettings template with placeholders only.
- Use local user-secrets/environment variables for development and a proper secrets store for production.
- Restrict access by environment and service.
- Rotate credentials after suspected exposure or staff/vendor access changes.
- Do not pass secrets into frontend `NEXT_PUBLIC_*` variables.
- Ensure CI logs do not print secret values.
- Do not hardcode provider API keys into agent instructions or tests.

If a secret is accidentally committed, treat it as compromised: revoke/rotate it and clean up exposure through the approved repository process. Deleting the visible line alone is not sufficient.

## 14. Logging, monitoring and audit

### 14.1 Diagnostic logs
May contain operation name, safe correlation ID, duration, status code and a limited resource identifier. They must not contain passwords, OTPs, session cookies, tokens, payment secrets, private document URLs or unnecessary full PII.

### 14.2 Audit events
Audit:
- Seller verification decisions and suspensions.
- Listing moderation/override.
- Sensitive profile/data access where required.
- Order state overrides.
- Refunds, fees and payout changes.
- Admin role and permission changes.
- Private-document access or export.
- Sensitive report exports.
- Security-policy changes.

Audit records include actor, action, entity, timestamp, reason where relevant and correlation ID. Ordinary application roles must not be able to silently rewrite or delete audit history.

### 14.3 Monitoring
Alert or otherwise surface:
- Repeated login/OTP failures.
- Unexpected authorization denials.
- Provider authentication failures.
- Payment signature failures or duplicate/invalid events.
- Unusually high cancellation/refund activity.
- Notification queue backlogs.
- Database connection exhaustion.
- Application error spikes.
- Repeated private-data access failures.

## 15. Dependency and infrastructure security

- Use supported runtimes and maintained dependencies.
- Pin compatible package versions through project files/lockfiles where supported.
- Run automated dependency and vulnerability checks in CI.
- Remove unused dependencies.
- Keep production database access restricted.
- Use separate credentials and data for local, staging and production environments.
- Back up the database and test restoration.
- Restrict admin access and provider console permissions.
- Secure CI/CD credentials and deployment environments.
- Review third-party provider access and retention terms.
- Do not run privileged application processes unnecessarily.

## 16. Security testing requirements

Required automated tests include:
- Customer A cannot read Customer B's profile, addresses, order, messages or payment data.
- Seller A cannot read Seller B's listings/orders or private documents.
- Public search/listing DTOs contain no private phone/email/WhatsApp fields.
- Unauthorized users cannot download verification documents.
- Customer cannot perform seller/admin actions.
- Seller cannot bypass the order state machine.
- Client-supplied total/fee values are ignored or rejected.
- Duplicate order/payment requests are handled idempotently.
- Invalid/forged webhook events are rejected.
- Upload limits/type checks are enforced.
- CSRF/origin/session behavior matches deployment configuration.
- Rate limits apply to sensitive endpoints.
- Exceptions do not leak secrets or stack traces.
- Logs are checked for redaction.
- Admin actions create audit events.

Use xUnit for backend unit/integration tests and Playwright for browser/security journey tests where appropriate.

## 17. Incident response baseline

Before production, document:
1. Who can declare and coordinate an incident.
2. How to disable a compromised provider integration or sensitive endpoint.
3. How to rotate credentials and revoke sessions.
4. How to preserve relevant audit evidence.
5. How to identify affected accounts/orders and data.
6. How to restore service safely.
7. How to notify affected parties and authorities where legally required.
8. How to perform root-cause analysis and record remediation.

Do not promise a particular statutory notification timeline until applicable obligations have been reviewed for the actual business and incident.

## 18. Pre-production security gate

- [ ] Supported runtime and dependency versions verified.
- [ ] Identity, session and account-recovery flows tested.
- [ ] CSRF/CORS/cookie configuration validated for real deployment origins.
- [ ] Server-side role and ownership checks tested.
- [ ] Contact privacy tests pass for public DTOs.
- [ ] Order pricing, idempotency and transition tests pass.
- [ ] Private document uploads/downloads are access-controlled.
- [ ] Webhook authenticity and replay protection are tested, if used.
- [ ] Rate limits and abuse controls are active.
- [ ] Secrets are not committed or published to the frontend.
- [ ] Logs and errors are redacted.
- [ ] Admin actions are audited.
- [ ] Backup/restore and incident procedures are documented.
- [ ] Privacy notice and product terms are approved.
- [ ] Any masked-calling claims are supported by end-to-end provider tests.

No production launch should proceed with a known unresolved critical privacy/authentication vulnerability.
