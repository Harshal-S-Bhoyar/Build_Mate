# BUILD MATE — Database Design

**Document ID:** BM-DB-001  
**Version:** 1.0  
**Status:** Proposed relational design  
**Last updated:** 26 October 2026  
**Database:** PostgreSQL 18 (supported current minor release)  
**Data access:** Entity Framework Core 10 with a compatible Npgsql EF Core provider

---

## 1. Purpose and design principles

PostgreSQL is the system of record for users, seller verification, customer addresses, bundled material/delivery listings, orders, status history, payments/fees, communications, notifications, reviews, support and audit events.

Principles:
- Relational integrity for core entities and foreign keys.
- Central, canonical status values shared by application code and tests.
- Fixed-point values for currency and fractional quantity; never binary floating point for money.
- Immutable commercial snapshot for confirmed orders.
- Strict separation between public listing data and private contact/document data.
- Query-driven indexing, not indiscriminate indexes.
- EF Core migrations tracked in source control and tested before deployment.
- No frontend/direct browser access to the database.
- No secrets or raw payment credentials in database records.

## 2. Conventions

- **Primary keys:** PostgreSQL `uuid`, mapped to C# `Guid`.
- **Timestamps:** `timestamptz` in UTC; API timestamps serialized as ISO 8601 UTC.
- **Money:** `numeric(12,2)` for INR monetary fields unless a documented limit requires adjustment.
- **Quantity:** `numeric(12,3)` where fractional amounts are allowed; validation depends on unit/category.
- **Currency:** explicit ISO code (`INR` for initial launch).
- **Names:** snake_case database columns/tables such as `created_at_utc` and `seller_id`; configure naming consistently in EF Core.
- **Enums/statuses:** central C# enums with a consistent string representation in PostgreSQL/API. Add constraints for critical status fields where appropriate.
- **Concurrency:** use a version/concurrency token or database transaction/locking strategy where capacity or state races are possible.
- **Deletion:** restrict deletes of orders, payments, ledgers, status history and audits. Use approved anonymization/retention workflows where required.
- **Migrations:** use EF Core migrations; do not use `EnsureCreated()` in production.

## 3. Identity and user records

### 3.1 Identity provider

Use ASP.NET Core Identity unless a documented decision selects another maintained implementation. If Identity is used, retain its standard identity/role/token tables and do not create a second password store. Extend the user record for approved application profile fields.

Recommended custom `users`/Identity-user fields:
- `id uuid primary key`
- `display_name varchar(120) not null`
- `normalized_email varchar(256) null`
- `normalized_phone varchar(20) null`
- `phone_verified_at_utc timestamptz null`
- `email_verified_at_utc timestamptz null`
- `account_status varchar(24) not null`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

The actual table names may follow Identity's `AspNetUsers` conventions or a documented snake_case mapping; choose one before generating migrations and keep it consistent.

### 3.2 Customer profiles — `customer_profiles`
- `id uuid primary key`
- `user_id uuid not null unique references users(id)` (or equivalent Identity table)
- `preferred_name varchar(120) null`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

One user has zero or one customer profile. If the product allows multiple roles per identity, store roles/claims separately rather than duplicating accounts.

### 3.3 Customer addresses — `customer_addresses`
- `id uuid primary key`
- `customer_user_id uuid not null references users(id)`
- `label varchar(60) null`
- `recipient_name varchar(120) not null`
- `recipient_phone_private varchar(20) not null`
- `address_line_1 varchar(200) not null`
- `address_line_2 varchar(200) null`
- `locality varchar(120) not null`
- `city varchar(100) not null`
- `district varchar(100) null`
- `state varchar(100) not null`
- `postal_code varchar(12) not null`
- `latitude numeric(9,6) null`
- `longitude numeric(9,6) null`
- `delivery_instructions text null`
- `is_default boolean not null default false`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

Indexes: `(customer_user_id)`. Add a partial unique index to enforce at most one default address per customer where `is_default = true`. Only the address owner may manage it. Store an address snapshot on the order.

## 4. Seller profile and verification

