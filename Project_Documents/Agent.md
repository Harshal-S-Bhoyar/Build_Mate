# BUILD MATE — AI Coding Agent Operating Instructions

**Document ID:** BM-AGENT-001  
**Version:** 1.0  
**Status:** Required development instructions  
**Last updated:** 26 October 2026  
**Project:** BUILD MATE construction-material marketplace

---

## 1. Mission

Implement BUILD MATE as a maintainable, secure, testable marketplace by following the approved product and engineering documentation.

You are a coding agent, not the business owner. Your responsibility is to implement agreed requirements, identify gaps, explain trade-offs, run appropriate checks and keep documentation accurate. You must not silently make high-impact business, financial, legal, privacy or architecture decisions.

The marketplace's defining model is:

**One listing = material + truck/delivery together, provided by one seller.**

A standard MVP order references one customer, one seller and one listing. Do not create a separate truck-owner role/workflow unless a later approved requirement explicitly changes the model.

## 2. Mandatory reading order

Before implementation, read these files:

1. `docs/BRD.md`
2. `docs/PRD.md`
3. `docs/DRD.md`
4. `docs/Architecture.md`
5. `docs/Database.md`
6. `docs/Design.md`
7. `docs/API.md`
8. `docs/Authentication-and-Security.md`
9. The feature-specific document for the task.
10. `docs/README.md` and the repository's actual setup/configuration files.

Read existing source code before modifying it. A document is not proof that an endpoint, database table, provider or feature already exists.

## 3. Source-of-truth and conflict resolution

Use this order to resolve requirements:

1. Explicit, recent decision from the product owner that applies to the task.
2. Approved architecture/security/product decision records.
3. `DRD.md` for detailed requirements.
4. `PRD.md` for product behavior and user journeys.
5. `BRD.md` for business purpose and non-negotiable rules.
6. Architecture, database, API, design and feature documents.
7. Existing code/tests when consistent with the approved requirements.
8. Your engineering judgment for implementation details that do not change user-visible policy.

If a real contradiction remains, stop the affected high-impact choice and document the options, risks and recommended decision. Do not resolve a conflict by selecting whichever instruction is easiest to code.

Create or update an Architecture Decision Record (ADR) for a material architectural change.

## 4. Technology stack — locked baseline

### Frontend
- Next.js App Router.
- React and TypeScript.
- Central design tokens and reusable components.
- Tailwind CSS and the approved accessible component approach.
- Zod where frontend-boundary/form validation is useful.
- Vitest for unit/component tests.
- Playwright for end-to-end browser tests.
- Backend API is the authoritative data and business-rule boundary.

### Backend
- ASP.NET Core Web API on .NET 10 LTS.
- C#.
- Entity Framework Core 10.
- Compatible Npgsql EF Core provider.
- PostgreSQL as the relational source of truth.
- xUnit for unit and integration testing.
- ASP.NET Core authentication/authorization and structured logging.

### Architecture
- Modular monolith for MVP.
- REST/JSON under `/api/v1`.
- EF Core migrations for schema changes.
- Provider interfaces and mock implementations.
- PostgreSQL-backed outbox/background processing where necessary.
- CI checks for build, format/lint, tests and migrations where feasible.

Do not add Prisma to the .NET backend. Prisma is not the selected ORM for this baseline. Do not add Redis, a broker, microservices, Kubernetes or other major infrastructure by default. Propose an ADR when measurable requirements justify additional infrastructure.

## 5. Required working method

For every task, use this cycle:

### Step 1 — Inspect
- Read the assigned feature specification.
- Inspect the relevant code, existing patterns, project files, migrations and tests.
- Identify dependencies and current implementation status.
- Check repository state before editing.

### Step 2 — Plan
Write a short implementation plan listing:
- User-visible behavior.
- Backend/domain changes.
- API contract changes.
- Database/migration changes.
- Authorization/privacy implications.
- Tests to add or update.
- Documentation to update.
- Risks or unresolved decisions.

For a small isolated fix, the plan can be brief. For cross-module work, include ordered tasks and prerequisites.

### Step 3 — Implement the smallest complete vertical slice
Implement one coherent behavior from UI/request through backend rules, persistence and tests.

- Follow existing naming and folder conventions.
- Keep controllers/endpoints thin.
- Put business rules in appropriate application/domain services.
- Use DTOs instead of serializing EF Core entities.
- Reuse design-system and validation patterns.
- Keep provider SDKs behind interfaces.
- Make the implementation production-safe rather than merely making a demo appear to work.

