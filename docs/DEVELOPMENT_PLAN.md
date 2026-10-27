# BUILD MATE — Project Development Plan

**Version:** 1.0  
**Status:** Working implementation plan  
**Product:** BUILD MATE construction-material marketplace  
**Initial pilot:** Selected service area in Nagpur, Maharashtra

## 1. Purpose

This document defines the recommended development sequence for BUILD MATE. It is intended for the project owner, human developers, and AI coding agents such as OpenCode.

The project must be implemented in small, testable phases. Do not ask an AI coding agent to build the entire product in one prompt. Each phase should produce a working, reviewable checkpoint before the next phase begins.

This plan supplements the product and technical specifications. Where a requirement conflicts with another document, identify the conflict and obtain a decision rather than silently choosing an implementation.

## 2. Product Rules That Must Remain Consistent

1. An orderable listing bundles construction material and delivery from the same seller.
2. In the MVP, one order references one customer, one seller, and one orderable listing.
3. Public listing and search responses must not expose private seller contact details.
4. Customer delivery addresses and other personal data must be visible only to authorized parties when needed for fulfillment.
5. The backend is the authority for business rules, authentication, authorization, order states, and data access.
6. UI validation does not replace server-side validation.
7. Payment, commission, cancellation, refund, dispute, and service-fee policies must be approved before they are implemented as business rules.
8. SMS, WhatsApp, payment gateway, and masked-calling integrations are not considered operational until the relevant provider is selected, configured, tested, and approved.
9. External provider calls must not be made while holding a database transaction open. Use a documented asynchronous workflow or outbox where appropriate.
10. Test data and local configuration must never contain real customer data, production secrets, or production credentials.

## 3. Canonical Technical Baseline

Use this baseline unless a documented architecture decision changes it:

| Area | Selected baseline |
|---|---|
| Frontend | Next.js App Router + TypeScript |
| UI styling | Tailwind CSS |
| Frontend validation | Zod |
| Backend | ASP.NET Core Web API with C# |
| Runtime | .NET 10 LTS |
| ORM | Entity Framework Core 10 |
| PostgreSQL provider | Compatible Npgsql EF Core provider |
| Database | PostgreSQL |
| DB administration | pgAdmin 4 |
| Backend tests | xUnit |
| Frontend unit/component tests | Vitest |
| Browser end-to-end tests | Playwright |
| API contract | OpenAPI |
| Logging | Structured logging; Serilog if selected and configured |
| Async processing | PostgreSQL-backed outbox and worker where required |
| Authentication | Secure cookie-based browser sessions, subject to the approved authentication specification |
| Source control | Git |
| CI | Repository-approved CI platform |

### 3.1 Stack consistency rules

- Do not use Prisma as the backend ORM in this ASP.NET Core baseline.
- Do not connect the browser or Next.js client-side code directly to PostgreSQL.
- Do not add Redis, a message broker, microservices, or other infrastructure unless there is a documented requirement and an approved decision record.
- If older documents describe a different ORM, authentication approach, status model, or API envelope, record the conflict and resolve it before implementing the affected feature.
- Use package versions that are mutually compatible. Confirm the exact installed SDK and package versions in the repository.

## 4. Repository Preparation

Recommended monorepo structure:

```text
build-mate/
├── AGENTS.md
├── README.md
├── .gitignore
├── .editorconfig
├── docs/
│   ├── DEVELOPMENT_PLAN.md
│   ├── DOCUMENT-MANIFEST.md
│   ├── BRD.md
│   ├── PRD.md
│   ├── DRD.md
│   └── ...
├── frontend/
│   ├── package.json
│   └── src/
├── backend/
│   ├── BuildMate.sln
│   ├── src/
│   │   ├── BuildMate.Api/
│   │   ├── BuildMate.Application/
│   │   ├── BuildMate.Domain/
│   │   └── BuildMate.Infrastructure/
│   └── tests/
│       ├── BuildMate.UnitTests/
│       └── BuildMate.IntegrationTests/
├── deployment/
└── .github/workflows/
```

Use the actual filenames and paths that already exist. Do not duplicate, overwrite, or rename existing documentation without checking references first.

## 5. Implementation Overview

