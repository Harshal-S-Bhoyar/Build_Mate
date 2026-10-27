# BUILD MATE — System Architecture

**Document ID:** BM-ARCH-001  
**Version:** 1.0  
**Status:** Proposed implementation baseline  
**Last updated:** 26 October 2026

---

## 1. Architecture goals

Build a secure, maintainable and agent-friendly marketplace without premature infrastructure. The architecture must encode the ready-to-deliver-load model, protect customer/seller contact details, maintain reliable order/price state, support replaceable external integrations, and let an AI coding agent implement one bounded feature at a time.

## 2. Locked technology decisions

These choices are the default source of truth for the current build. Changes require an Architecture Decision Record (ADR) and updates to all affected documents.

| Layer | Selected default |
|---|---|
| Frontend | Next.js App Router, React and TypeScript |
| UI | Tailwind CSS and accessible component primitives (such as shadcn/ui or equivalent) |
| Backend | ASP.NET Core Web API on .NET 10 LTS |
| Backend language | C# |
| Relational database | PostgreSQL 18, using a supported current minor release |
| ORM/data access | Entity Framework Core 10 + a compatible Npgsql EF Core provider |
| Database management UI | pgAdmin is a developer tool; it is not the database engine or an application dependency |
| API | REST/JSON under `/api/v1`; OpenAPI in development and controlled environments |
| Frontend validation | TypeScript types and Zod at relevant frontend form/API boundaries |
| Backend validation | DTO/request validation plus explicit application/domain validation; keep one canonical business rule source on the backend |
| Authentication | ASP.NET Core Identity or a separately approved maintained identity/session implementation; prefer Secure, HttpOnly cookies for browser sessions |
| Authorization | Server-side role- and resource-based authorization |
| Backend tests | xUnit; ASP.NET Core integration tests with `WebApplicationFactory` |
| Frontend tests | Vitest for unit/component testing; Playwright for browser end-to-end testing |
| Local environment | Docker Compose for PostgreSQL and any optional local supporting services |
| Observability | Structured logs, correlation IDs, health checks, error monitoring and provider delivery state |
| CI/CD | Git-based automated restore/build/test/lint/migration checks and controlled deployment |
| File storage | Private object storage for seller verification documents; controlled public storage/CDN for approved listing images |

Use a supported current .NET 10 SDK patch and verify package compatibility before pinning package versions. PostgreSQL must be a supported release. Record exact SDK/package versions in project files and lockfiles; do not silently mix incompatible EF Core/Npgsql versions.

## 3. Architectural style

Use a **modular monolith** for the MVP. The frontend and API can be deployed independently, but backend business modules live in one ASP.NET Core solution backed by one primary PostgreSQL database. Do not start with microservices. The initial challenge is to prove supply, demand, fulfilment and unit economics, not to operate distributed services.

## 4. Logical modules

1. **Identity & Access:** users, roles, sessions and account state.
2. **Customer Profiles:** personal profile and saved delivery addresses.
3. **Seller Operations:** seller profile, verification, service areas and eligibility.
4. **Catalog & Listings:** categories, specifications, bundled material/delivery offers, capacity and availability.
5. **Search:** validated filters, service-area eligibility, sorting and pagination.
6. **Orders:** order/quote submission, price snapshots, lifecycle, cancellation and completion.
7. **Communications:** platform messaging and masked-call orchestration.
8. **Notifications:** outbox processing and SMS/WhatsApp/email adapters.
9. **Payments & Fees:** payment records, fee policy snapshots, refunds and reconciliation.
10. **Trust & Support:** reviews, complaints, disputes and moderation.
11. **Admin & Audit:** privileged actions, reports, exports and audit records.
12. **Media:** listing images and private verification-document access.

Controllers should remain thin. Place business logic in application/domain services and enforce access rules centrally.

## 5. Suggested repository structure

```text
build-mate/
  web/                                      # Next.js + TypeScript
    src/app/
    src/components/
    src/features/
    src/lib/
    src/types/
    tests/
    package.json
  backend/
    BuildMate.sln
    src/
      BuildMate.Api/                        # HTTP, middleware, composition root
      BuildMate.Application/                # use cases, DTOs, ports, validators
      BuildMate.Domain/                      # entities, value objects, domain rules
      BuildMate.Infrastructure/              # EF Core, PostgreSQL, provider adapters
    tests/
      BuildMate.UnitTests/
      BuildMate.IntegrationTests/
  docs/                                      # authoritative Markdown docs
  infra/
    docker-compose.yml
    scripts/
  .github/workflows/
  .editorconfig
  .gitignore
```

Adapt this layout only with a documented reason. Do not place business rules in UI components or directly in HTTP controllers. `web/` must call the API; it must never connect directly to PostgreSQL.

## 6. Dependency direction

- `BuildMate.Domain` has no dependency on ASP.NET Core, EF Core, or provider SDKs.
- `BuildMate.Application` depends on Domain and defines use cases/ports.
- `BuildMate.Infrastructure` implements application ports and uses EF Core/Npgsql and external provider SDKs.
- `BuildMate.Api` handles HTTP, middleware, serialization, authentication, authorization and dependency injection.
- `web/` consumes API contracts and owns presentation state only.

