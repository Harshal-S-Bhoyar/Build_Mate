# BUILD MATE — Documentation Manifest

**Document ID:** BM-MANIFEST-001  
**Version:** 1.0  
**Status:** Master documentation index  
**Last updated:** 26 October 2026  
**Project:** BUILD MATE construction-material marketplace  
**Working brand:** Provisional

---

## 1. Purpose

This manifest is the master index for the BUILD MATE product and engineering documentation. It lists the complete planned set of 35 individual Markdown files, explains their roles, provides a recommended reading order and maps the implementation dependencies between features.

The documentation is intended to support development by a human engineering team or an AI coding agent. It is not proof that the application, endpoints, integrations, database schema or deployment have already been implemented.

Each file should be maintained independently under the repository's `docs/` directory.

## 2. Technology baseline

The current documentation baseline is:

| Area | Selected baseline |
|---|---|
| Frontend | Next.js App Router, React and TypeScript |
| UI | Tailwind CSS and approved accessible component patterns |
| Frontend validation | TypeScript and Zod where appropriate |
| Backend | ASP.NET Core Web API on .NET 10 LTS |
| Backend language | C# |
| Database | PostgreSQL |
| Data access | Entity Framework Core 10 and compatible Npgsql provider |
| API | REST/JSON under `/api/v1` |
| Authentication | ASP.NET Core Identity by default, with an approved browser session strategy |
| Authorization | Server-side role-based and resource-based authorization |
| Frontend unit/component tests | Vitest |
| Browser end-to-end tests | Playwright |
| Backend tests | xUnit and API integration tests |
| Database changes | EF Core migrations |
| Async processing | PostgreSQL-backed outbox and .NET hosted worker where appropriate |
| External services | Provider interfaces with mock/fake implementations |
| CI/CD | Automated build, validation, test and controlled release workflow |

### Technology-change rule

The files in this package use EF Core/Npgsql for the .NET backend. Do not silently replace that design with Prisma, another ORM, a different backend runtime or another database strategy. Any architecture change must be approved, documented in an Architecture Decision Record (ADR), and propagated to every affected document and project file.

Redis, a message broker, microservices and an external analytics warehouse are not required by default. Add them only when a documented need justifies their operational complexity.

## 3. Non-negotiable product rules

1. Every orderable listing combines construction material and delivery into one bundled offer.
2. One seller is responsible for the bundled offer.
3. An MVP order references one customer, one seller and one listing.
4. BUILD MATE is not a public seller-contact directory.
5. Seller and customer private contact details are not exposed through public listing/search APIs.
6. Platform messaging is the default communication channel; masked calling is enabled only after provider privacy behavior is verified.
7. The backend owns authorization, prices, order eligibility and status transitions.
8. Confirmed order terms and delivery details are snapshotted.
9. Payment status and order status are separate.
10. Provider failures must not be displayed as successes.
11. Reviews and trust signals must be based on genuine eligible records.
12. No commission, payment, cancellation, refund or legal policy may be invented by a coding agent.
13. Verification documents are private.
14. Sensitive actions are permissioned and appropriately audited.
15. Real production integrations require configuration, tests and explicit release approval.

## 4. Complete inventory — 35 documents

### Group A — Core product and business requirements

| No. | Filename | Purpose |
|---:|---|---|
| 1 | `BRD.md` | Business case, stakeholders, goals, scope, business rules, risks and revenue hypotheses |
| 2 | `PRD.md` | Product goals, personas, page journeys, feature priority, metrics and release acceptance |
| 3 | `DRD.md` | Detailed functional, domain, API, validation, security and acceptance requirements |

### Group B — Architecture, security and data

| No. | Filename | Purpose |
|---:|---|---|
| 4 | `Architecture.md` | Logical architecture, technology decisions, modules, dependencies and deployment |
| 5 | `Authentication-and-Security.md` | Identity, sessions, authorization, contact privacy, secure uploads and security gates |
| 6 | `Database.md` | PostgreSQL entities, relationships, constraints, indexes, statuses, snapshots and migrations |

### Group C — Design and engineering workflows

| No. | Filename | Purpose |
|---:|---|---|
| 7 | `Design.md` | Design system, pages, components, responsive behavior and accessibility |
| 8 | `Feature-Development.md` | Feature roadmap, dependencies, implementation workflow and definition of done |
| 9 | `Project-Implementation-and-Setup.md` | Repository bootstrap, prerequisites, configuration, local environment and initial setup |
| 10 | `Testing-QA-and-Debugging.md` | Testing layers, quality gates, security tests and debugging workflow |
| 11 | `Development Plan.md` | Phased development plan, execution sequence, operating rules, and checkpoints |

### Group D — Project entry points and API/integrations