### Step 4 — Validate
Run the relevant checks, including as applicable:
- Frontend install/typecheck/lint/unit tests.
- Backend restore/build/format/unit tests.
- PostgreSQL integration tests.
- EF Core migration validation.
- Playwright critical-flow tests.
- Privacy/authorization tests.
- Provider contract tests with mocks.

Never claim a check passed unless it was actually run and passed. If a tool, service or runtime is unavailable, state the blocker and what remains unverified.

### Step 5 — Review the diff
Check for:
- Unrelated changes.
- Hardcoded secrets or environment-specific addresses.
- Unauthorized private-field exposure.
- Missing error handling.
- Duplicate business rules.
- Unsafe query building or unbounded listing retrieval.
- Missing tests/migrations.
- Incomplete loading/empty/error UI states.
- Accidental destructive changes.

### Step 6 — Report
Provide:
- What changed.
- Important files changed.
- Database/API changes.
- Commands/tests actually run and their result.
- Unverified checks and blockers.
- Any decisions requiring product-owner approval.

Do not say “complete” when only the UI exists but the endpoint, persistence or authorization is missing.

## 6. Mandatory business rules

### Marketplace listing
- Material and delivery are bundled.
- Seller is accountable for the complete listing.
- Only eligible approved listings from eligible sellers are orderable.
- Listing price mode is explicit: fixed delivered price or quote required.
- Every price states its quantity unit and delivery basis.
- No public supplier-contact directory.

### Orders
- One customer, seller and listing per MVP order.
- Backend recalculates totals and validates all important conditions.
- Create an immutable commercial and delivery-address snapshot when the approved flow confirms the order.
- Duplicate retries must not create duplicate orders.
- Seller/customer actions must follow the documented state machine.
- Payment status and order status remain distinct.

### Privacy
- Public listing/search DTOs must not expose private phone, email, personal WhatsApp, private address, payout details or verification-document storage keys.
- Every private-resource access has a server-side authorization check.
- The UI hiding a button is not sufficient security.
- Masked calling must not be enabled until actual provider testing proves the promised caller-ID privacy.
- Do not put private information or secrets in logs.

### Trust
- Do not fabricate ratings, review counts, seller verification, delivery estimates, completed-order numbers, stock or provider outcomes.
- Do not mark a notification/payment/call successful after a timeout or failure.
- Use explicit mock/test behavior in development rather than fake production success.

## 7. Frontend implementation rules

- Use TypeScript with strict type safety.
- Use the API client layer rather than scattering arbitrary fetch calls throughout the app.
- Keep request and response contracts typed.
- Use accessible labels, focus states and helpful validation errors.
- Include loading, empty, error, permission-denied and session-expired states where applicable.
- Do not access PostgreSQL directly from the browser.
- Do not put secrets in `NEXT_PUBLIC_*` variables.
- Do not use client-side authorization as the only access control.
- Avoid unneeded dependencies.
- Do not change the design system inconsistently between features.
- Do not hardcode production host URLs in source files.

## 8. Backend implementation rules

- Keep HTTP controllers/endpoints thin.
- Use application/domain services for use cases and business policies.
- Use explicit request/response DTOs.
- Validate every untrusted input server-side.
- Use EF Core/Npgsql safely; parameterize any necessary raw SQL.
- Use transactions for multi-record state-changing workflows.
- Add concurrency/idempotency handling for retries and limited inventory.
- Use centralized order-state transition policies.
- Use UTC timestamps and consistent decimal precision.
- Use dependency injection and cancellation tokens for suitable asynchronous operations.
- Keep external SDKs in infrastructure adapters.
- Use generic safe production error responses and structured server logs.
- Do not use `EnsureCreated()` for production schema management.
- Do not make schema changes without an EF Core migration.

## 9. Database and migration rules

Before changing a table or column:
1. Determine whether the change is backward-compatible.
2. Inspect current migrations and entity configuration.
3. Change entities/configuration and migration together.
4. Review nullability, defaults, precision, constraints, indexes and delete behavior.
5. Consider data migration/backfill requirements.
6. Test applying migrations to a clean database and, when feasible, upgrading the previous schema.
7. Update `Database.md` and relevant feature documentation.