### 4.1 `seller_profiles`
- `id uuid primary key`
- `user_id uuid not null unique references users(id)`
- `display_name varchar(160) not null`
- `legal_business_name varchar(200) null`
- `business_type varchar(40) not null`
- `description text null`
- `verification_status varchar(24) not null`
- `seller_status varchar(24) not null`
- `service_area_summary varchar(200) null`
- `public_rating_average numeric(3,2) null`
- `public_rating_count integer not null default 0`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

Suggested verification statuses: `NotSubmitted`, `PendingReview`, `Approved`, `Rejected`, `Suspended`, `Expired`. Suggested seller statuses: `Active`, `Paused`, `Suspended`, `Closed`. Verification and account status must not be conflated.

### 4.2 `seller_verification_documents`
- `id uuid primary key`
- `seller_id uuid not null references seller_profiles(id)`
- `document_type varchar(50) not null`
- `private_storage_key text not null`
- `original_filename varchar(255) null`
- `content_type varchar(100) not null`
- `file_size_bytes bigint not null`
- `verification_state varchar(24) not null`
- `reviewed_by_user_id uuid null references users(id)`
- `reviewed_at_utc timestamptz null`
- `review_reason_code varchar(80) null`
- `created_at_utc timestamptz not null`

Store a private object-storage key, not a public URL. Only authorized reviewers and the relevant seller under policy can access the document. Public DTOs never include document keys.

## 5. Material categories and specifications

### 5.1 `material_categories`
- `id uuid primary key`
- `code varchar(40) not null unique`
- `name varchar(100) not null`
- `description text null`
- `is_active boolean not null`
- `sort_order integer not null`
- `created_at_utc timestamptz not null`

Initial codes: `BLACK_STONE`, `SAND`, `BRICKS`, `MURUM`.

### 5.2 `material_specifications`
- `id uuid primary key`
- `category_id uuid not null references material_categories(id)`
- `name varchar(120) not null`
- `grade_or_size varchar(120) null`
- `description text null`
- `is_active boolean not null`
- `created_at_utc timestamptz not null`

Store material attributes used for search/filter as typed fields or controlled category-specific schemas. Do not put important queryable fields only into an unvalidated free-form JSON blob.

## 6. Material listings — bundled material + delivery

`material_listings` is the principal marketplace listing table.