| No. | Filename | Purpose |
|---:|---|---|
| 11 | `README.md` | Project introduction, setup commands, technology, phases and production checklist |
| 12 | `Agent.md` | AI coding-agent instructions, autonomy boundaries, safety rules and work reporting |
| 13 | `API.md` | REST endpoint inventory, DTO conventions, authorization, idempotency and errors |
| 14 | `Integration.md` | Provider adapters, retries, notifications, webhooks, storage and operational integration rules |
| 15 | `MCP-Connection.md` | Optional Model Context Protocol architecture, tool restrictions and safe AI tooling |

### Group E — Feature specifications 01–05

| No. | Filename | Purpose |
|---:|---|---|
| 16 | `01-authentication-and-sessions.md` | Registration, login, logout, verification, sessions and access control |
| 17 | `02-customer-profile-and-addresses.md` | Customer profiles, saved addresses, default address and order-address privacy |
| 18 | `03-seller-onboarding-and-verification.md` | Seller applications, private evidence, review decisions and seller eligibility |
| 19 | `04-material-listings-and-delivery-capacity.md` | Material specifications, bundled delivery listings, pricing modes and capacity |
| 20 | `05-search-and-filtering.md` | Public search, category/quantity/area filters, eligibility, sorting and pagination |

### Group F — Feature specifications 06–10

| No. | Filename | Purpose |
|---:|---|---|
| 21 | `06-order-quote-and-checkout.md` | Order submission, quote lifecycle, server-calculated price and immutable snapshots |
| 22 | `07-order-lifecycle-and-delivery-status.md` | Seller response, status transitions, delivery progress, cancellation and disputes |
| 23 | `08-contact-privacy-platform-messaging-masked-calling.md` | Private communication, thread authorization, reports and provider-gated masked calling |
| 24 | `09-sms-notifications.md` | SMS templates, outbox processing, provider adapter, retries and delivery status |
| 25 | `10-whatsapp-business.md` | WhatsApp Business templates, eligibility, consent, callbacks and delivery outcomes |

### Group G — Feature specifications 11–15

| No. | Filename | Purpose |
|---:|---|---|
| 26 | `11-payments-refunds-and-reconciliation.md` | Payments, verified callbacks, refunds, reconciliation and financial exceptions |
| 27 | `12-commissions-and-fees.md` | Fee-policy configuration, calculation, snapshots and financial audit |
| 28 | `13-reviews-and-ratings.md` | Completed-order reviews, eligibility, aggregation and moderation |
| 29 | `14-support-complaints-disputes.md` | Tickets, complaints, dispute review, evidence and resolution workflows |
| 30 | `15-admin-dashboard-and-moderation.md` | Seller/listing review, order operations, support queues and controlled reporting |

### Group H — Final feature specifications and manifest

| No. | Filename | Purpose |
|---:|---|---|
| 31 | `16-media-uploads.md` | Public listing images, private documents, validation, storage and moderation |
| 32 | `17-analytics-and-reporting.md` | Business KPIs, operational reports, data quality and analytics privacy |
| 33 | `18-audit-logging-and-privacy.md` | Audit trail, log redaction, data minimization, retention and privacy requests |
| 34 | `19-seo-performance-accessibility.md` | Public discoverability, metadata, performance, responsive UI and accessibility |
| 35 | `DOCUMENT-MANIFEST.md` | Master document inventory, implementation dependencies and decision register |

**Total planned documents: 35.**

## 5. Recommended reading order for the coding agent

Before implementation:
1. `Agent.md`
2. `README.md`
3. `BRD.md`
4. `PRD.md`
5. `DRD.md`
6. `Architecture.md`
7. `Database.md`
8. `API.md`
9. `Authentication-and-Security.md`
10. `Design.md`
11. `Feature-Development.md`
12. `Project-Implementation-and-Setup.md`
13. `Testing-QA-and-Debugging.md`
14. `Integration.md`
15. `MCP-Connection.md` if MCP tooling is being considered.

The agent must then read the specific feature specification assigned to the task and the documents on which that feature depends.

Do not ask an AI coding agent to implement all 35 documents' requirements in one operation. Work through bounded, testable milestones.

## 6. Dependency map

