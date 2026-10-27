# BUILD MATE

**Construction materials. Delivered to your site.**

BUILD MATE is a proposed responsive marketplace for construction materials offered as ready-to-deliver loads. A seller's offer bundles the material and truck/delivery together. Customers can discover listings, compare terms, submit orders, follow status updates and contact support through the platform.

**Working brand:** BUILD MATE (provisional; complete brand/domain/trademark checks before public launch).

**Initial pilot:** One selected service area in the Nagpur region of Maharashtra, India.

---

## 1. Product principles

- **Bundled delivery:** Every orderable offer includes the material and delivery together.
- **One seller per MVP order:** No separate truck-owner marketplace or multi-seller cart in the first release.
- **Contact privacy:** No public supplier directory or public listing exposure of private seller phone/email/personal WhatsApp.
- **Server-authoritative rules:** Prices, permissions, availability and order transitions are validated by the backend.
- **Local validation first:** Prove demand, supply, completed deliveries and per-order economics before expensive expansion.
- **Incremental delivery:** Build and test a small complete feature before moving to the next one.

## 2. Technology stack

| Component | Baseline |
|---|---|
| Frontend | Next.js App Router, React, TypeScript |
| UI | Tailwind CSS and approved accessible components |
| Frontend validation | TypeScript and Zod where useful |
| Frontend unit/component tests | Vitest |
| Browser E2E tests | Playwright |
| Backend | ASP.NET Core Web API on .NET 10 LTS |
| Language | C# |
| Relational database | PostgreSQL |
| ORM | Entity Framework Core 10 |
| PostgreSQL provider | Compatible Npgsql EF Core provider |
| Backend tests | xUnit and ASP.NET Core integration tests |
| API contract | REST/JSON under `/api/v1`, OpenAPI |
| Local dependencies | Docker Compose where useful |
| Background processing | .NET hosted worker and PostgreSQL-backed outbox where needed |
| Deployment checks | CI build, tests, migration validation and controlled release |

Use compatible, supported versions as specified by the project files. Do not introduce Prisma for the .NET backend. Do not add Redis, a separate broker or microservices unless an approved architecture decision justifies the additional complexity.

## 3. Repository structure

Recommended initial structure:

```text
build-mate/
├── web/
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   ├── features/
│   │   ├── lib/
│   │   └── types/
│   ├── tests/
│   ├── package.json
│   └── ...
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
├── docs/
│   ├── BRD.md
│   ├── PRD.md
│   ├── DRD.md
│   ├── Architecture.md
│   ├── Database.md
│   ├── Design.md
│   ├── API.md
│   ├── Authentication-and-Security.md
│   ├── Agent.md
│   └── README.md
├── infra/
│   ├── docker-compose.yml
│   └── scripts/
├── .github/
│   └── workflows/
├── .editorconfig
├── .gitignore
├── AGENTS.md
└── README.md
```

This is a target structure. Directories and project files need to be created during implementation; the presence of this diagram does not mean they already exist.

## 4. Documentation index

| Document | Purpose |
|---|---|
| `BRD.md` | Business case, stakeholders, scope and commercial hypotheses |
| `PRD.md` | Product goals, page journeys, feature priority and launch acceptance |
| `DRD.md` | Detailed functional, security, data and acceptance requirements |
| `Architecture.md` | Technology choices, modules, dependencies, deployments and architecture decisions |
| `Database.md` | PostgreSQL entities, constraints, indexes, statuses and migrations |
| `Design.md` | UX, design tokens, components, responsive behavior and accessibility |
| `API.md` | Endpoint inventory, contracts, authorization and error conventions |
| `Authentication-and-Security.md` | Identity, sessions, access controls, privacy and security testing |
| `Agent.md` | Instructions and workflow for an AI coding agent |
| `Integration.md` | External-provider integration strategy |
| `MCP-Connection.md` | Model Context Protocol integration requirements, if applicable |
| `Feature-Development.md` | Implementation sequence, dependencies and feature workflow |
| `Project-Implementation-and-Setup.md` | Detailed repository/bootstrap instructions |
| `Testing-QA-and-Debugging.md` | Test strategy, release quality gates and debugging workflow |
| `01-...md` through `19-...md` | Individual feature specifications |
| `DOCUMENT-MANIFEST.md` | Complete inventory, dependencies, document status and recommended reading order |