| Phase | Main objective | Must be completed before |
|---|---|---|
| 0 | Repository and documentation audit | Any significant code changes |
| 1 | Technical foundation: frontend, API, database connectivity, CI | Database-backed features |
| 2 | Domain model, EF Core schema, migrations, reference data | Features relying on persistent entities |
| 3 | Authentication, sessions, roles, authorization | Protected account workflows |
| 4 | Seller onboarding and verification | Seller listing publication |
| 5 | Material catalog, listings, search, and filters | Customer order workflow |
| 6 | Order creation, lifecycle, history, and delivery status | Communications that depend on order events |
| 7 | Privacy-safe in-platform communication and notification outbox | External messaging rollout |
| 8 | Admin moderation, media handling, support, and audit | Controlled pilot operations |
| 9 | Payments, fees, commissions, refunds, and reconciliation | Only after policies are approved |
| 10 | Analytics, accessibility, performance, security review, deployment, and pilot | Public pilot release |

Testing, privacy checks, code review, documentation updates, and Git checkpoints are required throughout all phases; they are not deferred to Phase 10.

---

## 6. Phase 0 — Repository and Documentation Audit

### Objective

Understand the actual repository and establish one reliable source of truth before implementation.

### Tasks

1. Inspect the repository, current branches, working tree, existing source code, scripts, and installed tooling.
2. Locate `AGENTS.md`, `DOCUMENT-MANIFEST.md`, `BRD.md`, `PRD.md`, `DRD.md`, and all referenced technical documents.
3. Compare the documents for conflicts, especially:
   - Prisma versus Entity Framework Core.
   - Cookie sessions versus JWT-only browser authentication.
   - API response envelope and error format.
   - Entity names, database relationships, and order states.
   - Public versus private seller/customer fields.
   - Payment, commission, cancellation, refund, and dispute rules.
4. Create a concise decision register for conflicts and missing business decisions.
5. Confirm the package-manager choice and the local database approach.
6. Check that `.gitignore` excludes build output, `.env` files, credentials, and local artifacts.
7. Do not implement product features in this phase.

### Deliverables

- Repository inventory.
- Documentation inventory.
- Conflict and risk register.
- Proposed architecture decisions for owner approval.
- Phase 1 implementation task list.

### Exit criteria

- The agent can identify the authoritative requirements and technical stack.
- High-impact contradictions are documented.
- No existing working code or documentation has been overwritten unnecessarily.
- The owner approves unresolved decisions that materially affect architecture.

---

## 7. Phase 1 — Technical Foundation

### Objective

Get the frontend, backend API, and PostgreSQL running together locally with repeatable setup and automated checks.

### Tasks

1. Create or complete the Next.js App Router project with strict TypeScript settings.
2. Create or complete `BuildMate.sln` and the four Clean Architecture projects.
3. Add the approved PostgreSQL local development setup, such as Docker Compose if chosen.
4. Add configuration templates and a clear local setup guide. Do not commit credentials.
5. Register the EF Core context and compatible Npgsql provider without introducing unrelated business entities.
6. Add basic liveness and readiness health endpoints.
7. Add centralized API exception handling and safe structured logging.
8. Add a simple frontend page that clearly identifies the BUILD MATE development app.
9. Add minimal backend and frontend tests.
10. Add repository scripts and basic CI for restore, build, lint, and tests where supported.
11. Add a development-only database connection check that does not disclose connection details.
12. Document commands to start and stop each service.

### Deliverables

- Running Next.js app.
- Running ASP.NET Core API.
- Reachable development PostgreSQL instance.
- Safe `.env.example` and backend configuration templates.
- Health endpoints.
- First automated tests and CI workflow.
- Local development instructions.

### Exit criteria

- Frontend starts successfully.
- API starts successfully.
- API can connect to the intended development database.
- Health endpoint reports expected status without exposing secrets.
- Frontend and backend build checks pass.
- Tests that can run locally pass; any blocked checks are documented honestly.
- First Git checkpoint is committed.

---

## 8. Phase 2 — Domain Model and Database Foundation

### Objective

Create the first intentional relational model and migration history before building workflows on top of it.

### Tasks

1. Model only entities supported by approved requirements.
2. Define primary keys, foreign keys, required fields, unique constraints, check constraints, and delete behavior.
3. Define storage conventions for timestamps, money, quantities, statuses, and identifiers.
4. Create EF Core entity configurations.
5. Add the initial migration and test it against a clean development database.
6. Seed required material categories: Black Stone, Sand, Bricks, and Murum.
7. Keep demo data separate from required reference data.
8. Add PostgreSQL integration tests for relationships and constraints.
9. Verify the schema using authorized local pgAdmin 4 access.
10. Document a safe migration workflow.

