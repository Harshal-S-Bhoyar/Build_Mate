# BUILD MATE — Project Implementation and Setup Guide

**Document ID:** BM-SETUP-001  
**Version:** 1.0  
**Status:** Implementation baseline  
**Last updated:** 26 October 2026

---

## 1. Purpose

This guide defines how to bootstrap, configure, run and validate the BUILD MATE development environment. It is written for developers and coding agents that will build the repository incrementally.

The repository should contain a Next.js frontend, an ASP.NET Core Web API, PostgreSQL persistence through EF Core/Npgsql, automated tests and project documentation.

Commands in this document are templates where noted. Run them from the specified directory and adapt paths only when the actual repository structure differs. Do not assume that a project, script or container exists until it has been created and verified.

## 2. Implementation principles

1. Create a small working foundation before adding business features.
2. Keep frontend and backend in clearly separated projects.
3. Make PostgreSQL the source of truth.
4. Use EF Core migrations for schema changes.
5. Keep backend business rules out of UI components.
6. Use environment-specific configuration and never commit real secrets.
7. Make local development possible without live provider credentials.
8. Use synthetic seed data only.
9. Add tests alongside each implemented feature.
10. Keep setup and troubleshooting instructions synchronized with the actual code.

## 3. Prerequisites

Install supported versions of:
- Node.js LTS compatible with the selected Next.js release.
- npm or the package manager selected by the repository.
- .NET 10 SDK.
- Docker Engine/Desktop and Docker Compose, if containerized PostgreSQL is used.
- Git.
- A code editor/IDE with TypeScript and C# support.
- PostgreSQL client tooling, optional but useful.

Verify installation:

```bash
node --version
npm --version
dotnet --info
docker --version
docker compose version
git --version
```

Record the actual version and package compatibility choices in project files and CI. Do not rely on a contributor's globally installed tools as the only source of version truth.

## 4. Target repository layout

```text
build-mate/
├── web/
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

Create folders when the first project work requires them. Do not create dozens of empty files merely to make the tree look complete.

## 5. Initialize the Git repository

For a new local project:

```bash
mkdir build-mate
cd build-mate
git init
mkdir docs infra
```

Copy the approved documentation into `docs/`. Before changing an existing repository, inspect its state:

```bash
git status
git branch --show-current
```

Do not discard user changes or run destructive reset/clean commands without inspecting the working tree and obtaining the necessary approval.

Configure `.gitignore` for at least:
- `node_modules/`
- `.next/`
- `bin/` and `obj/`
- local environment files containing secrets
- generated test results/coverage
- IDE caches
- private uploads and database dumps
- local logs and temporary files

Do not ignore source-controlled EF Core migrations or package lockfiles.

## 6. Create the .NET solution

From the repository root, create the backend folders and solution.

```bash
mkdir -p backend/src backend/tests
cd backend

dotnet new sln -n BuildMate

dotnet new webapi -n BuildMate.Api -o src/BuildMate.Api
dotnet new classlib -n BuildMate.Domain -o src/BuildMate.Domain
dotnet new classlib -n BuildMate.Application -o src/BuildMate.Application
dotnet new classlib -n BuildMate.Infrastructure -o src/BuildMate.Infrastructure