Before coding a feature, read its specification and all directly related architecture/security/API/database documents.

## 5. Prerequisites

Install and verify:
- A supported Node.js LTS release compatible with the selected Next.js version.
- The .NET 10 SDK.
- Docker Desktop or compatible Docker Engine with Compose, if using the containerized local database.
- Git.
- A local editor/IDE such as VS Code or an IDE supporting .NET.
- A PostgreSQL client or administrative UI if useful.

The actual supported versions should be recorded in the frontend package manifest, backend project files and contributor documentation. Avoid installing arbitrary globally pinned package versions that conflict with project configuration.

Check the installations:

```bash
node --version
npm --version
dotnet --info
docker --version
docker compose version
git --version
```

These commands check the tools only. They do not initialize a BUILD MATE repository.

## 6. Clone or open the repository

If the repository is already local, open its root directory and inspect the current Git state before changing files.

To clone a configured repository:

```bash
git clone <YOUR_REPOSITORY_URL>
cd build-mate
git status
```

Replace `<YOUR_REPOSITORY_URL>` with the repository URL you control. Do not invent or commit a public repository URL before the project owner has created one.

## 7. Configuration and secrets

Provide environment-specific configuration for:
- PostgreSQL connection string.
- ASP.NET Core environment.
- Allowed frontend origin(s)/CORS settings, if applicable.
- Cookie/authentication configuration.
- Public frontend API base URL.
- Private storage configuration.
- SMS/WhatsApp/telephony/payment provider credentials only when those features are implemented.
- Logging and error-monitoring configuration.

Create safe templates such as:
- `web/.env.example`
- `backend/src/BuildMate.Api/appsettings.Development.example.json`
- `infra/.env.example`

These are suggested filenames; use the actual configuration layout chosen by the implementation.

Rules:
- Commit templates with placeholders only.
- Never commit production credentials.
- Do not place backend secrets in `NEXT_PUBLIC_*` values.
- Use .NET User Secrets or environment variables for local API secrets.
- Use a managed secret store for production where available.
- Keep local, staging and production credentials separate.
- Never put real seller documents or customer contact data into seed files.

## 8. Local database setup

The preferred local path is PostgreSQL through Docker Compose or an equivalent local instance. The repository must provide a Compose configuration or clear manual instructions during bootstrap.

Once the actual Compose file is created, the typical startup command is:

```bash
docker compose -f infra/docker-compose.yml up -d
```

Check container status:

```bash
docker compose -f infra/docker-compose.yml ps
```

The Compose service/database/user names and credentials must come from the project's configuration. Do not assume service names or credentials that are not defined in the actual file.

Production PostgreSQL must not use development passwords, public unrestricted ports or development seed accounts.

## 9. Backend setup

From the repository root, after the solution and projects have been created:

```bash
cd backend
dotnet restore
dotnet build
dotnet test
```

These commands assume `backend/BuildMate.sln` exists. If the solution is not yet bootstrapped, create the solution and projects following `Architecture.md` and `Project-Implementation-and-Setup.md` first.

Recommended project responsibilities:
- `BuildMate.Domain`: domain entities, value objects and core rules.
- `BuildMate.Application`: use cases, ports, DTOs and application validation.
- `BuildMate.Infrastructure`: EF Core/Npgsql persistence and provider adapters.
- `BuildMate.Api`: HTTP endpoints, middleware, dependency injection and authentication.

Do not put business rules solely in controllers or frontend components.

### 9.1 Database migrations
During initial implementation:
1. Configure the EF Core `DbContext`.
2. Configure the compatible Npgsql provider.
3. Set the database connection through local configuration.
4. Create and review the first migration.
5. Apply it to a development database.
6. Test the migration against an empty database and the expected upgrade path.
7. Seed synthetic data only.

Typical commands, once the project structure and EF tooling are configured:

```bash
dotnet ef migrations list --project src/BuildMate.Infrastructure --startup-project src/BuildMate.Api
dotnet ef database update --project src/BuildMate.Infrastructure --startup-project src/BuildMate.Api
```

Run these from `backend/`. Adjust project paths to match the actual project files. These commands must not point to production accidentally.

Use migrations as the schema evolution mechanism. Do not use `EnsureCreated()` as a production migration strategy.

## 10. Frontend setup

After `web/package.json` has been created with the approved scripts:

```bash
cd web
npm ci
npm run dev
```

Common expected script names, to be defined in the project manifest, include:

```bash
npm run dev
npm run build
npm run lint
npm run typecheck
npm run test
npm run test:e2e
```

Not every script exists automatically. Add only scripts that are configured and maintainable in the repository. Document the actual script names once the initial frontend project is generated.

The frontend must communicate with the backend through the API. It must not connect directly to PostgreSQL or contain server-only secrets.

## 11. Initial end-to-end verification

Once both applications and the local database are configured:

1. Start PostgreSQL.
2. Apply development migrations.
3. Start the ASP.NET Core API.
4. Verify the configured health endpoint.
5. Start the Next.js frontend.
6. Confirm the frontend can reach the API.
7. Use synthetic customer, seller and admin accounts.
8. Test a bundled material-and-delivery listing.
9. Test customer order submission and seller acceptance.
10. Confirm public listing responses do not expose private contacts.
11. Run backend and frontend tests.
12. Verify logs do not contain passwords, OTPs, cookies, provider secrets or unnecessary personal data.

Do not use a real order, production account, live payment or real outbound SMS to test a local feature unless the test is explicitly approved and the service is configured for that purpose.

## 12. Development order

Recommended sequence:

### Phase 1 — Foundation
- Repository structure.
- Development configuration.
- PostgreSQL and migrations.
- API/frontend health check.
- CI build/test pipeline.
- Central error handling and logging.

### Phase 2 — Identity and access
- Identity setup and login/session behavior.
- Customer and seller role/resource policies.
- Security tests and private DTO conventions.

### Phase 3 — Seller onboarding and catalog
- Seller application/profile.
- Verification state and admin review.
- Material categories/specifications.
- Bundled delivery listing CRUD and moderation.

### Phase 4 — Customer marketplace
- Public homepage and material navigation.
- Search and filter.
- Listing details and price basis.
- Customer address management.
- Public contact privacy tests.

### Phase 5 — Order operations
- Order submission.
- Price/address snapshots.
- Seller accept/reject.
- Lifecycle/status history.
- Cancellation and operational exceptions under approved rules.

### Phase 6 — Communication and support
- Platform messages.
- Notification outbox and provider mocks.
- SMS/WhatsApp integration after provider decisions.
- Masked calling only after validated provider support.
- Support tickets and complaints.

### Phase 7 — Commercial features
- Approved payment workflow.
- Commission/fee calculation.
- Refund and reconciliation.
- Completed-order reviews and reporting.

### Phase 8 — Release preparation
- Privacy/security review.
- Accessibility and mobile QA.
- Backup/restore checks.
- Monitoring and incident procedures.
- Controlled pilot and measurable go/no-go review.

Each phase depends on tested foundations from the previous phase; do not build advanced integrations around an unstable order state machine.

## 13. Testing

### Backend
- Domain rule unit tests using xUnit.
- Application/use-case tests.
- API integration tests.
- PostgreSQL mapping and migration tests.
- Authorization/IDOR tests.
- Order concurrency/idempotency tests.
- Provider contract tests using fakes.

### Frontend
- Vitest unit/component tests.
- Form validation and error-state tests.
- Accessibility checks.
- Playwright journeys for customer, seller and admin.
- Responsive viewport checks.
- Public-data privacy checks against API results and rendered pages.

### Essential user journeys
- Customer searches for a suitable delivered load.
- Customer views price/terms and submits an order.
- Seller accepts/rejects and updates permitted status.
- Customer tracks the order and accesses support.
- Admin approves a seller and moderates a listing.
- Unauthorized user cannot access private resources.
- Provider outage is surfaced as failure rather than success.

