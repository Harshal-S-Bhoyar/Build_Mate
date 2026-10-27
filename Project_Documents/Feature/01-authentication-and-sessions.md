# Feature Specification 01 — Authentication and Sessions

**Document ID:** BM-FEAT-01  
**Version:** 1.0  
**Status:** Implementation-ready specification, subject to login-policy decisions  
**Priority:** P0 — MVP foundation  
**Dependencies:** Repository foundation, API error handling and configuration

---

## 1. Purpose

Implement secure account registration, login, logout, session management and account access controls for BUILD MATE. This feature establishes the identity boundary used by customer profiles, seller onboarding, orders, messaging and administration.

The implementation must use ASP.NET Core on .NET 10 LTS and PostgreSQL through Entity Framework Core/Npgsql. ASP.NET Core Identity is the default identity framework unless an approved architecture decision selects a maintained alternative.

## 2. Outcomes

- Users can authenticate using the login method approved by the product owner.
- The backend can identify the authenticated user reliably.
- Browser sessions are protected and can be invalidated.
- Customer, seller, support and admin capabilities are authorized on the server.
- Users cannot assign themselves privileged roles.
- Authentication abuse is rate-limited and logged safely.
- Public and private APIs do not leak credentials or unnecessary account information.

## 3. Scope

### Included
- Identity configuration and user records.
- Registration flow according to the approved policy.
- Login/logout and session-status endpoint.
- Email/phone verification if enabled.
- Account activation, suspension and closure states.
- Role and resource-based authorization foundations.
- Session expiry and revocation behavior.
- Rate limiting, safe error handling and audit events.
- Automated authentication and authorization tests.

### Excluded
- Business/seller verification approval; handled by feature 03.
- Customer address management; handled by feature 02.
- Order-specific permissions and lifecycle; handled by order features.
- Full enterprise single sign-on unless a later requirement approves it.
- Passwordless/OTP login before that mode is selected and its recovery rules are approved.

## 4. Decisions and defaults

1. Use ASP.NET Core Identity for the default account/credential implementation.
2. Prefer a server-managed browser session using Secure, HttpOnly cookies.
3. Do not store long-lived browser tokens in `localStorage`.
4. Use server-side role and resource authorization.
5. Do not allow public registration to create an `Admin`, `Support` or other privileged role.
6. Require verification before sensitive account actions as specified by the approved login policy.
7. Treat verification of a phone/email channel as control of that channel, not proof of legal identity or business legitimacy.
8. Keep the initial login method configurable so the product owner can choose password login, OTP/passwordless login, or another supported flow without rewriting domain authorization.

The exact login methods, OTP lifetime, retry count, cooldowns, password policy and recovery process must be explicitly configured before production.

## 5. Actors

- **Anonymous visitor:** Can access public pages and initiate registration/login.
- **Authenticated customer:** Can access permitted customer resources.
- **Authenticated seller:** Can access seller features granted to that account; seller verification is separate.
- **Support user:** Can access only the support capabilities assigned to the role and case.
- **Admin:** Can access explicitly permitted administration functions.
- **Security/operations owner:** Manages environment secrets, monitoring and incident response.

Roles must be assigned by an authorized backend process or administrator. A client-supplied role field must never determine the user's permissions.

## 6. Identity and account model

Use the framework's identity user and role tables as appropriate. Extend the identity user with application-specific fields only where needed.

Required conceptual fields:
- `id`: stable UUID identity.
- `display_name`.
- Normalized email and/or phone identifier, according to the chosen login method.
- Verification timestamps for enabled channels.
- `account_status`.
- `created_at_utc`.
- `updated_at_utc`.

Suggested account statuses:
- `PendingVerification`
- `Active`
- `Suspended`
- `Closed`

Keep this separate from:
- Seller verification status.
- Seller operational status.
- Listing moderation status.
- Order status.

Do not create a second password store if ASP.NET Core Identity is used.

## 7. User stories

### BM-AUTH-01 — Register
As a new user, I want to create an account so I can use protected marketplace functions.

Acceptance:
- Required inputs are validated on the server.
- Identifiers are normalized consistently.
- The account is created with a non-privileged role/state.
- Verification is required where the approved policy says it is.
- The response does not reveal unnecessary account existence information.
- Duplicate requests do not create duplicate accounts.

### BM-AUTH-02 — Sign in
As a registered user, I want to sign in securely so I can access my own resources.

Acceptance:
- Valid credentials complete the configured login flow.
- Invalid credentials produce a safe error.
- Rate limits and lockout/abuse controls apply.
- Authentication establishes the approved server/browser session.
- The server does not trust user-supplied role claims.

### BM-AUTH-03 — Read session
As a signed-in user, I want to know whether I am authenticated and which basic identity is active.

Acceptance:
- Session response contains only minimal profile/role information needed by the UI.
- Anonymous requests return an appropriate unauthenticated result.
- The endpoint never returns cookies, password hashes, reset tokens or OTP values.

### BM-AUTH-04 — Sign out
As an authenticated user, I want to end my current session.

Acceptance:
- The session cookie is cleared/invalidated according to the chosen session mechanism.
- Reuse of a revoked server-managed session fails where server-side revocation is supported.
- Logout does not disclose session data.
- State-changing session actions use the appropriate CSRF protection.

### BM-AUTH-05 — Suspend an account
As an authorized administrator, I want to suspend an account that should not use the platform.

Acceptance:
- The action requires explicit permission.
- A reason code is recorded.
- Relevant active sessions/credentials are invalidated according to policy.
- An audit record is created.
- The affected user receives a generic, safe message.