### Important rules

- Monetary calculations must not use binary floating-point values.
- Select one money storage convention and use it consistently. Integer paise is a possible INR baseline if approved; an explicitly defined `numeric` model is another option.
- Quantity precision and allowed units must follow catalog requirements.
- Keep order history consistent even when seller profiles or listings become inactive.
- Never apply a development migration to production by accident.

### Exit criteria

- Migrations can build a clean database from scratch.
- Seed operations are repeatable and do not create duplicate reference rows.
- Key constraints and relationships are tested against PostgreSQL.
- Money and quantity conventions are documented.
- A second Git checkpoint is committed.

---

## 9. Phase 3 — Authentication and Authorization

### Objective

Implement secure identity, sessions, roles, and resource-level permissions before protected marketplace workflows.

### Tasks

1. Confirm and implement the approved phone OTP or other sign-in workflow.
2. Add OTP expiry, attempt limits, throttling, and secure verification handling.
3. Never log or persist raw OTP values unnecessarily.
4. Configure secure session cookies, including `HttpOnly`, `Secure` in production, and an appropriate `SameSite` policy.
5. Implement CSRF/antiforgery protections for cookie-authenticated state-changing requests.
6. Define account status and role/permission behavior.
7. Implement backend authorization policies.
8. Enforce resource ownership for customer orders, seller listings, and private documents.
9. Add logout, expiry, revocation, and session-invalid behavior.
10. Use a development OTP provider or explicitly documented test mechanism until a real provider is approved.
11. Add tests for invalid credentials, expired OTPs, throttling, unauthorized access, and cross-account access attempts.

### Exit criteria

- Anonymous users cannot access protected endpoints.
- A customer cannot access another customer's private order.
- A seller cannot edit another seller's listing.
- Admin APIs require approved admin permissions.
- Cookie and antiforgery behavior is tested in the actual deployment pattern.
- No production OTP or signing secret is committed.

---

## 10. Phase 4 — Seller Onboarding and Verification

### Objective

Allow sellers to register, submit required business details, and reach an approved state before publishing eligible listings.

### Tasks

1. Build seller profile creation and editing.
2. Implement the documented verification-status model.
3. Build the seller application UI and backend endpoints.
4. Add protected upload references if seller documents are part of the approved workflow.
5. Add admin review capabilities or a minimal controlled verification operation.
6. Enforce which states permit listing creation or publication.
7. Audit sensitive administrative changes.
8. Test seller ownership and unauthorized state changes.

### Exit criteria

- Sellers can submit and view their own onboarding status.
- Unauthorized users cannot view another seller's private information.
- Unapproved sellers cannot perform actions that require approval.
- Verification decisions are traceable.

---

## 11. Phase 5 — Material Catalog, Listings, and Search

### Objective

Create the first usable marketplace experience for discovering materials and delivery offers.

### Tasks

1. Implement the four initial categories.
2. Build seller listing creation, editing, availability, publication, and withdrawal.
3. Store material and delivery terms as one orderable offer.
4. Define price, unit, minimum quantity, delivery coverage, and availability behavior from approved requirements.
5. Implement listing approval/moderation if required by the chosen launch policy.
6. Implement public search and category filters with bounded pagination.
7. Build responsive listing cards and listing-detail pages.
8. Use explicit public DTOs that omit private contact details.
9. Add indexes for verified search patterns through migrations.
10. Test search behavior, pagination, publication filtering, and privacy leakage.

### Exit criteria

- Eligible published listings can be browsed and filtered.
- Unpublished, suspended, or otherwise ineligible listings are excluded.
- Listing results clearly explain the material-and-delivery offer.
- Public endpoints do not expose private contact details or internal verification documents.
- No unbounded search endpoint is shipped.

---

## 12. Phase 6 — Order Creation and Lifecycle

### Objective

Enable a customer to request/order one listing and let the seller manage the order through approved states.

### Tasks