## 14. Security and privacy

Before any public release:
- Enforce authentication and authorization in the backend.
- Configure secure session cookies and CSRF controls for browser sessions.
- Restrict CORS.
- Keep seller/customer private contacts out of public DTOs.
- Protect verification documents using private storage.
- Enforce rate limits on login, OTP, messaging, uploads and other abuse-sensitive endpoints.
- Use server-calculated order totals and idempotency safeguards.
- Verify provider callbacks.
- Redact secrets and personal information from logs.
- Audit sensitive admin actions.
- Publish approved terms, privacy, seller, cancellation/refund and complaint policies.
- Test database restore and incident procedures.

See `Authentication-and-Security.md` for the complete checklist.

## 15. External integrations

Integrations should be selected only after business requirements and provider capabilities are confirmed.

Possible integrations:
- SMS.
- WhatsApp Business.
- Masked calling/telephony.
- Payment gateway.
- Email delivery.
- Object storage.
- Optional geocoding/maps.

Use interfaces and mock adapters so core development does not require live credentials. Provider configuration, callback validation, retries, opt-ins, privacy behavior and delivery/failure visibility must be implemented before a production integration is marked complete.

## 16. CI/CD expectations

The repository's pipeline should, where appropriate:
1. Restore dependencies.
2. Check formatting and lint.
3. Compile frontend/backend.
4. Run unit tests.
5. Run integration tests using isolated test infrastructure.
6. Validate EF Core migration behavior.
7. Run vulnerability/dependency checks.
8. Build deployable artifacts.
9. Deploy only through controlled, environment-specific steps.
10. Run post-deployment health checks.

A green build is necessary but not sufficient. Privacy, authorization and critical user journeys need explicit test coverage.

## 17. Coding-agent instructions

Before each task, the AI coding agent must:
- Read `docs/Agent.md` and the relevant feature specification.
- Inspect existing code before making changes.
- State a bounded implementation plan for work that crosses modules.
- Follow established project conventions.
- Add tests with the implementation.
- Review changes for security, data privacy and migration effects.
- Run the relevant commands.
- Report what changed and what was actually tested.
- Escalate unresolved business decisions instead of inventing high-impact policy.

Do not ask an agent to implement all features in one giant operation. Use the feature specifications and development phases to keep the work reviewable.

## 18. Production checklist

- [ ] Environment configuration separated by environment.
- [ ] No secrets committed or exposed to the frontend.
- [ ] Database migrations reviewed and validated.
- [ ] Backup and recovery procedures tested.
- [ ] Authentication, authorization and ownership tests pass.
- [ ] Public listing and API privacy tests pass.
- [ ] Order pricing/snapshot/idempotency tests pass.
- [ ] Provider failure and retry behavior tested.
- [ ] Logging and audit permissions configured.
- [ ] Rate limits and abuse controls active.
- [ ] Legal and product policies approved.
- [ ] Monitoring and incident responsibilities assigned.
- [ ] Core customer, seller and admin journeys tested.
- [ ] Accessibility and responsive UI checks completed.
- [ ] Any masked-calling privacy claim verified with the actual provider.
- [ ] Pilot success metrics and rollback criteria approved.

## 19. Product-owner decisions still requiring confirmation

The repository must track explicit decisions for:
- Initial pilot service area.
- Quantity units and detailed specifications per category.
- Fixed delivered price versus quote-required categories.
- Login/guest checkout rules.
- Seller verification evidence and approval policy.
- Seller response timeout.
- Cancellation, delivery confirmation and dispute windows.
- Pilot payment collection and refund method.
- Platform commission/service fee and who pays it.
- Chosen SMS, WhatsApp, telephony, storage and payment providers.
- Data retention/deletion rules.
- Hosting/region, budget, source-code ownership and operational access.

## 20. License and ownership

Do not add an open-source license, commercial license, privacy promise or warranty statement without owner approval. Confirm that code, branding, imagery and third-party assets are appropriately licensed for the intended use.

---

**Project status:** Documentation defines the intended baseline. Repository setup, integrations, launch readiness and product-market fit must be verified independently during implementation.