dotnet new xunit -n BuildMate.UnitTests -o tests/BuildMate.UnitTests
dotnet new xunit -n BuildMate.IntegrationTests -o tests/BuildMate.IntegrationTests
```

Depending on the installed SDK templates, you may need to specify controller-based API generation explicitly or remove unused template endpoints. Confirm the resulting template matches the desired API style.

Add projects to the solution:

```bash
dotnet sln add src/BuildMate.Api/BuildMate.Api.csproj
dotnet sln add src/BuildMate.Domain/BuildMate.Domain.csproj
dotnet sln add src/BuildMate.Application/BuildMate.Application.csproj
dotnet sln add src/BuildMate.Infrastructure/BuildMate.Infrastructure.csproj
dotnet sln add tests/BuildMate.UnitTests/BuildMate.UnitTests.csproj
dotnet sln add tests/BuildMate.IntegrationTests/BuildMate.IntegrationTests.csproj
```

Configure references to follow the architecture dependency direction:
- Application → Domain.
- Infrastructure → Application and Domain.
- API → Application and Infrastructure.
- Tests → the projects they test.

Do not introduce circular project references.

## 7. Package compatibility and EF Core

Before adding packages, verify that the selected EF Core and Npgsql versions support one another and the chosen .NET target.

Typical package categories:
- EF Core design-time tooling.
- EF Core relational/database package as required by the chosen provider setup.
- Compatible Npgsql EF Core provider.
- ASP.NET Core integration test support.
- Existing framework-provided authentication/authorization packages where applicable.

Use the package versions verified for the repository; do not copy arbitrary versions from an old tutorial. Keep major/minor compatibility aligned across EF Core packages.

Install the EF CLI tool using a repository-compatible method. A local tool manifest is often preferable for team consistency.

Example tool-manifest setup, if not already present:

```bash
dotnet new tool-manifest
dotnet tool install dotnet-ef
dotnet tool restore
```

If the tool manifest already exists, do not recreate it. Pin compatible tool versions after validating them against the SDK and EF Core package versions.

## 8. Create the frontend

From the repository root, use the official Next.js project generator to create the app in `web/`.

An example interactive command is:

```bash
npx create-next-app@latest web
```

Select TypeScript and App Router, and choose the agreed linting and styling options. If `web/` already contains project files, inspect them first instead of running a generator that may overwrite content.

The frontend should have:
- A central API client.
- Environment-based API origin configuration.
- Shared design tokens/components.
- Feature folders for customer, seller, admin and marketplace flows.
- Type definitions for API contracts.
- Unit/component tests.
- Playwright end-to-end tests.
- Loading, empty, authorization and error states.

Do not put server secrets in `NEXT_PUBLIC_*` variables.

## 9. Configure PostgreSQL

The first local database may run through Docker Compose or an installed PostgreSQL instance. Create `infra/docker-compose.yml` with:
- A supported PostgreSQL image version.
- A named persistent volume for local development.
- Environment-driven database name/user/password.
- A local-only port mapping where appropriate.
- A health check.
- No production credentials.

Never commit real passwords. A sample `.env.example` must use placeholder values and explain how to configure a private local environment.

Typical startup once the Compose file exists:

```bash
docker compose -f infra/docker-compose.yml up -d
docker compose -f infra/docker-compose.yml ps
```

Do not expose PostgreSQL publicly in production. Configure a dedicated application DB identity with only required permissions. Use separate credentials for migrations/administration and routine application access where operationally appropriate.

## 10. Backend configuration

Create configuration for each environment:
- `Development`
- `Test`
- `Staging`
- `Production`

Typical settings include:
- Connection string.
- CORS allowed origins.
- Authentication/session options.
- Upload limits.
- Rate-limit policy.
- Logging levels.
- Object-storage settings.
- Provider adapters.
- Background-processing options.

Local secrets can use .NET User Secrets or environment variables. Production secrets should use an appropriate secret manager. Do not return secret values from health endpoints or diagnostics.

Maintain an `.env.example` or equivalent configuration template with names and placeholders, not real credentials.

## 11. First API health endpoint

Create the agreed health routes and test them locally. A liveness check should indicate that the process is running. A readiness check may verify critical dependencies using safe results and bounded timeouts.

Health responses must not disclose:
- Database connection strings.
- Passwords, tokens or keys.
- Private network topology.
- Raw exceptions or stack traces.

The exact URLs should match `API.md` and the actual implementation.

## 12. Configure EF Core and migrations

1. Create the `DbContext` in the infrastructure layer.
2. Configure Npgsql and connection-string loading.
3. Define entity mappings, precision, FKs, indexes and delete behavior.
4. Add the first migration.
5. Review the generated migration and SQL for destructive changes.
6. Apply it to a disposable development database.
7. Verify constraints and table names.
8. Run integration tests against PostgreSQL.

Example commands from `backend/`, after actual project configuration:

```bash
dotnet ef migrations add InitialCreate \
  --project src/BuildMate.Infrastructure \
  --startup-project src/BuildMate.Api
```

```bash
dotnet ef database update \
  --project src/BuildMate.Infrastructure \
  --startup-project src/BuildMate.Api