- `id uuid primary key`
- `seller_id uuid not null references seller_profiles(id)`
- `category_id uuid not null references material_categories(id)`
- `specification_id uuid null references material_specifications(id)`
- `title varchar(180) not null`
- `description text null`
- `available_quantity numeric(12,3) not null`
- `quantity_unit varchar(24) not null`
- `minimum_order_quantity numeric(12,3) not null`
- `price_mode varchar(24) not null` — `FixedDeliveredPrice` or `QuoteRequired`
- `delivered_unit_price numeric(12,2) null`
- `currency char(3) not null default 'INR'`
- `delivery_included boolean not null`
- `included_charges_description text null`
- `excluded_charges_description text null`
- `service_area_json jsonb not null`
- `availability_start_utc timestamptz null`
- `availability_end_utc timestamptz null`
- `estimated_lead_time_hours integer null`
- `truck_type varchar(80) null`
- `truck_capacity numeric(12,3) null`
- `truck_capacity_unit varchar(24) null`
- `listing_status varchar(24) not null`
- `moderation_status varchar(24) not null`
- `last_availability_confirmed_at_utc timestamptz null`
- `version integer not null default 1`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`
- `published_at_utc timestamptz null`

Constraints:
- Available and minimum quantities are greater than zero.
- Minimum order does not exceed available capacity under the selected capacity model.
- `delivery_included` must be true for an orderable MVP listing.
- Fixed delivered-price listings require a positive delivered price.
- Quote-required listings must explicitly indicate quote mode; the UI may not imply that a fixed final price is known.
- Lead time, if set, must be positive.
- Only eligible approved sellers and approved listings can be public/orderable.

Initial indexes:
- `(listing_status, moderation_status, category_id)`
- `(seller_id, listing_status)`
- `(category_id, listing_status, delivered_unit_price)`
- JSONB service-area index only if supported by actual query patterns.

The implementation must decide before coding whether service areas use a validated `jsonb` structure or normalized tables. Do not mix representations casually. Use realistic test data and `EXPLAIN ANALYZE` before tuning search indexes.

## 7. Listing media

`listing_media`:
- `id uuid primary key`
- `listing_id uuid not null references material_listings(id)`
- `storage_key text not null`
- `alt_text varchar(200) null`
- `sort_order integer not null`
- `moderation_state varchar(24) not null`
- `created_at_utc timestamptz not null`

Only approved listing media is publicly served. Use separate policies and storage areas for public listing images and private documents.

## 8. Orders and immutable snapshots

### 8.1 `orders`
- `id uuid primary key`
- `public_order_number varchar(32) not null unique`
- `customer_user_id uuid not null references users(id)`
- `seller_id uuid not null references seller_profiles(id)`
- `listing_id uuid not null references material_listings(id)`
- `order_status varchar(32) not null`
- `payment_status varchar(24) not null`
- `quantity numeric(12,3) not null`
- `quantity_unit varchar(24) not null`
- `material_category_code varchar(40) not null`
- `material_title_snapshot varchar(180) not null`
- `material_spec_snapshot jsonb not null`
- `seller_display_name_snapshot varchar(160) not null`
- `unit_price_snapshot numeric(12,2) null`
- `subtotal_amount numeric(12,2) null`
- `delivery_amount numeric(12,2) not null default 0`
- `platform_fee_amount numeric(12,2) not null default 0`
- `discount_amount numeric(12,2) not null default 0`
- `tax_amount numeric(12,2) not null default 0`
- `total_amount numeric(12,2) null`
- `currency char(3) not null default 'INR'`
- `delivery_address_snapshot jsonb not null`
- `delivery_requested_at_utc timestamptz null`
- `confirmed_terms_snapshot jsonb not null`
- `seller_response_deadline_utc timestamptz null`
- `accepted_at_utc timestamptz null`
- `delivered_at_utc timestamptz null`
- `completed_at_utc timestamptz null`
- `cancelled_at_utc timestamptz null`
- `cancellation_reason_code varchar(80) null`
- `dispute_status varchar(24) null`
- `version integer not null default 1`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

Rules:
- Every MVP order references one customer, one seller and one listing.
- Server calculates totals; non-negative constraints apply to monetary components where appropriate.
- Snapshot material, unit, quantity, delivery terms, price, fee, seller identity reference, address and accepted terms when the order becomes confirmed under the product flow.
- Protect retries with an idempotency record/unique key.
- Do not store raw card details or payment secrets.
- Keep payment status independent from order status.

Indexes:
- `(customer_user_id, created_at_utc desc)`
- `(seller_id, order_status, created_at_utc desc)`
- `(order_status, created_at_utc)`
- Unique `public_order_number`

### 8.2 `order_status_history`
- `id uuid primary key`
- `order_id uuid not null references orders(id)`
- `from_status varchar(32) null`
- `to_status varchar(32) not null`
- `actor_user_id uuid null references users(id)`
- `actor_role varchar(24) not null`
- `reason_code varchar(80) null`
- `note_internal text null`
- `created_at_utc timestamptz not null`
- `correlation_id varchar(80) null`

History is append-only for ordinary application roles. Index by `(order_id, created_at_utc)`.

## 9. Payments, refunds and platform fees

### 9.1 `payments`
- `id uuid primary key`
- `order_id uuid not null references orders(id)`
- `provider_code varchar(50) not null`
- `provider_payment_reference varchar(180) null`
- `payment_method varchar(40) not null`
- `payment_status varchar(24) not null`
- `amount numeric(12,2) not null`
- `currency char(3) not null default 'INR'`
- `idempotency_key varchar(120) null`
- `initiated_at_utc timestamptz not null`
- `confirmed_at_utc timestamptz null`
- `failure_code varchar(100) null`
- `created_at_utc timestamptz not null`

Use provider references and event-deduplication constraints that match the selected gateway.

### 9.2 `refunds`
- `id uuid primary key`
- `payment_id uuid not null references payments(id)`
- `amount numeric(12,2) not null`
- `reason_code varchar(80) not null`
- `refund_status varchar(24) not null`
- `provider_refund_reference varchar(180) null`
- `requested_by_user_id uuid not null references users(id)`
- `created_at_utc timestamptz not null`
- `completed_at_utc timestamptz null`

### 9.3 Fees and ledger

`fee_policies` fields: `id`, `name`, `fee_type`, optional `rate numeric(7,4)`, optional `fixed_amount numeric(12,2)`, `effective_from_utc`, `effective_to_utc`, `is_active`, `created_by_user_id`, `created_at_utc`.

`commission_ledger_entries` fields: `id`, `order_id`, `seller_id`, optional `fee_policy_id`, `gross_order_amount`, `platform_fee_amount`, optional `seller_amount`, `entry_status`, `created_at_utc`.

Store the applied fee/policy snapshot per order. Fee changes must not alter old orders and must be audited. Business owner must approve the fee formula before production fees are collected.

## 10. Messages and communications

### 10.1 `message_threads`
- `id uuid primary key`
- `order_id uuid null references orders(id)`
- `enquiry_id uuid null`
- `thread_status varchar(24) not null`
- `created_at_utc timestamptz not null`

### 10.2 `message_thread_participants`
- `thread_id uuid not null references message_threads(id)`
- `user_id uuid not null references users(id)`
- `participant_role varchar(24) not null`
- Primary key `(thread_id, user_id)`

### 10.3 `messages`
- `id uuid primary key`
- `thread_id uuid not null references message_threads(id)`
- `sender_user_id uuid not null references users(id)`
- `body text not null`
- `moderation_status varchar(24) not null`
- `created_at_utc timestamptz not null`
- `redacted_at_utc timestamptz null`

### 10.4 `communication_events`
- `id uuid primary key`
- `order_id uuid null references orders(id)`
- `thread_id uuid null references message_threads(id)`
- `channel varchar(24) not null`
- `provider_code varchar(50) null`
- `provider_reference varchar(180) null`
- `event_status varchar(24) not null`
- `started_at_utc timestamptz null`
- `ended_at_utc timestamptz null`
- `duration_seconds integer null`
- `created_at_utc timestamptz not null`

Do not record call audio by default. Capture only the metadata needed for operational support and audit.

## 11. Notification outbox

`notification_outbox` fields:
- `id uuid primary key`
- `event_type varchar(80) not null`
- `aggregate_type varchar(40) not null`
- `aggregate_id uuid not null`
- `recipient_user_id uuid null references users(id)`
- `channel varchar(24) not null`
- `template_code varchar(80) not null`
- `payload_json jsonb not null`
- `delivery_status varchar(24) not null`
- `attempt_count integer not null default 0`
- `next_attempt_at_utc timestamptz null`
- `last_error_code varchar(100) null`
- `created_at_utc timestamptz not null`
- `sent_at_utc timestamptz null`

Index for polling by delivery status and next-attempt timestamp. Keep payloads minimal, redact logs, retry transient failures with bounds, and expose exhausted failures to operations.

## 12. Reviews, support and audit

### 12.1 `reviews`
- `id uuid primary key`
- `order_id uuid not null unique references orders(id)`
- `customer_user_id uuid not null references users(id)`
- `seller_id uuid not null references seller_profiles(id)`
- `rating smallint not null check (rating between 1 and 5)`
- `review_text varchar(2000) null`
- `moderation_status varchar(24) not null`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`

