# BUILD MATE — Feature Development Workflow and Roadmap

**Document ID:** BM-FEATURE-DEV-001  
**Version:** 1.0  
**Status:** Required development workflow  
**Last updated:** 26 October 2026

---

## 1. Purpose

This document defines how BUILD MATE should be developed feature by feature. It gives developers and AI coding agents a reliable implementation order, dependency rules, acceptance gates and change-control process.

The purpose is to avoid a common failure mode: building many attractive screens before authentication, data integrity, seller eligibility, order rules and privacy have been implemented.

## 2. Development principles

1. Build complete vertical slices rather than large disconnected layers.
2. Start with stable foundations and work outward through dependencies.
3. Complete authorization, validation, persistence and tests alongside the UI.
4. Prefer a modular monolith for the MVP.
5. Keep a single source of truth for order statuses, prices and permissions.
6. Do not implement unapproved legal, payment or commercial assumptions.
7. Keep external integrations behind replaceable adapters.
8. Deliver in small changes that can be built, tested, reviewed and reverted.
9. Do not treat mock data as proof of marketplace success.
10. Measure real fulfilment and economics before scaling.

## 3. Mandatory domain constraints

Every task must preserve these constraints unless the product owner approves a formal change:

- A listing bundles material and delivery from one seller.
- No separate truck-owner workflow exists in MVP.
- An MVP order references one customer, one seller and one listing.
- Public customer-facing listing APIs do not expose seller private phone/email/personal WhatsApp.
- The backend calculates totals and owns state transitions.
- Confirmed order terms and price are snapshotted.
- Seller verification, account status and listing moderation are distinct concepts.
- Failed external operations are not presented as successes.
- No fake ratings, verification, inventory, delivery estimates or transactions.

## 4. Feature delivery lifecycle

Every feature follows this lifecycle.

### Stage 1 — Clarify the contract
Read the relevant feature specification and its dependencies. Identify:
- Actor and permissions.
- Primary user journey.
- Domain rules.
- API changes.
- Database changes.
- External dependencies.
- Error/empty/loading states.
- Acceptance criteria.
- Business-owner decisions still open.

Record a question for any unapproved high-impact behavior.

### Stage 2 — Prepare the implementation plan
Create a bounded plan that identifies:
- Frontend files.
- Backend/domain/application files.
- Persistence/migration changes.
- API DTO/contract changes.
- Authorization/privacy implications.
- Tests.
- Documentation changes.

### Stage 3 — Implement the backend contract
Where required, implement:
- Domain/application rules.
- Validation.
- Authorization and resource ownership.
- Persistence and transaction boundaries.
- API DTOs and endpoints.
- Error codes and safe logging.
- Unit/integration tests.

Do not expose a UI action that the backend cannot enforce correctly.

### Stage 4 — Implement the UI
Implement:
- Intended page/component.
- API client integration.
- Field labels and validation feedback.
- Loading, empty, error and permission states.
- Responsive behavior and keyboard accessibility.
- Safe retry behavior for operations that may already have succeeded.

### Stage 5 — Test and review
Run relevant backend/frontend checks and review the final diff for:
- Inconsistent business rules.
- Missing resource checks.
- Contact-data leakage.
- Duplicate mutation paths.
- Unhandled provider failures.
- Missing migrations.
- Missing tests.
- Unrelated changes.

### Stage 6 — Integrate and document
Update API docs, database docs, feature status, environment setup and the document manifest as appropriate. Do not mark a feature complete until all acceptance criteria are tested or explicitly recorded as blocked.

## 5. Recommended implementation order

The order below is dependency-aware. A practical deployment may combine related tasks, but the dependencies must remain satisfied.

### Phase 0 — Repository and engineering foundation

**Scope**
- Repository structure.
- Frontend and backend projects.
- PostgreSQL connection and EF Core migrations.
- Central configuration and secret handling.
- API health, global error handling and correlation IDs.
- Logging with redaction.
- CI build/test pipeline.

**Dependencies:** None.

**Completion gate**
- Local setup works.
- Frontend and backend build.
- Database migrations run against test/development PostgreSQL.
- No production secrets are tracked.
- CI can report reproducible failures.

### Phase 1 — Authentication and sessions

**Scope**
- Identity configuration.
- Login/logout and session handling.
- Registration and verification according to approved flow.
- Account status and roles.
- Customer/seller route protection.
- CSRF, CORS and rate limits.
- Ownership/role authorization tests.

**Dependencies:** Phase 0.

**Completion gate**
- Authenticated sessions work.
- Anonymous private access is denied.
- Customer A cannot access Customer B's resources.
- Role assignment cannot be self-manipulated.
- Sessions and error responses follow the approved security policy.

### Phase 2 — Customer profile and addresses

**Scope**
- Customer profile.
- Address CRUD and default address.
- Validation and ownership.
- Address snapshots used by later orders.

