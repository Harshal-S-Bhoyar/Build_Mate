# BUILD MATE — Master Documentation Manifest

**Document ID:** BM-DOC-MANIFEST-001  
**Version:** 1.1  
**Status:** Canonical Documentation Index & Source of Truth  
**Last Updated:** October 2026  
**Project:** BUILD MATE Construction-Material Marketplace  

---

## 1. Purpose & Documentation Architecture

This manifest establishes the single canonical index for all BUILD MATE technical and product documentation. It bridges the repository directory structure with the approved specifications stored in [`Project_Documents/`](file:///Users/siddharth/Building_Material/Project_Documents/), maps dependencies, and declares the source of truth for all architectural and engineering decisions.

All developers and AI coding agents must consult this manifest before designing or implementing features.

---

## 2. Canonical Technical Baseline

| Layer / Concern | Approved Standard | Reference Documentation |
| :--- | :--- | :--- |
| **Frontend Framework** | Next.js App Router (React, TypeScript `strict: true`) | [`04_next_js_and_typescript_frontend_architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/04_next_js_and_typescript_frontend_architecture.md) |
| **UI & Styling** | Tailwind CSS + Accessible Radix/Shadcn Primitives | [`Design.md`](file:///Users/siddharth/Building_Material/Project_Documents/Design.md) |
| **Frontend Validation** | Zod (Forms + Anti-Bypass Regex Validation) | [`techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md) |
| **Backend Runtime** | **.NET 10 LTS** with C# | [`01_asp_net_core_backend_architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/01_asp_net_core_backend_architecture.md) |
| **Backend Architecture** | Clean Architecture Modular Monolith (`Api`, `Application`, `Domain`, `Infrastructure`) | [`Architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Architecture.md) |
| **Data Access & ORM** | Entity Framework Core 10 with compatible `Npgsql` provider (**Prisma is strictly prohibited**) | [`02_entity_framework_core_data_access_standards.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/02_entity_framework_core_data_access_standards.md) |
| **Database Engine** | PostgreSQL 16+ (ACID, JSONB snapshots, Trigram GIN indexing) | [`03_postgresql_and_pgadmin_database_design.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/03_postgresql_and_pgadmin_database_design.md) |
| **Database Administration**| pgAdmin 4 (Profiling, Query Analysis, Role Separation) | [`03_postgresql_and_pgadmin_database_design.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/03_postgresql_and_pgadmin_database_design.md) |
| **Monetary Precision** | **Integer Paise** (`bigint` in PostgreSQL, `long` in C#) — NO floating point or raw decimal rupees | [`techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md) |
| **Session Management** | Secure HttpOnly Cookie-based sessions with server-side authorization | [`Authentication-and-Security.md`](file:///Users/siddharth/Building_Material/Project_Documents/Authentication-and-Security.md) |
| **Backend Validation** | FluentValidation on Application Request DTOs | [`techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md) |
| **Backend Testing** | xUnit + Testcontainers (PostgreSQL integration) | [`Testing-QA-and-Debugging.md`](file:///Users/siddharth/Building_Material/Project_Documents/Testing-QA-and-Debugging.md) |
| **Frontend Testing** | Vitest (unit/components) + Playwright (browser E2E) | [`Testing-QA-and-Debugging.md`](file:///Users/siddharth/Building_Material/Project_Documents/Testing-QA-and-Debugging.md) |
| **Async Processing** | PostgreSQL transactional outbox + .NET Hosted Background Worker | [`techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md) |

---

## 3. Core Document Mapping & Repository Locations

The physical documents are stored in the [`Project_Documents/`](file:///Users/siddharth/Building_Material/Project_Documents/) folder. Below is the mapping between standard canonical references and the actual repository paths:

### Core Requirements & Domain Specifications
| Canonical Reference | Repository Path | Description |
| :--- | :--- | :--- |
| `AGENTS.md` | [`AGENTS.md`](file:///Users/siddharth/Building_Material/AGENTS.md) | Agent operational rules, technical baseline, and MCP skills |
| `docs/DEVELOPMENT_PLAN.md` | [`docs/DEVELOPMENT_PLAN.md`](file:///Users/siddharth/Building_Material/docs/DEVELOPMENT_PLAN.md) | Phased project development plan, implementation sequence, and agent execution gates |
| `docs/DOCUMENT-MANIFEST.md` | [`docs/DOCUMENT-MANIFEST.md`](file:///Users/siddharth/Building_Material/docs/DOCUMENT-MANIFEST.md) | Master documentation index (this document) |
| `docs/BRD.md` | [`Project_Documents/BRD.md`](file:///Users/siddharth/Building_Material/Project_Documents/BRD.md) | Business Requirements Document: Problem statement, market opportunity, goals |
| `docs/PRD.md` | [`Project_Documents/PRD.md`](file:///Users/siddharth/Building_Material/Project_Documents/PRD.md) | Product Requirements Document: User personas, journeys, feature roadmap |
| `docs/DRD.md` | [`Project_Documents/DRD.md`](file:///Users/siddharth/Building_Material/Project_Documents/DRD.md) | Detailed Requirements Document: Functional, validation, and domain constraints |
| `docs/techstack.md` | [`Project_Documents/Tech-stack/techstack.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/techstack.md) | Comprehensive enterprise technical stack matrix and standards |
| `docs/01_backend_architecture.md` | [`Project_Documents/Tech-stack/01_asp_net_core_backend_architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/01_asp_net_core_backend_architecture.md) | ASP.NET Core Clean Architecture, DI, and middleware pipeline |
| `docs/02_ef_core_data_access.md` | [`Project_Documents/Tech-stack/02_entity_framework_core_data_access_standards.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/02_entity_framework_core_data_access_standards.md) | EF Core Code-First conventions, interceptors, and Npgsql setup |
| `docs/03_postgresql_database_design.md`| [`Project_Documents/Tech-stack/03_postgresql_and_pgadmin_database_design.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/03_postgresql_and_pgadmin_database_design.md) | PostgreSQL schema, tables, GIN indexes, pgAdmin 4 workflows |
| `docs/04_nextjs_frontend_architecture.md`| [`Project_Documents/Tech-stack/04_next_js_and_typescript_frontend_architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/04_next_js_and_typescript_frontend_architecture.md) | Next.js App Router, RSC vs Client boundaries, and UI structure |

### Architecture, Security & Standards
| Canonical Reference | Repository Path | Description |
| :--- | :--- | :--- |
| `docs/05_api_design.md` | [`Project_Documents/Tech-stack/05_restful_api_design_and_openapi_contracts.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/05_restful_api_design_and_openapi_contracts.md) | REST API endpoints, DTO conventions, and ApiResponse wrapper |
| `docs/06_auth_design.md` | [`Project_Documents/Tech-stack/06_authentication_phone_otp_and_rbac_authorization.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/06_authentication_phone_otp_and_rbac_authorization.md) | OTP authentication, cookie transport, and RBAC authorization |
| `docs/07_frontend_state.md` | [`Project_Documents/Tech-stack/07_frontend_state_management_and_data_fetching.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/07_frontend_state_management_and_data_fetching.md) | TanStack Query caching and Zustand global UI state |
| `docs/08_error_logging.md` | [`Project_Documents/Tech-stack/08_global_error_handling_and_structured_logging.md`](file:///Users/siddharth/Building_Material/Project_Documents/Tech-stack/08_global_error_handling_and_structured_logging.md) | Serilog structured logging, correlation IDs, and ProblemDetails |
| `docs/Architecture.md` | [`Project_Documents/Architecture.md`](file:///Users/siddharth/Building_Material/Project_Documents/Architecture.md) | System-level architecture and component boundary guidelines |
| `docs/Authentication-and-Security.md` | [`Project_Documents/Authentication-and-Security.md`](file:///Users/siddharth/Building_Material/Project_Documents/Authentication-and-Security.md) | Identity policies, CSRF/CORS, and contact-privacy security gates |
| `docs/Database.md` | [`Project_Documents/Database.md`](file:///Users/siddharth/Building_Material/Project_Documents/Database.md) | High-level entity specifications and snapshot rules |
| `docs/API.md` | [`Project_Documents/API.md`](file:///Users/siddharth/Building_Material/Project_Documents/API.md) | Master API endpoint catalog and response codes |
| `docs/Design.md` | [`Project_Documents/Design.md`](file:///Users/siddharth/Building_Material/Project_Documents/Design.md) | Visual design system, accessible UI, and layout rules |
| `docs/Testing-QA-and-Debugging.md` | [`Project_Documents/Testing-QA-and-Debugging.md`](file:///Users/siddharth/Building_Material/Project_Documents/Testing-QA-and-Debugging.md) | Multi-layered test strategy and quality assurance gates |
| `docs/Project-Implementation-and-Setup.md` | [`Project_Documents/Project-Implementation-and-Setup.md`](file:///Users/siddharth/Building_Material/Project_Documents/Project-Implementation-and-Setup.md) | Environment setup, tool checks, and bootstrap commands |

### Feature Specifications 01–19 ([`Project_Documents/Feature/`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/))
- `01-authentication-and-sessions.md`: Phone OTP, registration, session revocation
- `02-customer-profile-and-addresses.md`: Saved delivery sites and geo-pinning
- `03-seller-onboarding-and-verification.md`: KYC, GST, yard location, verification workflow
- `04-material-listings-and-delivery-capacity.md`: Bundled material + vehicle capacity listings
- `05-search-and-filtering.md`: Hyperlocal pincode search, trigram matching, filtering
- `06-order-quote-and-checkout.md`: Server-side pricing calculation, single-seller loads, snapshots
- `07-order-lifecycle-and-delivery-status.md`: Order states, transitions, timeline tracking
- `08-contact-privacy-platform-messaging-masked-calling.md`: Anti-bypass chat & masked calling
- `09-sms-notifications.md`: Transactional SMS templates and outbox processing
- `10-whatsapp-business.md`: WhatsApp notification templates and webhooks
- `11-payments-refunds-and-reconciliation.md`: Financial gateway abstraction, audit, reconciliation
- `12-commissions-and-fees.md`: Platform commission engine and immutable fee snapshots
- `13-reviews-and-ratings.md`: Order-verified customer reviews and ratings
- `14-support-complaints-disputes.md`: Tickets, evidence submission, and dispute escalation
- `15-admin-dashboard-and-moderation.md`: Seller KYC approvals, listing review, operations
- `16-media-uploads.md`: Public catalog images vs private KYC documents
- `17-analytics-and-reporting.md`: GMV, delivery performance, and operational KPIs
- `18-audit-logging-and-privacy.md`: Immutable audit trail and PII redaction
- `19-seo-performance-accessibility.md`: Public SSR, OpenGraph, Core Web Vitals, a11y

---

## 4. Key Architectural Decisions (ADR)
All major architectural decisions are formally documented in [`docs/adr/`](file:///Users/siddharth/Building_Material/docs/adr/):
- **ADR 0001:** [Canonical Technical Baseline & Architecture](file:///Users/siddharth/Building_Material/docs/adr/0001-canonical-technical-baseline.md)

---

## 5. Unresolved Business Decisions
To prevent hallucinated policies or unapproved commercial terms, open business and commercial decisions are cataloged in:
- [UNRESOLVED-BUSINESS-DECISIONS.md](file:///Users/siddharth/Building_Material/docs/UNRESOLVED-BUSINESS-DECISIONS.md)