Only an eligible customer for a completed order may create a review.

### 12.2 `support_tickets`
- `id uuid primary key`
- `public_ticket_number varchar(32) not null unique`
- `created_by_user_id uuid not null references users(id)`
- `order_id uuid null references orders(id)`
- `ticket_type varchar(40) not null`
- `priority varchar(20) not null`
- `ticket_status varchar(24) not null`
- `subject varchar(180) not null`
- `description text not null`
- `assigned_to_user_id uuid null references users(id)`
- `resolution_code varchar(80) null`
- `created_at_utc timestamptz not null`
- `updated_at_utc timestamptz not null`
- `resolved_at_utc timestamptz null`

Access is limited to the creator, relevant parties permitted by policy, assigned support, and authorized admins.

### 12.3 `audit_events`
- `id uuid primary key`
- `actor_user_id uuid null references users(id)`
- `actor_role varchar(24) null`
- `action varchar(100) not null`
- `entity_type varchar(60) not null`
- `entity_id uuid null`
- `correlation_id varchar(80) null`
- `safe_metadata_json jsonb null`
- `created_at_utc timestamptz not null`

Do not store passwords, OTPs, tokens, payment secrets or unnecessary personal data in audit metadata. Sensitive audit records should be append-only for ordinary application roles.

## 13. Canonical statuses