**Dependencies:** Phases 0–1.

**Completion gate**
- Address ownership is enforced.
- Only one default address exists per customer.
- Existing records are not silently changed by later address edits.
- Exact-address data is not exposed publicly.

### Phase 3 — Seller onboarding and verification

**Scope**
- Seller application/profile.
- Verification document upload/access controls.
- Seller verification states.
- Admin review and decision audit.
- Seller activation/suspension controls.

**Dependencies:** Phases 0–1; private object storage can be mocked initially.

**Completion gate**
- Seller cannot publish an orderable offer before required approval.
- Documents are private.
- Admin decisions are audited.
- Public seller data is an explicit allowlisted DTO.

### Phase 4 — Material catalog and bundled listings

**Scope**
- Material categories/specifications.
- Listing create/edit/pause/draft/submit.
- Moderation workflow.
- Quantity/unit and capacity rules.
- Fixed delivered price versus quote mode.
- Public listing-media pipeline.
- Availability freshness.

**Dependencies:** Phases 0–3.

**Completion gate**
- Material and delivery are always bundled for an orderable listing.
- Invalid units, quantities and pricing combinations are rejected.
- Only eligible approved listings become public/orderable.
- Listing edits do not change confirmed orders.

### Phase 5 — Search and filtering

**Scope**
- Search API.
- Category/location/date/quantity filters supported by the MVP.
- Allowlisted sorting.
- Stable pagination.
- Search result and detail pages.
- Empty/error/loading states.

**Dependencies:** Phase 4.

**Completion gate**
- Search results reflect actual eligibility and availability rules.
- No public private-contact fields are returned.
- Filters validate inputs and remain bounded.
- Core queries are tested against PostgreSQL.

### Phase 6 — Order submission and seller response

**Scope**
- Price revalidation.
- Idempotent order submission.
- Order/address/commercial snapshots.
- Seller accept/reject.
- Response deadline, once approved.
- Status history and audit records.
- Cancellation rules, once approved.

**Dependencies:** Phases 0–5.

**Completion gate**
- No client-supplied total is trusted.
- Retries do not create duplicate orders.
- Every order has one customer, one seller and one listing.
- State transitions are enforced by backend policy.
- Capacity/concurrency risks are tested.

### Phase 7 — Order lifecycle and fulfilment

**Scope**
- Preparation/loading.
- Out-for-delivery.
- Delivery marking and evidence where approved.
- Customer confirmation/completion.
- Status timeline.
- Delay, cancellation and dispute states.

**Dependencies:** Phase 6.

**Completion gate**
- Only authorized actors can perform transitions.
- History is traceable.
- Delivery evidence is protected.
- Failed/exceptional flows have an operational handling path.

### Phase 8 — Messaging and platform-mediated communication

**Scope**
- Order/enquiry threads.
- Participant authorization.
- Message moderation/reporting basics.
- Contact-detail leakage safeguards and policy.
- Admin/support access.

**Dependencies:** Phases 1 and 6.

**Completion gate**
- Only thread participants and authorized case staff can read/write.
- Public contact details remain hidden.
- Message abuse and support escalation have documented behavior.
- Messaging failure states are visible.

### Phase 9 — Notifications

**Scope**
- Durable outbox.
- Background worker.
- Notification templates.
- Mock SMS/email/WhatsApp adapters.
- Retry and failure visibility.
- User preferences and required consent.

**Dependencies:** Phases 0 and 6.

**Completion gate**
- Order and outbox records are transactionally aligned where practical.
- Retries are bounded and idempotent.
- Failed sends do not appear successful.
- Sensitive data is minimized in message bodies and logs.

### Phase 10 — SMS, WhatsApp Business and masked calling

**Scope**
- Provider selection.
- Provider adapter and credentials.
- Template/configuration requirements.
- Webhook/callback validation.
- Consent/opt-out behavior.
- Masked-call participant authorization and privacy testing.

**Dependencies:** Phases 8–9; business/provider approval.

**Completion gate**
- Provider success/failure is accurately tracked.
- Relevant compliance and consent requirements are reviewed.
- Masked-calling behavior has been tested from both parties' perspective.
- No direct-contact fallback leaks numbers.

### Phase 11 — Payments, refunds, fees and reconciliation

**Scope**
- Approved payment flow.
- Provider verification.
- Payment state and webhook idempotency.
- Fee-policy snapshot.
- Refunds and ledger/reconciliation.
- Admin privileges and audit.

**Dependencies:** Phase 6; approved commercial/legal/operational policy.

**Completion gate**
- No fee rate or payment policy has been silently assumed.
- Payment and order statuses remain separate.
- Duplicate callbacks do not double-apply payment.
- Refund/reconciliation failures are visible and actionable.
- Financial actions are audited.

### Phase 12 — Reviews, support and moderation