## 8. Proposed API contract

Implement the actual endpoints in `API.md`. The expected route family is:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/session`
- `POST /api/v1/auth/verification/send` — only if verification/OTP is enabled.
- `POST /api/v1/auth/verification/confirm` — only if verification/OTP is enabled.
- `POST /api/v1/auth/password/forgot` — only if password login is enabled.
- `POST /api/v1/auth/password/reset` — only if password login is enabled.

These routes are a target contract, not proof they already exist.

### API rules
- Use explicit request and response DTOs.
- Return the approved `ProblemDetails`-style error structure.
- Do not serialize identity entities.
- Do not return a password hash, reset token, OTP, session cookie or sensitive claims.
- Do not accept a client-provided privileged role.
- Avoid user-enumeration responses from registration/recovery endpoints.
- Use rate limits appropriate to the selected authentication method.

## 9. Browser session requirements

Configure cookies according to the actual deployment topology:
- `Secure` in production.
- `HttpOnly`.
- An appropriate `SameSite` policy.
- Restrictive domain/path settings.
- A documented lifetime and renewal/expiry approach.
- Appropriate invalidation/revocation behavior.

State-changing cookie-authenticated requests must use the selected anti-CSRF strategy. CORS must use explicit configured origins; never enable wildcard credentialed origins.

Do not choose cookie attributes by copying a tutorial without testing the real frontend/API origin arrangement.

## 10. Authentication validation and abuse controls

- Normalize identifiers before uniqueness and account lookup.
- Apply per-operation rate limits.
- Use framework-managed password hashing if passwords are enabled.
- Use cryptographically secure random values for OTP/reset challenges.
- Bound OTP attempts and enforce one-time use if OTP is enabled.
- Give recovery codes and links limited lifetime and single-use semantics where appropriate.
- Do not put secrets in URLs, analytics or client logs.
- Avoid messages that tell an attacker which email/phone is registered.
- Do not disable abuse controls in production merely to simplify development.
- Provide a safe support path when the user cannot access a verified channel.

The exact thresholds are configuration decisions and must be tested before production.

## 11. Authorization foundation

Every protected endpoint must enforce server-side authorization.

At minimum, verify:
- Customer can access only their own customer resources.
- Seller can access only their own seller resources and eligible seller orders.
- A seller account that is not approved cannot publish orderable listings.
- Support can access only permitted cases/resources.
- Admin permissions are restricted by policy.
- A user cannot gain permissions by changing request bodies, route IDs or frontend state.

A role name in the frontend is informational; it is not an authorization boundary.

## 12. Data and privacy requirements

- Use framework identity schema/tables consistently.
- Keep identifiers normalized and unique according to the selected login policy.
- Store verification timestamps and account status.
- Keep authentication challenges or reset records under secure lifecycle rules.
- Do not log passwords, OTPs, cookies, auth headers or reset links.
- Avoid sending unnecessary personal data to analytics and third-party providers.
- Define account closure and personal-data retention behavior with the approved privacy policy.
- Use synthetic users in development and tests.

## 13. Error cases

The feature must handle:
- Missing/invalid input.
- Duplicate registration.
- Invalid credentials.
- Unverified account.
- Suspended/closed account.
- Expired session.
- Expired or already-used verification challenge.
- Rate-limited request.
- Identity store/database unavailable.
- Invalid CSRF token.
- Disabled or misconfigured authentication method.

Errors must be safe and actionable without disclosing internal identity details.

## 14. Audit and monitoring

Record appropriate safe events for:
- Successful/failed sign-in where policy permits.
- Account creation.
- Verification state change.
- Password reset or credential recovery event.
- Session/security-sensitive change.
- Account suspension/closure.
- Role/permission change.
- Repeated abuse-limit events.

Never store OTPs, reset tokens, session cookies or raw authorization headers in audit metadata.

## 15. Required tests

### Unit tests
- Identifier normalization/validation.
- Account-state policies.
- Role-assignment policy.
- Verification challenge expiry/consumption if implemented.
- Authentication-related safe error mapping.

### Integration tests
- Registration success and duplicate attempt.
- Login and logout.
- Session-status response.
- Session expiry/revocation behavior.
- CSRF and cookie behavior in the deployed origin model.
- Rate-limiting behavior.
- Suspended account cannot use protected APIs.
- Public registration cannot grant privileged role.
- Recovery flow does not expose private secrets.

### Authorization tests
- Anonymous caller denied private access.
- Customer cannot read another customer's address/order.
- Seller cannot access another seller's records.
- Non-admin cannot access admin routes.
- Support access is restricted according to permissions.
- Modified user ID/role fields do not bypass checks.

## 16. Acceptance checklist

- [ ] Approved login method documented.
- [ ] Identity framework/configuration is consistent.
- [ ] No duplicate password store exists.
- [ ] Browser session configuration is secure and tested.
- [ ] CSRF/CORS behavior is validated for actual deployment origins.
- [ ] Registration cannot grant privileged roles.
- [ ] Account status is enforced server-side.
- [ ] Abuse controls are active.
- [ ] Errors avoid account enumeration where relevant.
- [ ] Sensitive values are excluded from logs.
- [ ] Customer/seller resource-ownership tests pass.
- [ ] Account recovery and verification rules are approved.
- [ ] Documentation reflects actual implemented behavior.

## 17. Dependencies and completion gate

This feature is a prerequisite for customer profiles, seller onboarding, orders, messaging and administration.

Authentication is complete only when the chosen login flow works end-to-end and the security tests demonstrate that private resources cannot be accessed by the wrong actor. A frontend-only sign-in screen does not count as complete.