1. Finalize the order state machine and transition matrix from the relevant specification.
2. Define the customer's order submission fields and delivery details.
3. Validate listing availability, minimum quantity, and seller eligibility at order time.
4. Snapshot agreed listing, price, quantity, and delivery terms where required for historical accuracy.
5. Create the order and initial order-history event transactionally.
6. Enforce valid state transitions on the backend.
7. Add concurrency protection for conflicting updates.
8. Build customer order history and order detail.
9. Build seller order inbox and permitted status actions.
10. Add delivery-status reporting only where defined by the approved business rules.
11. Test duplicate submissions, race conditions, invalid transitions, and cross-account access.

### Exit criteria

- An order references exactly one customer, seller, and listing in the MVP.
- The order preserves the agreed offer terms needed for history.
- Invalid state transitions are rejected.
- Concurrent updates cannot silently overwrite each other.
- Customer and seller views expose only their authorized information.

---

## 13. Phase 7 — Communication and Notifications

### Objective

Keep communication controlled and deliver reliable order-related notifications without exposing private contacts publicly.

### Tasks

1. Implement the database-backed outbox with idempotent processing.
2. Record notification intent in the same transaction as the triggering business change when required.
3. Add retry policy, attempt count, next-available time, failure tracking, and safe observability.
4. Build in-platform messaging only if it is included in the approved MVP scope.
5. Select an SMS provider and implement a testable adapter before enabling SMS in production.
6. Select and approve a WhatsApp Business provider and message templates before enabling WhatsApp.
7. Evaluate masked calling only after provider capability, cost, privacy, and consent requirements are verified.
8. Redact private fields from notification payloads and logs.
9. Add tests for retries, duplicate events, provider failures, and authorization.

### Exit criteria

- A failed notification does not roll back a successfully committed order.
- Outbox retries do not create uncontrolled duplicate messages.
- Provider credentials are stored securely.
- Public listing/search responses continue to omit private contact data.
- Messaging integrations are clearly marked disabled when not configured.

---

## 14. Phase 8 — Admin, Moderation, Media, and Support

### Objective

Provide the operational controls required to supervise a limited pilot safely.

### Tasks

1. Build protected admin dashboard entry points.
2. Implement seller verification review and listing moderation.
3. Implement documented account/listing suspension actions.
4. Add audit events for privileged changes.
5. Implement secure media upload with file size limits, MIME/magic-byte checks, and storage access controls.
6. Keep private verification documents separate from public listing images.
7. Build support/complaint workflows and dispute states according to approved rules.
8. Add access control to support notes and private attachments.
9. Add safe operational search and reporting.
10. Test resource ownership, file validation, privilege escalation, and audit completeness.

### Exit criteria

- Admin endpoints require the correct authorization policy.
- Admin actions are audit logged without capturing secrets.
- Private documents are not publicly addressable.
- Unsupported file types and oversized uploads are rejected.
- Complaint and dispute workflows follow an explicitly approved state model.

---

## 15. Phase 9 — Payments and Commercial Features

### Objective

Implement commercial workflows only after the owner approves the required policies and provider decisions.

### Decisions required before coding

- Which payment methods are supported for the pilot: COD, manual UPI recording, online gateway, or a defined combination?
- Does the platform collect money or only record payment status?
- How are commissions or platform fees calculated?
- Who is charged, and when?
- What are the cancellation and refund rules?
- How are partial deliveries, partial refunds, failed payments, and disputes handled?
- What tax and accounting requirements apply?
- Which gateway and settlement/reconciliation process are approved?

### Tasks after decisions are approved

1. Model payment attempts and confirmed payment records separately where needed.
2. Use integer minor units or the approved exact-decimal strategy.
3. Validate gateway webhook signatures.
4. Make webhook handling idempotent.
5. Maintain a ledger or auditable transaction record if required by the approved model.
6. Implement commissions and fees according to approved written examples.
7. Implement refunds and reconciliation workflows.
8. Test duplicate webhooks, reordered events, payment failures, and ledger balance invariants.

### Exit criteria

- No fee, commission, cancellation, or refund formula is invented by the agent.
- Every money movement or status change is traceable.
- Webhooks are verified and idempotent.
- Test cases cover rounding and reconciliation.
- Production credentials and provider accounts are approved and configured.

---

## 16. Phase 10 — Reporting, Security, Performance, and Pilot Release

### Objective

Validate the application end to end and release only the features that meet pilot-readiness requirements.

### Tasks