**Scope**
- Eligible completed-order review.
- Review moderation.
- Support tickets and assignments.
- Complaint/dispute resolution.
- Seller/listing reports and abuse handling.

**Dependencies:** Phases 3, 6–8.

**Completion gate**
- Reviews are tied to real eligible orders.
- Support access respects case permissions.
- Outcomes and privileged overrides are audited.

### Phase 13 — Admin reporting and operational readiness

**Scope**
- Operational dashboard.
- Listing freshness.
- Order and provider failure reports.
- Export controls.
- Monitoring, incident response and backup/restore.
- Pilot KPI definitions.

**Dependencies:** Stable underlying domains and audited records.

**Completion gate**
- Reports use documented metric definitions.
- Exports are restricted.
- Operations can identify and manage failures.
- Recovery/rollback procedures have been tested.

### Phase 14 — Pilot and scale decision

**Scope**
- Controlled launch.
- Real seller/customer onboarding.
- End-to-end delivery operations.
- KPI review.
- Product-owner go/no-go decision.

**Dependencies:** All P0 and safety-critical release gates.

**Completion gate**
- Privacy/security issues have no unresolved critical blockers.
- Genuine orders have been completed and reviewed.
- Unit economics and operational workload are measured.
- Expansion is justified by evidence, not projected registrations alone.

## 6. Feature-specification map

The individual feature documents map to this roadmap:

1. `01-authentication-and-sessions.md`
2. `02-customer-profile-and-addresses.md`
3. `03-seller-onboarding-and-verification.md`
4. `04-material-listings-and-delivery-capacity.md`
5. `05-search-and-filtering.md`
6. `06-order-quote-and-checkout.md`
7. `07-order-lifecycle-and-delivery-status.md`
8. `08-contact-privacy-platform-messaging-masked-calling.md`
9. `09-sms-notifications.md`
10. `10-whatsapp-business.md`
11. `11-payments-refunds-and-reconciliation.md`
12. `12-commissions-and-fees.md`
13. `13-reviews-and-ratings.md`
14. `14-support-complaints-disputes.md`
15. `15-admin-dashboard-and-moderation.md`
16. `16-media-uploads.md`
17. `17-analytics-and-reporting.md`
18. `18-audit-logging-and-privacy.md`
19. `19-seo-performance-accessibility.md`

When a feature has dependencies on more than one phase, follow the strictest dependency and do not assume the numbered filenames alone define implementation order.

## 7. Definition of ready

A feature is ready to start when:
- User story and scope are understood.
- Upstream dependencies exist or have an agreed interface.
- Acceptance criteria are testable.
- Role/ownership behavior is defined.
- Data/API impacts are identified.
- High-impact business decisions are approved.
- Test approach is understood.
- Required provider credentials are either available in a controlled environment or a mock path is specified.

## 8. Definition of done

A feature is done only when:
- The stated journey works end-to-end where the acceptance criteria require it.
- Backend validation and domain rules are implemented.
- Authorization and privacy tests pass.
- Database changes have a reviewed migration, if applicable.
- Main success and failure paths are tested.
- Loading/empty/error UI is implemented.
- Provider failures are correctly surfaced.
- Relevant docs/API schemas are updated.
- No secret/private-data leakage was introduced.
- Actual validation results and remaining limitations are reported.

## 9. Work-item template

Use this format for each implementation task:

### Title
A single user-visible capability or bounded technical change.

### User value
Why this task is needed.

### Preconditions
Required upstream functionality or approvals.

### Scope
Included behavior and explicit exclusions.

### Business rules
Rules the implementation must preserve.

### API/data changes
Endpoints, DTOs, schema and state changes.

### Authorization/privacy
Who can do what and which fields are private.

### Acceptance criteria
Observable, testable behavior.

### Tests
Unit, integration, browser, provider and security tests.

### Documentation
Files that need updates.

### Owner decisions
Unresolved decisions that block or constrain delivery.

## 10. Change-control rules

- Keep changes focused and reviewable.
- Avoid unrelated refactoring during feature delivery.
- Never delete a failing test merely to make CI pass.
- Record architecture changes in an ADR.
- Update dependent documents when a requirement changes.
- Avoid destructive migrations without an explicit review.
- Do not enable production integrations while their policies remain unapproved.
- Document partial completion honestly.

## 11. Product-owner decision register

Maintain an explicit decision log for:
- Pilot service area.
- Supported quantities and units.
- Fixed delivered price versus quote rules.
- Guest/login checkout policy.
- Seller verification evidence.
- Response/cancellation/dispute time limits.
- Delivery proof requirements.
- Pilot payment and cash/UPI handling, if any.
- Platform fee rate and paying party.
- SMS/WhatsApp/telephony/payment/storage providers.
- Privacy and retention rules.
- Hosting, budget and production operation responsibilities.

**Rule:** An AI agent may recommend an option, but it must not embed an unapproved commercial or legal rule in a way that becomes difficult to change.
