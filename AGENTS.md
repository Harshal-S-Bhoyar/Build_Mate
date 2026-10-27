# Agent Guidelines

## BUILD MATE — Technical Baseline & Business Rules

### Canonical Technical Baseline
- **Frontend:** Next.js App Router, React, TypeScript (`strict: true`), Tailwind CSS.
- **Backend:** ASP.NET Core Web API with C# on **.NET 10 LTS**.
- **ORM:** Entity Framework Core 10 with compatible `Npgsql` provider (`Npgsql.EntityFrameworkCore.PostgreSQL`).
- **Data Architecture:** PostgreSQL 16+ as the single source of truth; pgAdmin 4 for database administration.
- **Financial Precision:** All monetary amounts, quotes, rates, and commissions are stored and transmitted as **64-bit integer paise** (`bigint` in DB, `long` in C#, `number` in TS) to eliminate floating-point rounding errors.
- **Session & Auth:** Secure cookie-based sessions with backend authorization; no tokens in localStorage.
- **Frontend Validation:** Zod schemas for boundary validation and anti-bypass protection.
- **Backend Validation:** FluentValidation on Application DTOs.
- **Testing:** xUnit for backend unit/integration tests; Vitest and Playwright for frontend unit and E2E tests.
- **Strict Negative Constraints:**
  - DO NOT introduce Prisma as backend ORM.
  - DO NOT add Redis, message brokers (Kafka/RabbitMQ), microservices, or external analytics warehouses without an explicit requirement and documented ADR.
  - DO NOT store plain contact numbers or private addresses in public responses.

### Non-Negotiable Business Rules
1. **Bundled Listing:** Every orderable listing bundles construction material and delivery from the same seller into a single offer.
2. **Order Cardinality:** An MVP order references exactly one customer, one seller, and one listing.
3. **Contact Privacy (Anti-Bypass):** Private customer and seller contact details must never appear in public listing results or search APIs. Platform messaging is the default communication channel.
4. **Authoritative Backend:** The backend owns authorization, pricing, quote calculation, and order state transitions. Frontend values are untrusted.
5. **No Invented Policies:** Do not invent payment, commission rates, cancellation terms, refund policies, or dispute rules.

### Source of Truth & Documentation
- **Master Documentation Index:** [DOCUMENT-MANIFEST.md](file:///Users/siddharth/Building_Material/docs/DOCUMENT-MANIFEST.md)
- **Project Development Plan:** [DEVELOPMENT_PLAN.md](file:///Users/siddharth/Building_Material/docs/DEVELOPMENT_PLAN.md)
- **Architectural Decision Records:** [docs/adr/](file:///Users/siddharth/Building_Material/docs/adr/) (see [0001-canonical-technical-baseline.md](file:///Users/siddharth/Building_Material/docs/adr/0001-canonical-technical-baseline.md))
- **Unresolved Business Decisions:** [UNRESOLVED-BUSINESS-DECISIONS.md](file:///Users/siddharth/Building_Material/docs/UNRESOLVED-BUSINESS-DECISIONS.md)
- **Detailed Specifications:** [Project_Documents/](file:///Users/siddharth/Building_Material/Project_Documents/)

### Phased Implementation Discipline
Coding agents must strictly follow the sequential phases in [docs/DEVELOPMENT_PLAN.md](file:///Users/siddharth/Building_Material/docs/DEVELOPMENT_PLAN.md) and adhere to the Canonical Technical Baseline:
1. **One Phase at a Time:** Finish, verify, and checkpoint one phase before starting the next. Never attempt to build the entire platform in a single prompt.
2. **Phase Boundary Stop Rule:** Stop at the defined phase boundary, execute verification commands, and report results before requesting approval to move to the next phase.
3. **Strict Policy Boundaries:** Never invent business, commercial, financial, fee, commission, or refund policies.

## Agent skills

### Issue tracker

Issues and PRDs live on GitHub Issues (via `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical triage roles mapped to standard labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context layout using `CONTEXT-MAP.md` at root pointing to per-package/per-service `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Workspace skills

Project-specific skills are located in [`.agents/skills/`](file:///Users/siddharth/Building_Material/.agents/skills) (and linked via [`skills/`](file:///Users/siddharth/Building_Material/skills)):
- **`diagnose`**: Disciplined 6-phase loop for hard bugs and performance regressions ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/diagnose/SKILL.md))
- **`tdd`**: Test-driven development with red-green-refactor loop ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/tdd/SKILL.md))
- **`grill-with-docs`**: Grilling session updating `CONTEXT.md` and ADRs inline ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/grill-with-docs/SKILL.md))
- **`improve-codebase-architecture`**: Deepen modules and rescue codebase architecture ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/improve-codebase-architecture/SKILL.md))
- **`to-issues`**: Break plans/specs into tracer-bullet vertical slice issues ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/to-issues/SKILL.md))
- **`to-prd`**: Synthesize context into a PRD issue ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/to-prd/SKILL.md))
- **`triage`**: Process issues through a triage state machine ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/triage/SKILL.md))
- **`zoom-out`**: Higher-level perspective on module context and callers ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/zoom-out/SKILL.md))
- **`grill-me`**: Relentless interactive interview to stress-test designs ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/grill-me/SKILL.md))
- **`caveman`**: Ultra-compressed communication mode cutting token usage ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/caveman/SKILL.md))
- **`write-a-skill`**: Standardized workflow for writing agent skills ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/write-a-skill/SKILL.md))
- **`git-guardrails`**: Intercept destructive git commands ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/git-guardrails/SKILL.md))
- **`setup-pre-commit`**: Husky and lint-staged configuration ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/setup-pre-commit/SKILL.md))
- **`migrate-to-shoehorn`**: Migrate test type assertions to shoehorn ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/migrate-to-shoehorn/SKILL.md))
- **`scaffold-exercises`**: Scaffold exercise directories and stubs ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/scaffold-exercises/SKILL.md))
- **`obsidian-vault`**: Search and manage Obsidian vault notes ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/obsidian-vault/SKILL.md))
- **`edit-article`**: Improve prose and manage information dependency order ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/edit-article/SKILL.md))
- **`egm-brainstorm`**: Upstream multi-lens ideation generating `concepts_brief.md` ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-brainstorm/SKILL.md))
- **`egm-draft`**: Turn concept briefs into formal specifications under `docs/designs/` ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-draft/SKILL.md))
- **`egm-review`**: Stress-test specs using zero-context Goldfish subagent reviews ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-review/SKILL.md))
- **`egm-review-loop`**: Autonomous iterative spec refinement with Goldfish swarms ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-review-loop/SKILL.md))
- **`egm-drift-report`**: Audit code implementation vs design specs for architectural drift ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-drift-report/SKILL.md))
- **`egm-bootstrap`**: Generate hierarchical README codebase maps for Elephants ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/egm-bootstrap/SKILL.md))
- **`unlazy`**: Completion discipline for substantial work via runnable acceptance gates and Depth Tree ([`SKILL.md`](file:///Users/siddharth/Building_Material/.agents/skills/unlazy/SKILL.md))


<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**This project has a knowledge graph. Start with the code-review-graph
MCP tools to narrow scope, then read the source.** The graph is cheaper than scanning files and
gives you structural context (callers, dependents, test coverage) that file search cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool` instead of Grep
- **Understanding impact**: `get_impact_radius_tool` instead of manually tracing imports
- **Code review**: `detect_changes_tool` + `get_review_context_tool` instead of reading entire files
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

### Verify in the source

- Narrow scope with the graph, then read the source. Do not change code from graph output alone.
- For any non-trivial change, read the implementation and the relevant tests before concluding.
- Verify the exact source when touching behavior, database logic, migrations, retries, fallbacks,
  recovery, or compatibility code.
- When the graph and the source disagree, the source wins. The graph may be stale or may not
  model that relationship.
- An empty graph result can mean "not indexed" or "not statically visible", not "does not exist".

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Understanding blast radius of a change |
| `get_affected_flows_tool` | Finding which execution paths are impacted |
| `query_graph_tool` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes_tool` | Finding functions/classes by name or keyword |
| `get_architecture_overview_tool` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes_tool` for code review.
3. Use `get_affected_flows_tool` to understand impact.
4. Use `query_graph_tool` pattern="tests_for" to check coverage.
<!-- /code-review-graph MCP tools -->
