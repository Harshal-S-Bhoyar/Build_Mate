# BUILD MATE — Testing, Quality Assurance and Debugging

**Document ID:** BM-QA-001  
**Version:** 1.0  
**Status:** Required quality baseline  
**Last updated:** 26 October 2026

---

## 1. Purpose

This document defines the testing and debugging approach for BUILD MATE. Testing must validate business correctness, privacy, authorization, data integrity, usability and operational failure handling—not merely whether pages render or the API returns `200 OK`.

## 2. Quality objectives

1. Prevent unauthorized access to customer, seller, order and document data.
2. Prevent fake totals, duplicate orders, invalid transitions and stale-price errors.
3. Verify the bundled material-plus-delivery model.
4. Validate database constraints and migrations using PostgreSQL.
5. Ensure the customer, seller and admin journeys work across frontend and backend.
6. Confirm external integration failures remain visible and recoverable.
7. Make failures reproducible and diagnosable.
8. Block releases with unresolved critical/high-risk issues.

## 3. Testing layers

### 3.1 Domain unit tests
Use xUnit for backend domain rules that can be tested without HTTP or a database.

Examples:
- Quantity must meet listing minimum.
- Unit/category combination is valid.
- An orderable listing includes delivery.
- Fixed-price mode requires a valid delivered price.
- Only allowed status transitions succeed.
- A seller cannot update an unrelated order.
- Fee snapshots do not change after a policy change.
- A review is allowed only when eligibility conditions are satisfied.

These tests should be deterministic and fast. Do not call live external services.

### 3.2 Application/use-case tests
Test use-case orchestration, including:
- Seller onboarding and verification.
- Listing submission and moderation.
- Order submission and snapshot generation.
- Cancellation and exception handling.
- Outbox creation and notification scheduling.
- Payment webhook deduplication, if implemented.
- Audit creation for sensitive actions.

Mock ports at application boundaries where practical, but do not use mocks as a substitute for database-specific integration tests.

### 3.3 API integration tests
Use ASP.NET Core integration-test support, such as `WebApplicationFactory`, with isolated test configuration.

Test:
- Routes, DTO serialization and validation.
- Cookie/session or approved authentication behavior.
- Role and resource ownership policies.
- Error contracts and status codes.
- Pagination and filter limits.
- Request idempotency.
- Public response privacy.
- Invalid transitions and concurrency conflicts.

### 3.4 Database integration tests
Use real PostgreSQL in a disposable test environment when validating:
- EF Core mappings.
- Numeric precision.
- Foreign keys and unique constraints.
- Partial indexes.
- Transactions and rollback.
- Concurrency strategy.
- Migrations.
- PostgreSQL-specific queries and JSONB use.

Do not assume EF Core InMemory or an unrelated database provider proves PostgreSQL behavior.

### 3.5 Frontend unit/component tests
Use Vitest and the selected React testing utilities where appropriate.

Test:
- Form field behavior and validation display.
- Currency/quantity formatting.
- Loading/empty/error states.
- Order-state display.
- Hidden/private fields not rendered on public components.
- Accessible labels and interactive control states.
- API client error mapping.
- Safe retry behavior.

Avoid testing implementation details that make harmless refactoring unnecessarily difficult.

### 3.6 Browser end-to-end tests
Use Playwright for high-value user journeys against an isolated test environment.

Recommended primary journeys:
1. Customer browses categories and searches for a delivered load.
2. Customer opens listing detail and reviews pricing/terms.
3. Customer submits an order using a test address.
4. Seller views and accepts the order.
5. Seller updates permitted order status.
6. Customer sees status progress and can access support.
7. Admin approves a seller and moderates a listing.
8. Unauthorized user is denied access to another user's private resource.
9. Provider failure is displayed honestly.
10. Customer can navigate the primary flow with keyboard controls.

Tests must use synthetic users/orders and fake provider integrations by default.

## 4. Test environments

Keep environments separate:

- **Local development:** fast feedback, synthetic seed data, mocked providers.
- **Automated test:** isolated DB/data, deterministic dependencies and no live customer data.
- **Staging:** production-like configuration and controlled integration tests.
- **Production:** real customer data, restricted access, monitored changes and no destructive testing.

Do not use production credentials in CI. Do not let a test suite wipe a shared database.

## 5. Test-data strategy

Build reusable synthetic fixtures:
- Customer A and Customer B.
- Seller A and Seller B.
- Admin and support users with distinct permissions.
- Verified and pending sellers.
- Active, paused, expired and rejected listings.
- Fixed-price and quote-required listings.
- Listings with different supported units/capacities.
- Orders in each lifecycle state.
- Failed and successful notification/payment events.
- Support tickets with different assignments.

Seed data must not create the impression of real verification, genuine reviews, live inventory or actual sales. Tests must be repeatable and must reset their own data safely.

## 6. Core domain test matrix

| Area | Positive tests | Negative/edge tests |
|---|---|---|
| Authentication | Valid approved login flow | Invalid credentials, expired challenge, rate limit |
| Authorization | User accesses own data | Wrong user, wrong seller, wrong role |
| Seller verification | Approved seller can publish if all checks pass | Pending/suspended seller cannot publish/orderably list |
| Listing | Valid bundled offer becomes eligible after approval | Delivery excluded, invalid quantity/unit, invalid price |
| Search | Matching eligible offer appears | Paused, expired, unapproved, out-of-area offer excluded |
| Order | Valid request creates one order | Price tampering, stale listing, duplicate retry, wrong address |
| Capacity | One valid order consumes capacity according to policy | Concurrent requests exceed available capacity |
| Lifecycle | Allowed transitions succeed | Skipped, repeated or unauthorized transitions fail |
| Privacy | Public DTO contains approved fields | Private phone/email/address/document fields leak |
| Messaging | Authorized participant sends/reads | Non-participant tries to access thread |
| Notifications | Outbox event is processed and recorded | Timeout/retry exhaustion is visible |
| Payments | Valid verified event is applied once | Forged/duplicate/out-of-order event |
| Reviews | Eligible completed customer can review | Unrelated or incomplete order review rejected |
| Administration | Authorized change succeeds and is audited | Unauthorized change denied; missing reason rejected where required |

## 7. Mandatory security and privacy tests

### 7.1 Cross-account resource access
For each private route, attempt access with:
- No session.
- Customer A accessing Customer B.
- Seller A accessing Seller B.
- Seller attempting customer/admin operations.
- Support user accessing an unassigned case.
- Admin without a required restricted permission.

Check that the response does not leak resource data through the body, error detail, metadata or logs.

### 7.2 Public DTO privacy tests
For public listing/search endpoints, explicitly assert that responses do not contain disallowed fields such as:
- Private phone number.
- Private email.
- Personal WhatsApp number or URL.
- Private delivery/customer address.
- Payout/banking data.
- Verification-document storage key or download URL.
- Internal moderation notes.
- Private order data.

Test both raw JSON and the frontend output. A field being hidden by CSS does not count as privacy protection.

### 7.3 Pricing/integrity tests
Send manipulated request bodies containing:
- Fake total.
- Fake seller ID.
- Fake fee/tax amount.
- Fake order status.
- Invalid unit/quantity.
- An expired or paused listing ID.
- An address ID belonging to another customer.

Confirm that the server ignores or rejects untrusted values and uses current authorized state.

### 7.4 Abuse and transport tests
Test rate limiting, request size limits, upload validation, session expiry, anti-CSRF behavior, CORS configuration, error redaction and provider callback authentication where applicable.

## 8. Order-state test matrix

Use the canonical states in `DRD.md` and `Database.md`:
- `PendingSellerResponse`
- `Accepted`
- `Preparing`
- `OutForDelivery`
- `Delivered`
- `Completed`
- `Rejected`
- `Cancelled`
- `Disputed`

