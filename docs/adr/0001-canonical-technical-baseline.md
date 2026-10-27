# ADR 0001: Canonical Technical Baseline and Clean Architecture

- **Status:** Accepted
- **Date:** October 2026
- **Deciders:** Technical Lead & Architecture Team
- **Consulted:** [`AGENTS.md`](file:///Users/siddharth/Building_Material/AGENTS.md), [`techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md), [`Architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Architecture.md)

---

## 1. Context & Problem Statement

BUILD MATE is a hyperlocal B2B/B2C marketplace connecting construction buyers, builders, and contractors with local verified suppliers of bulk construction materials (Black Stone, River Sand, Crushed Sand, Red Bricks, Murum, Aggregate) bundled with verified vehicle delivery capacity (Tippers, Tractors, Hyvas).

The system requires:
1. High-throughput, deterministic transactions and strict state machine lifecycle management.
2. Complete contact privacy (anti-bypass) preventing direct phone number and address leakage prior to order confirmation.
3. Zero floating-point rounding drift in bulk financial quotes and platform fee calculations.
4. Mobile-first, low-latency UI for field users on Indian mobile networks, paired with a dense admin console.
5. Strong, type-safe API boundaries and testability across both frontend and backend.

Past discussions and documentation revisions contained potential discrepancies (e.g., Prisma mentions as negative constraints, EF Core 8 vs .NET 10, decimal rupees vs integer paise, cookie sessions vs JWT bearers). A definitive Architectural Decision Record is required to lock the canonical technical baseline.

---

## 2. Decision Matrix

### 2.1 Backend Runtime & Language
- **Decision:** ASP.NET Core Web API with C# targeting **.NET 10 LTS**.
- **Rationale:** .NET 10 LTS provides high-performance asynchronous I/O, native JSON serialization, built-in dependency injection, and enterprise-grade reliability for high-volume transactions.
- **Repository Structure:** Clean Architecture Modular Monolith:
  - `src/backend/BuildMate.Domain`: Pure domain entities, value objects, domain events, state machine enums (no ORM or framework dependencies).
  - `src/backend/BuildMate.Application`: Use cases, CQRS/service interfaces, Request DTOs, FluentValidation validators.
  - `src/backend/BuildMate.Infrastructure`: Entity Framework Core DbContext, Npgsql configuration, outbox implementation, external provider adapters.
  - `src/backend/BuildMate.Api`: HTTP controllers, Program.cs, middleware pipeline, Serilog configuration, health endpoints.

### 2.2 Data Access & ORM: Entity Framework Core 10 (Strictly No Prisma)
- **Decision:** **Entity Framework Core 10** with `Npgsql.EntityFrameworkCore.PostgreSQL`.
- **Negative Constraint:** **Prisma is strictly prohibited** for the backend ORM.
- **Rationale:** EF Core 10 offers first-class LINQ-to-SQL translation, Code-First migrations, interceptors for automated audit trails, and native support for PostgreSQL-specific features (arrays, JSONB, GIN indexing).

### 2.3 Database Engine & Administration: PostgreSQL 16 + pgAdmin 4
- **Decision:** PostgreSQL 16+ as the single relational source of truth; pgAdmin 4 for developer query tuning and inspection.
- **Rationale:** ACID compliance, row-level locking (`FOR UPDATE`), trigram indexing (`pg_trgm`) for fuzzy material/locality search, and native array support for serviceable pincodes (`text[]`).

### 2.4 Financial Precision: 64-Bit Integer Paise
- **Decision:** All monetary fields (material base prices, delivery fees, platform fees, taxes, discounts, order totals, and ledger entries) are stored and transmitted as **64-bit signed integers** (`bigint` in PostgreSQL, `long` in C#, `number` in TypeScript) denominated in **paise** ($1\text{ INR} = 100\text{ paise}$).
- **Rationale:** Eliminates floating-point rounding errors and database decimal precision discrepancies across clients and servers. Frontend formats paise to formatted INR (`₹`) via a centralized currency utility.

### 2.5 Frontend Architecture: Next.js App Router & TypeScript
- **Decision:** Next.js (App Router), React, TypeScript (`strict: true`), Tailwind CSS.
- **Rationale:** React Server Components (RSC) enable fast, SEO-optimized, contact-redacted server rendering for public listing pages, while Client Components (`'use client'`) handle interactive forms, OTP verification, and order tracking.

### 2.6 Session & Authentication Strategy
- **Decision:** Secure cookie-based sessions with backend authorization (`HttpOnly`, `Secure`, `SameSite=Strict/Lax`).
- **Rationale:** Tokens and sensitive credentials must never be stored in browser `localStorage` or `sessionStorage` where they are vulnerable to XSS. Backend maintains authoritative session state and role/resource permissions.

### 2.7 Validation Strategy
- **Decision:** Dual-layer boundary validation:
  - **Frontend:** Zod for form validation and anti-bypass pattern detection (blocking phone numbers and emails in inquiry/review fields).
  - **Backend:** FluentValidation on Application Request DTOs before business logic execution.

### 2.8 Asynchronous Processing: Transactional Outbox
- **Decision:** PostgreSQL-backed `outbox_messages` table polled by an ASP.NET Core `BackgroundService` hosted worker.
- **Negative Constraint:** No external message brokers (RabbitMQ, Kafka) or distributed caches (Redis) in the baseline.
- **Rationale:** Guarantees atomic writes (order status + outbox notification in the same DB transaction) without the operational overhead of managing separate broker clusters in Phase 1.

### 2.9 Testing Strategy
- **Decision:**
  - **Backend:** xUnit for domain unit tests; Testcontainers with PostgreSQL for integration and migration tests.
  - **Frontend:** Vitest for component/utility testing; Playwright for cross-browser end-to-end journey tests.

---

## 3. Non-Negotiable Business Rules

1. **Bundled Material + Delivery Listing:** Every orderable listing bundles construction material and vehicle delivery capacity from the same seller.
2. **Order Cardinality:** An MVP order references exactly one customer, one seller, and one listing.
3. **Contact Privacy & Anti-Bypass:** Public search and listing APIs must redact seller phone numbers, yard addresses, and KYC documents. Platform messaging is the default communication channel.
4. **Authoritative Backend:** The backend owns pricing, totals, and state transitions. Clients cannot submit prices or arbitrary state changes.
5. **No Invented Commercial Policies:** Commission rates, payment collection timings, refund terms, and cancellation penalties require explicit product-owner approval.

---

## 4. Consequences

### Positive
- Strict architectural boundaries preventing logic leakage between layers.
- Elimination of financial rounding bugs by standardizing on integer paise.
- Zero credential exposure on frontend clients due to HttpOnly cookie sessions.
- Lean operational footprint (PostgreSQL + .NET + Next.js without unnecessary microservice/broker overhead).

### Negative / Trade-offs
- Developers must maintain C# EF Core configurations and TypeScript interfaces in sync (mitigated via OpenAPI contract generation).
- Integer paise requires explicit UI formatting before displaying to end users.