1. Define KPI formulas before showing business dashboards.
2. Apply privacy filters and authorization to all reports and CSV exports.
3. Run end-to-end browser tests for customer, seller, and admin workflows.
4. Run dependency and secret scans available in the CI environment.
5. Review authorization, session handling, CSRF, rate limiting, upload handling, and privacy DTOs.
6. Check accessibility, mobile responsiveness, and core performance.
7. Validate database backups and practice a restore in a non-production environment.
8. Create staging deployment configuration and a release checklist.
9. Verify environment variables, HTTPS, logging, alerting, and health checks.
10. Complete a controlled pilot/UAT with representative test accounts.
11. Document known limitations, support procedures, and rollback steps.

### Exit criteria

- Critical workflows pass end-to-end tests.
- No known unresolved critical security or privacy defect remains.
- Backups and restore steps have been tested.
- Production secrets are stored outside source control.
- Monitoring and support ownership are defined.
- Product owner signs off on pilot scope and known limitations.

---

## 17. Definition of Done for Every Feature

A feature is not complete merely because its UI exists. Every feature must satisfy the applicable checks below:

- Requirements and acceptance criteria are identified.
- Backend behavior is implemented and validated.
- Authorization and resource ownership are enforced server-side.
- Database changes include migrations where required.
- Public and private DTOs are appropriately separated.
- Expected errors are handled with stable responses.
- Sensitive values are excluded from logs.
- Unit and integration tests cover important cases.
- Frontend tests cover relevant interactions.
- End-to-end tests cover critical user journeys where appropriate.
- Accessibility and responsive behavior have been reviewed.
- Documentation and environment templates are updated.
- Build and tests were actually run; results are reported accurately.
- A Git checkpoint exists before starting the next major phase.

## 18. Testing Strategy

| Test level | What it validates | When to run |
|---|---|---|
| Domain unit tests | Invariants, state transitions, calculations | On every relevant change |
| Application unit tests | Use-case decisions and failure paths | On every relevant change |
| API integration tests | Routing, validation, authentication, authorization | For each API feature |
| PostgreSQL integration tests | Constraints, migrations, transactions, queries | For every persistence feature |
| Frontend unit/component tests | Rendering, interactions, validation | For each UI feature |
| Playwright E2E tests | Customer/seller/admin journeys | Each milestone and before release |
| Privacy regression tests | No private fields in public responses | Every relevant API change |
| Security checks | Secrets, dependencies, access controls | Continuously and before release |

Use a real disposable PostgreSQL instance or a suitable test container for tests that rely on PostgreSQL-specific behavior. Do not use production data in automated tests.

## 19. Git and Change Management

Recommended practices:

1. Commit the baseline before major implementation begins.
2. Use small changes with clear commit messages.
3. Review `git diff` before accepting an AI agent's changes.
4. Never commit secrets, `.env` files containing credentials, generated private documents, or production data.
5. Run formatting, build, and relevant tests before committing.
6. Keep generated migrations with the code that requires them.
7. Do not combine unrelated feature changes in one large commit.
8. Revert or repair a failing phase before moving forward.

Example checkpoint sequence:

```text
chore: establish repository baseline
chore: add technical foundation
feat: add domain and database foundation
feat: add secure authentication
feat: add seller onboarding
feat: add listings and search
feat: add order lifecycle
feat: add notification outbox
feat: add moderation and support
feat: add approved commercial workflows
chore: prepare pilot release
```

Use these as examples, not mandatory exact commit messages.

## 20. Coding Agent Operating Rules

For every implementation task, instruct the agent to:

1. Read the relevant requirements and technical files first.
2. Inspect existing code before changing it.
3. State the specific scope and files it expects to change.
4. Follow the canonical stack and documented layer boundaries.
5. Avoid unrelated refactoring and unapproved dependencies.
6. Never invent business policy.
7. Implement tests alongside the feature.
8. Run and report the actual commands and results.
9. Report tests that could not run and the reason.
10. Summarize files changed, design decisions, setup steps, risks, and next recommended task.
11. Stop at the scope boundary instead of silently proceeding into the next phase.

## 21. First Coding Agent Prompt — Documentation Audit

Copy this prompt into OpenCode after opening the BUILD MATE repository:

```text
You are the technical lead for BUILD MATE.

First, audit the repository and documentation. Do not implement product
features yet.

Read AGENTS.md, docs/DOCUMENT-MANIFEST.md, the BRD, PRD, DRD, techstack,
backend architecture, EF Core data access, PostgreSQL database design,
frontend architecture, and relevant feature specifications.

If paths differ, find the existing files before declaring them missing.
Do not overwrite useful files or recreate the repository unnecessarily.

Canonical baseline:
- Next.js App Router + TypeScript
- ASP.NET Core Web API with C# and .NET 10 LTS
- Entity Framework Core with a compatible Npgsql provider
- PostgreSQL and pgAdmin 4
- Zod, Vitest, Playwright, and xUnit
- Secure cookie-based browser sessions, subject to the approved auth spec

Do not use Prisma as the backend ORM. Do not add Redis, a broker, or
microservices without an approved design decision.

Identify contradictions, especially ORM, authentication, API contracts,
order states, database relationships, privacy rules, and commercial policy.
Do not silently resolve material conflicts. Produce a decision register.

Report:
1. Actual repository structure and existing code.
2. Documentation files found.
3. Conflicts, risks, and unresolved business decisions.
4. Recommended source of truth.
5. Phase 1 technical foundation plan and files likely to change.
6. Commands available to validate the current setup.

Do not claim a build or test passed unless you ran it. Stop after the audit
and wait for the next task.
```

## 22. Second Coding Agent Prompt — Technical Foundation

Run this only after reviewing the audit and resolving high-impact conflicts:

```text
Implement BUILD MATE Phase 1 — Technical Foundation only.

Inspect the repository first and preserve working code.

Scope:
1. Create or complete the Next.js + TypeScript application.
2. Create or complete the ASP.NET Core Clean Architecture solution:
   API, Application, Domain, Infrastructure.
3. Configure PostgreSQL for local development using the approved approach.
4. Configure EF Core and a compatible Npgsql provider.
5. Add liveness/readiness health endpoints.
6. Add centralized error handling and structured logging.
7. Add minimal frontend and backend tests.
8. Add safe configuration templates and update .gitignore.
9. Add basic CI checks where supported by this repository.
10. Document exact macOS setup, start, test, and stop commands.

Do not implement authentication, seller onboarding, listings, search,
orders, payments, SMS, WhatsApp, or other marketplace features in this task.
Do not add unapproved dependencies or invent business rules.
Do not commit secrets or run destructive database commands.
Do not run migrations against production.

Run available frontend/backend checks and verify the intended local database
connection. Report the exact commands and actual outcomes. List blocked checks
and explain why. Stop after Phase 1.
```

## 23. Decision Register Template

Track decisions that must be approved before the dependent phase starts.

| ID | Decision | Owner | Needed by | Status |
|---|---|---|---|---|
| D-001 | Final cookie/session and OTP provider design | Product/technical owner | Phase 3 | Open |
| D-002 | Seller verification requirements and approval rules | Product owner | Phase 4 | Open |
| D-003 | Listing fields, units, delivery coverage, availability rules | Product owner | Phase 5 | Open |
| D-004 | Final order-state transition matrix | Product owner | Phase 6 | Open |
| D-005 | SMS/WhatsApp provider and approved templates | Product/operations owner | Phase 7 | Open |
| D-006 | Media storage provider, retention, and private-document access | Technical/product owner | Phase 8 | Open |
| D-007 | Payment method and whether platform collects money | Product/finance owner | Phase 9 | Open |
| D-008 | Commission, fee, cancellation, and refund rules | Product/finance owner | Phase 9 | Open |
| D-009 | Pilot hosting, backups, support and incident ownership | Technical/product owner | Phase 10 | Open |

Update status to `Approved`, `Rejected`, or `Deferred` with a date and a link to the relevant decision record. Do not implement an open decision that changes money movement, privacy, legal obligations, or core order behavior.

## 24. How to Use This Plan

1. Save this document as `docs/DEVELOPMENT_PLAN.md`.
2. Add it to the existing `DOCUMENT-MANIFEST.md`.
3. Make sure `AGENTS.md` tells coding agents to follow this plan and the canonical technical baseline.
4. Run the Phase 0 documentation audit prompt first.
5. Review its report and approve the required decisions.
6. Implement Phase 1 only.
7. Verify the phase, commit a checkpoint, and then proceed in order.

**Primary rule:** finish, verify, and checkpoint one phase before starting the next. Keep the MVP narrow, preserve privacy, and never let the coding agent invent business or financial policy.