| Feature | Prerequisites | Recommended delivery phase |
|---|---|---|
| Repository/bootstrap | None | Phase 0 |
| API health, logging and error handling | Repository/bootstrap | Phase 0 |
| Authentication and sessions | Foundation | Phase 1 |
| Customer profile and addresses | Authentication | Phase 2 |
| Seller onboarding and verification | Authentication, storage foundation | Phase 3 |
| Media upload foundation | Storage interface and security controls | Phase 3–4 |
| Material catalog and bundled listings | Seller eligibility and database foundation | Phase 4 |
| Search/filtering | Approved active listings | Phase 5 |
| Order/quote/checkout | Authentication, addresses, listings, price rules | Phase 6 |
| Order lifecycle/delivery status | Order submission | Phase 7 |
| Platform messaging | Authentication and eligible orders/enquiries | Phase 8 |
| SMS notifications | Notification outbox and business events | Phase 9 |
| WhatsApp Business | Notification/event design and provider approval | Phase 10 |
| Masked calling | Privacy-safe participants and validated provider | Phase 10 or later |
| Payments/refunds | Order lifecycle, commercial policy and provider approval | Conditional |
| Commissions/fees | Approved business fee model and financial records | Conditional |
| Reviews/ratings | Genuine eligible completed orders | After completion workflow |
| Support/disputes | Authentication, orders and support authorization | Before broad public launch |
| Admin/moderation | Authentication and audited operations | Minimum controls in P0 |
| Analytics/reporting | Reliable records and defined KPI formulas | Phase 13 |
| Audit/privacy | Foundation and all sensitive features | Start in Phase 0; extend continuously |
| SEO/performance/accessibility | Frontend foundation and public page contracts | Continuous, with release gate |
| MCP connection | Specific use case and security review | Optional; not a launch dependency |

This table is a dependency map, not permission to bypass cross-cutting security and testing. Security, accessibility, audit and tests must be developed alongside features rather than postponed to the end.

## 7. Recommended implementation phases

### Phase 0 — Engineering foundation
Create the frontend/backend projects, PostgreSQL connection, migrations, configuration templates, CI checks, health endpoints and safe logging.

**Exit gate:** Local setup is reproducible; builds and tests run; secrets are not committed.

### Phase 1 — Authentication
Implement the approved login/session design and enforce role/resource permissions.

**Exit gate:** Unauthenticated and wrong-owner requests fail securely.

### Phase 2 — Customer profile and addresses
Implement profile/address CRUD, default-address integrity and privacy-safe snapshots.

**Exit gate:** A customer cannot read another customer's data.

### Phase 3 — Seller onboarding
Implement seller applications, evidence upload, moderation and seller eligibility.

**Exit gate:** Unapproved sellers cannot publish orderable listings.

### Phase 4 — Catalog and bundled listings
Implement categories, listing management, price modes, availability and moderation.

**Exit gate:** Every orderable offer bundles material and delivery from one eligible seller.

### Phase 5 — Search
Implement public search and listing detail using the canonical eligibility rules.

**Exit gate:** Search output is accurate, bounded and privacy-safe.

### Phase 6 — Order/quote/checkout
Implement server-side pricing, idempotency, accepted-term snapshots and the seller-response request.

**Exit gate:** No duplicate order/price tampering and no broken snapshot integrity.

### Phase 7 — Order lifecycle
Implement seller acceptance/rejection, preparation, dispatch, delivery and approved cancellation/dispute paths.

**Exit gate:** Status transitions and histories are server-enforced and auditable.

### Phase 8 — Communication
Implement authorized platform messages, privacy boundaries and support linkage.

**Exit gate:** Unrelated users cannot access threads or private order data.

### Phase 9 — Notification foundation
Implement the durable notification outbox, worker, templates and deterministic mock providers.

**Exit gate:** Provider failure does not falsify order state.

### Phase 10 — Conditional integrations
Enable real SMS, WhatsApp Business or masked calling only after provider, consent/privacy, cost and operational requirements are verified.

**Exit gate:** Provider contract, failure, privacy and callback tests pass.

### Phase 11 — Financial capabilities
Implement payments/refunds/reconciliation and commissions/fees only after the owner approves the commercial model and operational responsibilities.

**Exit gate:** Amounts, callbacks, refunds and ledgers reconcile reliably.

### Phase 12 — Trust and support
Implement completed-order reviews, complaints and dispute handling.

**Exit gate:** Reviews link to real eligible orders; support workflows preserve privacy and audit trails.

### Phase 13 — Operations, analytics and release
Complete admin monitoring/reporting, privacy/retention checks, backups, accessibility, performance measurements and pilot acceptance.

**Exit gate:** The business owner approves a controlled launch using measurable criteria.

## 8. Requirement traceability

Every high-impact requirement should be traceable from business intent to implementation and test.

Recommended traceability chain:

`BRD business rule → PRD user journey → DRD detailed requirement → feature specification → API/database implementation → automated test → release acceptance`

For each requirement, track:
- Requirement ID or stable reference.
- Source document and section.
- Implemented module/endpoint.
- Test name or test case.
- Status.
- Remaining decision/blocker.

Do not mark a requirement completed solely because the documentation is written.

## 9. Architecture and policy change management

A change to backend runtime, ORM, database, authentication, permissions, order semantics, fee policy, data retention or external provider requires an explicit decision.

