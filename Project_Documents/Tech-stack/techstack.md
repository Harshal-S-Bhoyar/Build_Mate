# BUILD MATE — Enterprise Technology Stack Specification (`techstack.md`)

## 1. Executive Summary & Architectural Vision
**BUILD MATE** is a hyperlocal B2B/B2C construction materials marketplace engineered to connect customers, builders, and contractors with verified local suppliers of bulk construction materials (Black Stone, River Sand, Crushed Sand, Red Bricks, Fly Ash Bricks, Murum, Aggregate) bundled with verified vehicle delivery capacity (Tippers, Tractors, Hyvas).

The platform is built as a **Clean Architecture Modular Monolith** optimized for:
* **Strict Contact Privacy & Anti-Bypass:** Preventing direct phone/address leakage prior to confirmed orders.
* **Financial Precision:** Representing all monetary values, material quotes, delivery charges, and platform commissions in integer **paise** (`bigint` / `long`) to eliminate floating-point rounding errors.
* **High-Reliability Local Operations:** Supporting low-latency hyperlocal search, deterministic order state machines, and asynchronous SMS/WhatsApp outbox notifications.

---

## 2. Core Technology Stack Matrix

| Component | Selected Technology | Target Version / Baseline | Primary Role in BUILD MATE |
| :--- | :--- | :--- | :--- |
| **Frontend** | Next.js + TypeScript | Next.js App Router, TypeScript 5.x | Mobile-first responsive web UI, SSR/RSC rendering, client interactivity, SEO |
| **Backend** | ASP.NET Core with C# | ASP.NET Core Web API | RESTful Web APIs, domain state machines, server-authoritative business rules |
| **Runtime** | .NET 10 LTS | .NET 10 LTS | High-performance managed runtime, hosting, and garbage collection |
| **ORM** | Entity Framework Core + compatible Npgsql provider | EF Core 10 (`Npgsql`) | Code-First modeling, LINQ query translation, audit interceptors, schema migrations |
| **Database** | PostgreSQL | PostgreSQL (supported release) | ACID relational storage, `jsonb` metadata, B-Tree & GIN indexing, row-level locking |
| **Database administration** | pgAdmin 4 | Latest Stable (v8.x+) | Developer schema administration, `EXPLAIN ANALYZE` profiling, backup/restore drills |
| **Frontend validation** | Zod | Zod (v3.x+) | Form schema validation, client-side anti-bypass pattern blocking, API boundary types |
| **Backend validation** | FluentValidation, if adopted in the approved implementation | FluentValidation 11.x+ | Strongly-typed request DTO validation, server-side anti-bypass verification |
| **Frontend tests** | Vitest + Playwright | Vitest + Playwright | Vitest for unit/component tests; Playwright for browser end-to-end user journeys |
| **Backend tests** | xUnit | xUnit 2.x+ | Automated domain unit testing, state machine verification, and integration tests |
| **Session approach** | Secure cookie-based sessions, with backend authorization | Secure, HttpOnly, SameSite cookies | Secure cookie-based sessions with backend authorization; no tokens in localStorage |
| **Background processing** | PostgreSQL-backed outbox and worker where needed | PostgreSQL outbox + .NET hosted worker | Reliable, transactional asynchronous event processing, SMS/WhatsApp notifications |

---

## 3. Backend Technology Specification (ASP.NET Core & C# on .NET 10 LTS)

### 3.1 Compiler & Runtime Configuration (`Directory.Build.props`)
All C# projects in the solution share a unified root `Directory.Build.props` configuration targeting .NET 10 LTS:

    <Project>
      <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <LangVersion>latest</LangVersion>
        <Nullable>enable</Nullable>
        <ImplicitUsings>enable</ImplicitUsings>
        <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
        <InvariantGlobalization>false</InvariantGlobalization>
      </PropertyGroup>
    </Project>

### 3.2 Standardized NuGet Package Inventory