For every implemented transition, test:
1. Valid actor and source state.
2. Invalid actor.
3. Invalid source state.
4. Missing required evidence/fields.
5. Concurrent attempt or repeated request.
6. State-history creation.
7. Outbox/audit behavior where required.
8. Safe API error contract.
9. Correct UI behavior after success and failure.

Terminal-state overrides must go through an explicitly authorized, audited workflow. Ordinary endpoints must not reopen terminal orders.

## 9. API and contract tests

Maintain tests that verify:
- HTTP status and response shape.
- Public/private DTO separation.
- Pagination limits.
- Date/timezone semantics.
- Stable enum values.
- Correct `400`, `401`, `403`, `404`, `409`, `413`, `429` behavior where applicable.
- Correlation ID behavior.
- Idempotency responses for the same and mismatched request.
- OpenAPI reflects implemented endpoints.

Avoid asserting exact internal exception messages. Assert stable public error codes and expected semantics.

## 10. Frontend usability and accessibility QA

Validate:
- Correct labels, validation summaries and field-level errors.
- Visible keyboard focus.
- Logical tab order.
- Dialog open/close/focus return behavior.
- Keyboard-operable navigation and dropdowns.
- Sufficient text/control contrast.
- Status communicated by text, not color alone.
- Narrow-screen layouts without unintended horizontal overflow.
- Zoom and enlarged text behavior.
- Loading/error/empty states.
- Reduced-motion preference where animations exist.
- Accessible status announcements for asynchronous changes.

Automated accessibility tools can find issues, but manual keyboard testing and representative screen-reader testing are still needed.

## 11. Performance and reliability checks

The MVP does not need a large-scale load test program on day one, but it should have measurable baselines.

Check:
- Search pagination and query plans.
- Slow API operations and excessive DB queries.
- Unbounded list endpoints.
- N+1 query patterns.
- Large/unbounded uploads.
- Request timeout behavior.
- Notification outbox backlog handling.
- Application behavior when PostgreSQL becomes unavailable.
- Provider timeout and recovery behavior.
- Memory/cpu/resource stability under a representative modest load.

Use query plans and measured traffic before adding caching or infrastructure. Do not introduce Redis solely because a generic architecture template recommends caching.

## 12. Suggested developer commands

Run from the appropriate repository directory after scripts/projects are configured.

Backend, from `backend/`:

```bash
dotnet restore
dotnet build
dotnet test
```

Frontend, from `web/`:

```bash
npm ci
npm run lint
npm run typecheck
npm run test
npm run build
```

Browser E2E testing, once configured:

```bash
npm run test:e2e
```

Add the `typecheck`, `test` and `test:e2e` scripts as actual project scripts. If a script fails or does not exist, report that accurately rather than treating the command as passed.

## 13. Debugging workflow

### Step 1 — Reproduce
- Capture exact steps and safe input.
- Record expected vs actual behavior.
- Note environment, browser/runtime and relevant version.
- Confirm whether the issue is repeatable.

### Step 2 — Collect safe evidence
Use:
- Correlation ID.
- Request method/path and status.
- Redacted server logs.
- Relevant test output.
- Migration status.
- Provider request reference where safe.
- Browser console/network details with tokens and private values removed.

Never copy unredacted production cookies, OTPs, payment secrets, verification documents or private customer addresses into bug reports.

### Step 3 — Locate the failing layer
Check in order:
1. Browser state and API request.
2. Network origin/CORS/session/CSRF.
3. API validation and authorization.
4. Application/domain rule.
5. EF Core transaction/query.
6. PostgreSQL constraints, connection or migration.
7. Outbox/background worker.
8. External provider behavior.

Follow the correlation ID across layers where supported.

### Step 4 — Write a regression test
Create the smallest test that reproduces the failure at the correct layer. A bug fix without a regression test should have a documented reason.

### Step 5 — Fix the cause
Avoid swallowing exceptions, bypassing validation, disabling security or hardcoding special cases. Fix the underlying invariant and add tests for adjacent failure modes.

### Step 6 — Verify the fix
Run the focused test, related integration tests and broader affected test suite. Inspect the diff for unintended changes.