```

Adjust the command only if the actual `DbContext`/design-time setup uses different projects. Do not run a local migration command against production accidentally.

Never use `EnsureCreated()` as a substitute for managed production migrations.

## 13. Seed data

Use development-only, synthetic seed data for:
- Initial material categories.
- Demonstration sellers and customer accounts.
- Listings and orders for local QA.
- Status and edge-case tests.

Seed data must be clearly labelled and must not imply real verification, real stock, actual prices, completed sales or genuine reviews.

If privileged test accounts are required, create them only in isolated test/development environments, with non-production credentials that cannot be used in production.

## 14. Local run workflow

Use separate terminals or the approved development orchestration script.

Typical sequence:
1. Start PostgreSQL.
2. Apply database migrations.
3. Start the ASP.NET Core API.
4. Check API health/readiness.
5. Start the Next.js frontend.
6. Test the frontend/API interaction.
7. Run automated tests.

Backend commands from `backend/`:

```bash
dotnet restore
dotnet build
dotnet test
dotnet run --project src/BuildMate.Api
```

Frontend commands from `web/`, once the scripts are defined:

```bash
npm ci
npm run dev
```

For verification:

```bash
npm run lint
npm run typecheck
npm run test
npm run build
```

These commands require corresponding scripts in `package.json`. Add and maintain the scripts as part of frontend setup; do not report them as passing if they do not exist or were not run.

## 15. Test environment

Integration tests must use isolated data and must not connect to production. Preferred approaches include:
- A dedicated disposable PostgreSQL database/container.
- An ephemeral test database created and destroyed by the test harness.
- A dedicated test instance that is reset safely.

Do not assume an in-memory substitute proves PostgreSQL-specific behavior such as constraints, numeric precision, transactions, migrations, or query semantics.

External providers should be mocked/faked by default. Live testing requires deliberate credentials, explicit environment configuration and approval.

## 16. Logging and debugging setup

Configure structured logging with:
- Correlation ID.
- Operation/route.
- Status/result.
- Duration.
- Safe actor/resource identifiers where appropriate.
- Exception details in protected server-side logs.

Redact:
- OTPs.
- Passwords.
- Session cookies and tokens.
- Payment secrets.
- Private phone/email/address data when not necessary.
- Private storage keys/URLs.
- Full provider payloads that contain PII.

Development error pages may provide detailed diagnostics locally. Production responses must remain safe and concise.

## 17. CI configuration

The initial CI workflow should:
1. Restore and build the .NET solution.
2. Run xUnit tests.
3. Install frontend dependencies using the committed lockfile.
4. Run frontend lint, typecheck, tests and build.
5. Run PostgreSQL integration tests in isolated infrastructure.
6. Validate migrations against a supported PostgreSQL instance.
7. Run dependency/security checks.
8. Publish test results and build artifacts.
9. Protect production deployment behind environment controls and approval where appropriate.

A green compilation alone does not prove secure behavior or end-to-end correctness.

## 18. Implementation milestones

### Milestone A — Repository foundation
Solution, frontend project, .NET solution, configuration templates, formatting/linting and CI.

### Milestone B — Database and API foundation
PostgreSQL, EF Core, migrations, health checks, API error handling and logging.

### Milestone C — Identity/security
Sessions, authentication, authorization policies, user/resource isolation and security tests.

### Milestone D — Marketplace vertical slice
Seller onboarding, approved listings, public search, listing details and privacy-safe DTOs.

### Milestone E — Order vertical slice
Order creation, price snapshots, seller responses, order lifecycle and notification outbox.

### Milestone F — Support and integrations
Platform messaging, support, provider adapters and approved external integrations.

### Milestone G — Release readiness
QA, security/privacy review, operational documentation, backups and controlled pilot.

## 19. Setup completion checklist

- [ ] Repository structure matches the approved architecture.
- [ ] Frontend starts locally.
- [ ] Backend builds and runs locally.
- [ ] PostgreSQL is reachable with development credentials.
- [ ] EF Core migration applies to an empty local DB.
- [ ] Synthetic seed data is available.
- [ ] API health endpoint responds.
- [ ] Frontend successfully calls the API.
- [ ] Backend and frontend tests have configured commands.
- [ ] No production secret is tracked.
- [ ] Logs redact sensitive values.
- [ ] CI checks are documented and reproducible.
- [ ] Setup documentation matches the actual files and commands.

## 20. Out-of-scope setup work

Do not make production cloud, payment, SMS, WhatsApp, masked-calling or custom-domain configuration a prerequisite for basic local development. Implement local mocks and defer live credentials until the associated feature and operating policy have been approved.