Define these as centralized C# enum types and keep the same semantic values across persistence/API/tests:
- `AccountStatus`: `PendingVerification`, `Active`, `Suspended`, `Closed`
- `SellerVerificationStatus`: `NotSubmitted`, `PendingReview`, `Approved`, `Rejected`, `Suspended`, `Expired`
- `SellerStatus`: `Active`, `Paused`, `Suspended`, `Closed`
- `ListingStatus`: `Draft`, `PendingReview`, `Active`, `Paused`, `Rejected`, `Expired`, `Archived`
- `ModerationStatus`: `Pending`, `Approved`, `Rejected`, `Flagged`, `Removed`
- `PriceMode`: `FixedDeliveredPrice`, `QuoteRequired`
- `OrderStatus`: `PendingSellerResponse`, `Accepted`, `Preparing`, `OutForDelivery`, `Delivered`, `Completed`, `Rejected`, `Cancelled`, `Disputed`
- `PaymentStatus`: `NotRequired`, `Pending`, `Authorized`, `Paid`, `Failed`, `PartiallyRefunded`, `Refunded`, `Cancelled`
- `NotificationDeliveryStatus`: `Pending`, `Processing`, `Sent`, `Failed`, `DeadLettered`, `Cancelled`
- `TicketStatus`: `Open`, `InProgress`, `WaitingForCustomer`, `WaitingForSeller`, `Resolved`, `Closed`
- `ReviewModerationStatus`: `Pending`, `Approved`, `Rejected`, `Hidden`

Do not redefine these enums separately in feature modules. Any mapping to integer/string DB values must be explicit and tested.

## 14. Indexes, transactions and concurrency

Minimum indexes include customer orders by date, seller orders by state/date, public listing query fields, order history by order/date, notification outbox by state/retry time, tickets by status/assignment and reviews by seller/state. Add more indexes based on measured query plans.

Create orders, initial status history, audit record and notification outbox entry atomically where practical. Use an idempotency constraint for order submission and payment callbacks. Use a transaction/concurrency token or row locking to prevent two orders consuming the same limited capacity. All financial and state transitions are server-controlled.

## 15. EF Core implementation rules

1. Use EF Core migrations as the normal schema-evolution mechanism.
2. Review migration SQL for production-sensitive changes.
3. Configure decimal precision explicitly.
4. Configure FK delete behavior, indexes, unique constraints and names explicitly.
5. Use read-only/no-tracking queries when suitable and project to DTOs.
6. Avoid returning EF entity graphs from API endpoints.
7. Avoid unbounded `Include()` chains; create purpose-built queries.
8. Use transactions for multi-record business operations.
9. Never use `EnsureCreated()` in production.
10. Test migrations against PostgreSQL in CI or a controlled integration environment.

## 16. Privacy, retention, backup and recovery

- Private contact data and verification document keys never appear in public DTOs.
- Exact delivery addresses are exposed only to authorized parties for the relevant order.
- Redact personal data and secrets from logs.
- Define data-retention/deletion/anonymization rules with qualified advice; preserve records that must lawfully remain.
- Use synthetic sample data in local development; never seed real contact details or real documents.
- Backups should be access-controlled and encrypted; periodically test restoration.
- Document recovery-point and recovery-time objectives after choosing infrastructure.

## 17. Database readiness checklist

- [ ] PostgreSQL and Npgsql/EF Core compatibility verified.
- [ ] Canonical enum/status mapping established.
- [ ] Money and quantity precision configured.
- [ ] Foreign keys, unique constraints, check constraints and indexes defined.
- [ ] Public DTOs exclude private data.
- [ ] Order commercial snapshot is implemented.
- [ ] Idempotency/concurrency behavior is tested.
- [ ] Migrations apply to an empty DB and from previous schema versions.
- [ ] Seed data is synthetic.
- [ ] Backup and restore procedures are tested before public launch.