### Step 7 — Document
Record root cause, fix, affected versions/data, test evidence and any follow-up work.

## 14. Frequent problem playbook

### Database connection failure
- Check PostgreSQL availability and container health.
- Verify local connection settings without exposing the password.
- Confirm API environment/configuration source.
- Verify network host/port and DB identity privileges.
- Check whether migrations were applied.

### Migration failure
- Inspect the migration and failing SQL.
- Check entity/configuration and schema history.
- Validate precision, nullability, constraints and data backfill.
- Test against a disposable database.
- Do not delete applied migrations to conceal the failure.

### Frontend/API mismatch
- Inspect the actual request and sanitized response.
- Compare frontend types with DTO/OpenAPI.
- Check JSON naming and enum values.
- Ensure the frontend handles non-2xx responses.
- Update contract tests and documentation.

### Authentication loop or 401
- Verify cookie attributes and actual deployment origins.
- Check session expiry/revocation.
- Validate anti-CSRF flow for state-changing requests.
- Inspect CORS and credential configuration.
- Ensure no access token is incorrectly stored in localStorage.
- Do not weaken cookie or authorization policy as a quick fix.

### Order duplicated
- Inspect idempotency key and request hash.
- Verify unique constraints and transaction handling.
- Check UI retry behavior.
- Confirm event/provider processing is idempotent.
- Add a regression test for timeout/retry conditions.

### Provider message/call failure
- Inspect the provider error code/reference and safe logs.
- Confirm environment credentials and sender/template configuration.
- Determine whether the error is transient or permanent.
- Verify bounded retry and dead-letter/failure visibility.
- Never report success from a timeout or failed provider response.

### Private information leak
- Disable or restrict the affected route/feature where necessary.
- Preserve relevant audit logs safely.
- Identify the affected DTO, log, storage key or UI.
- Rotate exposed secrets if any.
- Limit further disclosure and escalate to the incident process.
- Fix the boundary, add regression tests and assess notification obligations with the responsible adviser.

## 15. Defect severity

| Severity | Meaning | Example |
|---|---|---|
| Critical | Active or credible severe compromise, financial integrity failure, or unauthorized exposure of sensitive data at scale | Cross-account private data access |
| High | Major core flow failure or significant security/privacy flaw | Seller can alter an unrelated order |
| Medium | Important feature impaired with a workaround | Search filter returns incorrect eligible set |
| Low | Minor visual/content issue with little functional impact | Small spacing inconsistency |

Severity assignment should consider actual exposure and impact, not only this illustrative table.

## 16. Release gates

### Gate A — Development
- Code compiles.
- Relevant unit tests pass.
- No known unhandled failure in the implemented path.

### Gate B — Integration
- API and database tests pass.
- Migrations apply.
- Role/resource checks pass.
- Provider failure behavior is tested with mocks.

### Gate C — Controlled pilot
- Critical browser journeys pass.
- Public-contact privacy tests pass.
- Order price/snapshot/idempotency rules pass.
- Support/cancellation policies are ready.
- Monitoring and rollback procedures exist.

### Gate D — Expansion
- No unresolved critical security/privacy defect.
- Pilot reliability and genuine fulfilment metrics have been reviewed.
- Contribution and operational workload support expansion.
- Backups/restoration and incident response are verified.

## 17. Test reporting template

### Feature/Release
Name and tested version/commit.

### Environment
Local, test, staging or production-safe check.

### Commands executed
Exact commands and actual results.

### Scenarios tested
Successful, invalid, unauthorized, concurrent and failure cases as applicable.

### Findings
Severity, reproducibility and impact.

### Remaining gaps
Tests not run, environment unavailable, provider not configured or decisions awaiting approval.

## 18. Exit criteria

A feature/release may be marked complete only when the agreed acceptance criteria are satisfied, appropriate tests have actually passed, high-risk security/privacy behaviors are verified, migrations are reviewed, external failures are handled, and all remaining limitations are disclosed.