Never delete or rewrite applied production migrations to hide a schema problem. Never use destructive migration steps without understanding data loss and obtaining required approval.

## 10. Authentication and security workflow

For any feature involving identity, personal data, file upload, orders, payments, messaging or administration:
- Identify the caller and resource owner.
- Define the required role/action policy.
- Enforce authorization on the backend.
- Test wrong-role, wrong-owner and unauthenticated attempts.
- Check whether the response includes unnecessary private fields.
- Apply appropriate rate limiting and idempotency.
- Redact logs.
- Add audit events for sensitive administrative actions.

Never create a temporary production backdoor, hardcoded admin account, magic password, public upload endpoint or bypass flag to make testing easier.

Use synthetic test users and test credentials confined to non-production environments.

## 11. External integrations

Define interfaces for external services and supply deterministic fakes. This includes, as applicable:
- SMS.
- WhatsApp Business.
- Masked calling.
- Payment gateway.
- Email.
- Object storage.
- Maps/geocoding.

Requirements:
- No live provider call in unit tests.
- Secrets come from configuration/secret stores.
- Provider timeouts and failures have explicit outcomes.
- Retries are bounded and idempotent.
- Provider webhooks are authenticated and deduplicated.
- Local setup works without production provider secrets.
- Do not invent API endpoints, SDK methods, price plans or provider capabilities.
- Verify external specifications from current official sources when implementation depends on provider behavior.

A mock sending “success” must be explicitly labelled as mock behavior and must not imply a real message/call/payment occurred.

## 12. Dependency and tooling discipline

- Prefer the smallest library set that meets the requirement.
- Verify that package versions support the selected framework.
- Keep lockfiles/project files consistent.
- Do not run arbitrary scripts downloaded from the internet without inspection.
- Do not disable TLS, certificate validation, security middleware or tests to force a green build.
- Never commit credentials, production exports or private customer/seller documents.
- Do not hide warnings by suppressing broad categories without a documented reason.

## 13. Agent autonomy boundaries

### The agent may decide independently
- Internal method names and small refactors.
- Test fixture organization.
- Reusable component boundaries.
- Non-breaking internal implementation details.
- Routine bug fixes that clearly satisfy an approved requirement.

### The agent must record or escalate
- New user-visible business rules.
- Changed pricing, commission, tax, refund or payout policy.
- Changed order cancellation/status semantics.
- New role/permission or private-data disclosure.
- A different authentication model.
- New external service/provider.
- Data retention/deletion policy changes.
- Additional infrastructure that materially raises cost/complexity.
- Destructive schema/data changes.
- Legal/compliance claims.
- Expansion of the product beyond the approved MVP.

If the unresolved issue blocks a high-impact decision, implement only safe preparatory work and document the dependency.

## 14. Task boundaries and change management

- Prefer one feature ticket/task per change.
- Avoid bundling broad unrelated refactors with functional work.
- Keep changes small enough to review.
- Update tests and docs in the same change.
- Do not overwrite user changes or reset unrelated work.
- Do not use destructive commands without inspecting affected state.
- Never delete tests simply because they fail.
- When a requirement changes, update the documentation and dependent tests.
- If a task is partially blocked, deliver the safe completed part and report the blocker.

## 15. Definition of done

A feature is done only when:
1. The specified user journey works.
2. Backend rules and validation are implemented.
3. Authorization and data privacy are verified.
4. Database changes are migrated safely if needed.
5. Loading/empty/error states are implemented where relevant.
6. Tests cover the main success and important failure paths.
7. No secrets or private data were exposed.
8. Relevant documentation is updated.
9. Actual test/build results are reported honestly.
10. No unapproved high-impact business decision has been embedded.

## 16. Standard task report

Use this format:

### Summary
What user-visible or technical behavior changed?

### Files changed
List the important files and why they changed.

### API/database
Describe endpoint, DTO and migration impacts, or state “none.”

### Validation performed
List commands actually executed and whether each passed, failed or could not run.

### Security and privacy
State the relevant authorization/privacy checks performed.

### Remaining work
List blockers, unverified checks or decisions that require owner approval.

## 17. Final instruction

Build a coherent, tested and secure product—not a collection of disconnected screens. Follow the approved documents, respect the boundaries of the MVP, and be explicit about uncertainty. When in doubt, preserve customer/seller privacy, keep business data server-authoritative, avoid irreversible changes, and ask for an owner decision before embedding a consequential assumption.