| NuGet Package | Version | Project Target | Purpose |
| :--- | :--- | :--- | :--- |
| `Npgsql.EntityFrameworkCore.PostgreSQL` | Compatible with .NET 10 / EF Core 10 | `Infrastructure` | Compatible PostgreSQL database provider for Entity Framework Core |
| `EFCore.NamingConventions` | Compatible with EF Core 10 | `Infrastructure` | Automatically maps C# `PascalCase` entities to PostgreSQL `snake_case` |
| `FluentValidation.DependencyInjectionExtensions` | `11.x` | `Application` | Backend validation (if adopted in the approved implementation) for request DTOs |
| `Serilog.AspNetCore` | Compatible with .NET 10 | `Api` | Structured JSON request and application logging |
| `Serilog.Enrichers.Environment` | Latest stable | `Api` | Enriches logs with machine, environment, and thread diagnostics |
| `Microsoft.AspNetCore.Authentication.Cookies` | Built-in (.NET 10) | `Api`, `Infrastructure` | Secure cookie-based sessions with backend authorization |
| `Swashbuckle.AspNetCore` / `Microsoft.AspNetCore.OpenApi` | Latest stable | `Api` | OpenAPI specification and Swagger UI generation |
| `AspNetCore.HealthChecks.NpgSql` | Latest stable | `Api` | Liveness and PostgreSQL readiness health probes |
| `xUnit` / `Testcontainers.PostgreSql` | Latest stable | `Tests` | Backend tests: automated unit, domain state machine, and PostgreSQL integration testing |

---

## 4. Database, ORM & Database Administration Specification