Cross-module workflows should use explicit application services and transactions; do not let arbitrary controllers access another module's tables directly.

## 7. Request lifecycle

A typical order request flows through:
1. Next.js sends an HTTPS request to the API.
2. API middleware attaches/propagates a correlation ID and applies exception handling, rate limiting, authentication and appropriate CSRF controls.
3. Endpoint validates the request shape and checks authentication/authorization.
4. Application use case loads required records and applies the business policy.
5. Domain policy validates seller/listing eligibility, quantity/unit, price terms and state transitions.
6. Infrastructure writes through EF Core inside a PostgreSQL transaction.
7. Order/status/audit and notification-outbox records are persisted consistently.
8. Background processing sends notifications through adapters and records provider outcomes.
9. API returns a purpose-built response DTO, never a raw EF entity.

## 8. Authentication and browser security boundary

- Prefer server-issued Secure, HttpOnly, SameSite cookies for browser sessions; do not store bearer tokens in localStorage.
- If the web and API use different origins, configure exact CORS origins and credentials only where required. Never combine wildcard origins with credentials.
- Cookie-authenticated state-changing routes require an appropriate anti-CSRF mechanism.
- OTP/login attempts require rate limiting and abuse controls.
- Every private endpoint checks resource ownership and role permissions.
- Do not assume a hidden UI action secures the underlying endpoint.

Full policies belong in `Authentication-and-Security.md` and `01-authentication-and-sessions.md`.

## 9. Database consistency

PostgreSQL is the source of truth. Use Entity Framework Core migrations as the schema evolution mechanism. Key invariants:
- Confirmed order terms/price are snapshotted.
- An MVP order references one customer, one seller and one listing.
- Only legal state transitions are permitted.
- Public search results come only from approved and eligible listings.
- Private contact information/documents have stricter access controls than public listing information.
- Commission/refund operations are traceable.
- Concurrent orders cannot silently oversell finite capacity.

Use transactions, concurrency tokens or row locks as appropriate. Do not rely on in-memory checks for multi-request integrity.

## 10. Background work and reliability

Start with a PostgreSQL-backed outbox and a small .NET `BackgroundService`/hosted worker where it meets pilot requirements. Use it for notification attempts, transient retries, stale quote/listing expiry and other time-based work. Each work item must be idempotent and have bounded retries/backoff; failed items must be inspectable by authorized operations staff.

Do not add Redis or a separate message broker by default. Add them only when measured traffic, reliability or deployment requirements justify them, and record the decision in an ADR.

## 11. Provider ports and mock adapters

Define application interfaces such as:
- `ISmsSender`
- `IWhatsAppSender`
- `IMaskedCallProvider`
- `IPaymentGateway`
- `IObjectStorage`
- `IEmailSender`
- `IClock`

Infrastructure implements provider integrations; tests and local development use deterministic fakes. Every adapter returns explicit success/failure, provider reference and retryability where useful. A timeout or rejected request must not be recorded as successful delivery/payment/call.

## 12. Security and observability

- HTTPS in production and least-privilege database/application identities.
- Separate local/staging/production credentials.
- Store secrets in environment-specific secret stores; commit only placeholder keys in `.env.example` or equivalent configuration templates.
- Redact OTPs, tokens, private phone/email/address, verification-document URLs and payment secrets from logs.
- Maintain audit events for sensitive actions and safe correlation IDs across API/background processing.
- Health endpoints must not reveal secret values, database connection strings or internal stack traces.
- Monitor API failures, database health, order conversion, provider failures and notification backlog.

## 13. Deployment architecture

Production requires:
- Next.js frontend host.
- ASP.NET Core API host with .NET 10 runtime or self-contained deployment.
- Managed PostgreSQL with restricted network access and backups.
- Private object storage for verification documents and controlled public storage/CDN for approved listing media.
- Secret management, HTTPS, DNS/domain, logs and error monitoring.
- CI/CD with build/test/migration checks and controlled release.
- Background worker, either co-hosted for a small pilot or deployed separately where needed.

Choose providers based on India-region options if required, supported .NET runtime, backup/restore, private networking, logging, reliability and total cost—not brand preference alone.

## 14. Test architecture

- Domain unit tests: prices, eligibility rules, permissions and state transitions.
- Application tests: workflows, idempotency and transaction behavior.
- API integration tests: endpoints, authentication and PostgreSQL mappings.
- Frontend component tests and Playwright E2E for customer, seller and admin journeys.
- Provider contract tests: success, timeout, malformed response, retry and duplicate webhook.
- Security tests: cross-user data access, role escalation, CSRF, rate limits and private-contact leakage.

## 15. Architecture Decision Records

Any change to backend runtime, ORM/database strategy, auth/session scheme, provider, queue/worker, storage, hosting or architecture must be recorded in an ADR with context, options, decision, trade-offs, migration impact, security impact and date. Update dependent documents and feature specifications in the same change.