For an architecture change, create an ADR containing:
- Context/problem.
- Options considered.
- Decision and rationale.
- Trade-offs.
- Security/privacy implications.
- Data/migration impact.
- Documents/files to update.
- Date and approval.

For a business-policy change, record the owner decision, affected feature requirements, UI/API/database implications and required test changes.

Update this manifest if files are renamed or if the development order materially changes.

## 10. Open decision register

The following are not fully finalized by this documentation package and must be explicitly decided.

### Market and operations
- Exact initial Nagpur-area pilot service zone.
- Seller recruitment and onboarding process.
- Initial supported unit list and category-specific material specifications.
- Available quantity versus per-load capacity semantics.
- Listing freshness interval and availability confirmation policy.

### Authentication and checkout
- Mandatory login versus guest request flow.
- Password, OTP/passwordless or another approved authentication mode.
- Verification channels and recovery process.
- Fixed-price order confirmation semantics.
- Quote state transitions, expiry and acceptance.
- Seller response deadline.
- Cancellation and delivery-confirmation rules.
- Delivery evidence requirements.
- Dispute windows and resolution/appeal policy.

### Commercial and finance
- Payment methods and payment timing.
- Platform fee/commission model.
- Who pays each fee.
- Taxes, rounding and financial presentation.
- Refund eligibility and approval permissions.
- Seller settlement/payout arrangement.
- Reconciliation process and accounting ownership.
- Treatment of cash/manual payments, if any.

### Provider and privacy decisions
- SMS provider and applicable sender/template registration.
- WhatsApp Business provider, account/template setup and messaging preferences.
- Masked-calling provider and verified two-party privacy behavior.
- Object-storage provider and private/public storage architecture.
- Maps/geocoding use, if required.
- Data-sharing terms and retention for each provider.
- Privacy-request owner and incident response responsibilities.

### Product and deployment
- Domain and brand clearance for BUILD MATE.
- Hosting region/provider and budget.
- Production logging/monitoring.
- Backups and recovery objectives.
- Public seller profile policy.
- Review publication/moderation policy.
- Legal, privacy, consumer, tax and transport/sourcing advice needed for the actual operating model.
- Source-code ownership, maintenance responsibilities and production access.

No AI coding agent may silently choose a high-impact commercial, legal, privacy or financial rule from this register.

## 11. Controlled pilot acceptance

Before a public or controlled pilot, verify that:
- A customer can discover an eligible material-plus-delivery offer.
- A customer can submit a valid order/quote request under approved pricing rules.
- Seller eligibility and listing moderation are enforced.
- Order snapshots and status history are reliable.
- Private contact information and documents are protected.
- Cancellation and support paths are documented and usable.
- Required integrations have safe mock paths and truthful failure behavior.
- Admin can manage verification, listings and core operational exceptions.
- Automated tests cover critical authorization, privacy, transaction and state-transition rules.
- Terms, privacy notices and relevant business policies are approved.
- Monitoring, rollback, backup and incident responsibilities are assigned.
- The owner has agreed on measurable pilot success criteria.

Do not treat page count, seller sign-ups, mock orders or fabricated analytics as evidence of product-market fit.

## 12. Suggested documentation status labels

Use one of the following labels in tracked progress reports:
- `Drafted` — the specification text exists.
- `Reviewed` — a responsible reviewer has checked consistency.
- `Approved` — relevant owner/technical decision has been approved.
- `InImplementation` — code work is underway.
- `Implemented` — implementation exists.
- `Tested` — named acceptance tests have actually passed.
- `Released` — enabled in the intended environment with required checks.
- `Blocked` — progress depends on a named unresolved decision or dependency.

A document can be drafted while the feature is not implemented. Keep these statuses separate.

## 13. Master acceptance checklist

- [ ] All 35 intended Markdown filenames are present.
- [ ] Internal document names and cross-references are consistent.
- [ ] Technology choices do not contradict approved architecture decisions.
- [ ] Every feature has explicit dependencies and acceptance criteria.
- [ ] Public/private data boundaries are documented.
- [ ] Order, payment and quote lifecycles are kept distinct.
- [ ] External integrations have mock and failure handling.
- [ ] Tests can be traced to important requirements.
- [ ] Open decisions have a named owner.
- [ ] Implementation status is reported separately from specification status.
- [ ] Pilot gates are based on real, measurable behavior.

## 14. Final principle

The goal of this documentation set is to help BUILD MATE be built incrementally, correctly and safely. The documents are a shared engineering contract: the coding agent should follow them, developers should test them, and the product owner should explicitly approve changes where business choices remain open.

The website must not merely look complete. It must protect private data, offer accurate bundled material-and-delivery listings, preserve the terms customers accept, coordinate real orders honestly and provide a reliable route for handling failures.