### 4.1 PostgreSQL 16 Standards
* **Primary Keys:** Sequential UUIDs (`uuid` in PostgreSQL, `Guid` in C#) generated by the application layer (`UUIDv7` pattern) to avoid B-Tree index fragmentation.
* **Monetary Storage:** All prices, unit rates, transport fees, taxes, and commissions are stored as 64-bit signed integers (`bigint` in PostgreSQL, `long` in C#) denominated in **paise** ($1\text{ INR} = 100\text{ paise}$).
* **Timestamps:** All dates and times use `timestamp with time zone` (`timestamptz`) mapped to C# `DateTimeOffset` in UTC (`TimeSpan.Zero`).
* **Extensions Required:**
  * `pg_trgm`: Trigram matching for fast fuzzy search on material names and locality pin codes.
  * `pg_stat_statements`: Tracks execution latency and buffer hits for slow-query inspection in pgAdmin 4.

### 4.2 Entity Framework Core Standards (EF Core + Compatible Npgsql Provider)
* **Approach:** Code-First with Fluent API (`IEntityTypeConfiguration<T>`) using Entity Framework Core 10 on .NET 10 LTS. Data Annotations are strictly prohibited in the `Domain` layer.
* **Provider:** Compatible Npgsql EF Core provider verified against the installed .NET 10 SDK and EF Core version.
* **Connection Pooling:** Managed via singleton `NpgsqlDataSource` (`Minimum Pool Size=5; Maximum Pool Size=100; Connection Idle Lifetime=300`).
* **Concurrency:** Optimistic concurrency enforced via PostgreSQL's system `xmin` column (`.IsRowVersion()`).

### 4.3 pgAdmin 4 Operational Standards
* **Local Access:** Provisioned via Docker Compose at `http://localhost:5050` and pre-linked to the local PostgreSQL 16 container.
* **Core Workflows:**
  1. Visual verification of EF Core Code-First migrations (`pk_`, `fk_`, `ix_`, `uq_` constraints).
  2. Query plan profiling (`EXPLAIN (ANALYZE, BUFFERS, VERBOSE)`) for material search and admin reporting queries.
  3. Role privilege management (`buildmate_migrator` vs. `buildmate_runtime`).
  4. Executing compressed custom-format (`-Fc`) backups and point-in-time recovery (PITR) drills.

---

## 5. Frontend Technology Specification (Next.js & TypeScript)

### 5.1 Core Frontend Stack
* **Framework:** Next.js (App Router) with React and TypeScript (`strict: true`).
* **Server vs. Client Rendering:**
  * **React Server Components (RSC):** Used for public material catalog pages, SEO landing pages, and initial dashboard shells.
  * **Client Components (`'use client'`):** Restricted to interactive leaf components (OTP login forms, search filter drawers, order checkout wizards, seller status toggles).
* **State & Data Fetching:**
  * **TanStack Query v5 (`@tanstack/react-query`):** Manages client-side API caching, pagination, polling for order status updates, and optimistic UI mutations.
  * **Zustand:** Manages lightweight global UI state (selected city/pincode context, filter drawer visibility).
* **Styling & Design System:**
  * **Tailwind CSS + Radix UI / Shadcn Primitives:** High-contrast, mobile-first utility styling designed for outdoor construction-site readability.

### 5.2 Frontend Validation (Zod)
* **Technology:** **Zod** schema validation.
* **Usage & Scope:**
  * Enforces strongly-typed schema validation at form boundaries (paired with React Hook Form) and client-side API input boundaries.
  * Enforces anti-bypass regex validation on user inputs (blocking phone numbers, email addresses, and contact leakage in public review/inquiry fields).
  * Keeps validation contracts aligned with backend rules while providing immediate, localized client-side feedback.

### 5.3 Frontend Tests (Vitest + Playwright)
* **Unit & Component Testing (Vitest):**
  * Fast, Vite-native unit and component test runner for React components, custom hooks, utility formatters (e.g., paise-to-INR currency calculations), and Zod schema validations.
  * Executed in CI pipeline on every push and PR.
* **Browser End-to-End Testing (Playwright):**
  * Automated cross-browser user journey verification testing customer ordering, seller order acceptance, and admin verification workflows.
  * Validates responsive mobile viewports (narrow mobile, tablet, and desktop) under realistic outdoor site condition constraints.

---

## 6. Repository & Solution Directory Layout

    build-mate/
    ├── docker-compose.yml                  # PostgreSQL + pgAdmin 4 local orchestration
    ├── Directory.Build.props               # Shared .NET 10 LTS compiler settings
    ├── BuildMate.sln                       # Root .NET Solution file
    ├── src/
    │   ├── backend/
    │   │   ├── BuildMate.Domain/           # Enterprise entities, value objects, enums, state rules
    │   │   ├── BuildMate.Application/      # Use-case services, DTOs, FluentValidation, interfaces
    │   │   ├── BuildMate.Infrastructure/   # EF Core DbContext, migrations, Npgsql, SMS/Storage adapters
    │   │   └── BuildMate.Api/              # ASP.NET Core controllers, middleware, Program.cs
    │   └── web/                            # Next.js + TypeScript frontend application
    │       ├── e2e/                        # Playwright end-to-end journey tests
    │       ├── public/
    │       ├── src/
    │       │   ├── app/                    # Next.js App Router route groups ((public), (customer), (seller), (admin))
    │       │   ├── components/             # UI primitives and domain feature components
    │       │   ├── hooks/                  # Custom React hooks
    │       │   ├── lib/                    # Fetch wrapper, formatters (paise-to-INR), utilities
    │       │   ├── schemas/                # Zod validation schemas
    │       │   ├── services/               # Typed API client services & TanStack Query keys
    │       │   ├── stores/                 # Zustand stores
    │       │   └── types/                  # Generated OpenAPI TypeScript interfaces
    │       ├── __tests__/                  # Vitest unit and component tests
    │       ├── vitest.config.ts            # Vitest test configuration
    │       ├── playwright.config.ts        # Playwright browser test configuration
    │       ├── next.config.mjs
    │       ├── package.json
    │       └── tsconfig.json
    └── tests/
        ├── BuildMate.UnitTests/            # Domain state machine & Application unit tests (xUnit)
        └── BuildMate.IntegrationTests/     # API, EF Core & PostgreSQL container tests (xUnit + Testcontainers)

---

## 7. Communication & Integration Protocols

### 7.1 Frontend-to-Backend API Contract & Session Approach
* **Protocol:** HTTPS REST JSON API versioned under `/api/v1/...`.
* **Session Approach:** **Secure cookie-based sessions, with backend authorization**. The ASP.NET Core backend manages `HttpOnly`, `Secure`, `SameSite=Strict` session cookies; credentials and tokens are never exposed to `localStorage`, `sessionStorage`, or client-side JavaScript. Server-side role-based and resource-based authorization validates all operations.
* **Standard Response Envelope:** All API responses use a deterministic JSON envelope (`ApiResponse<T>` for success and RFC 7807 `ProblemDetails` for errors).
* **Contract Synchronization:** `openapi-typescript` generates `src/web/src/types/api-schema.d.ts` directly from the ASP.NET Core Swagger specification (`/swagger/v1/swagger.json`).

### 7.2 Background Processing & Asynchronous Outbox
* **Background Processing:** **PostgreSQL-backed outbox and worker where needed**. Order lifecycle events (`OrderPlaced`, `OrderAccepted`, `OrderDispatched`, `OrderDelivered`) are persisted into the PostgreSQL `outbox_messages` table within the same EF Core database transaction and dispatched reliably and asynchronously by an ASP.NET Core `BackgroundService` hosted worker.
* **Webhook Verification:** Incoming webhooks from payment gateways and masked-calling/SMS providers are verified via HMAC-SHA256 signature headers and processed idempotently using PostgreSQL unique event keys.