# 03. PostgreSQL & pgAdmin 4 Database Design (`03_postgresql_database_design.md`)

## 1. PostgreSQL 16 Architecture & Storage Rules
BUILD MATE relies on **PostgreSQL 16** as its single system of record for transactional data, hyperlocal catalog search, financial ledgers, and transactional outbox queues.

### 1.1 Non-Negotiable Data Type Conventions
| Domain Concept | C# (.NET 8) Type | PostgreSQL 16 Type | Rationale & Constraint Rule |
| :--- | :--- | :--- | :--- |
| **Entity Primary Key** | `Guid` | `uuid` | Application-generated sequential `UUIDv7` prevents B-Tree index page splits. |
| **Monetary Amounts** | `long` | `bigint` | Stored strictly in integer **paise** ($1\text{ INR} = 100\text{ paise}$); eliminates floating-point rounding drift. |
| **Timestamps** | `DateTimeOffset` | `timestamptz` | Always persisted in UTC (`TimeSpan.Zero`). Local IST (`+05:30`) conversion occurs at the presentation layer. |
| **Pin Codes** | `string` | `char(6)` / `varchar(6)` | Enforced via `CHECK (pincode ~ '^[1-9][0-9]{5}$')`. |
| **Phone Numbers** | `string` | `varchar(15)` | Normalized E.164 format (`+919876543210`) with unique constraint on `users`. |
| **State / Status Enums** | `enum` | `varchar(40)` | Stored as human-readable uppercase strings (`PENDING_SELLER_RESPONSE`) with `CHECK` constraints. |
| **Snapshots & Metadata** | `string` / POCO | `jsonb` | Binary JSON for immutable order price/address snapshots and audit diffs. |

### 1.2 Required PostgreSQL Extensions
Executed during initial database bootstrap:

    CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

---

## 2. Core Relational Schema & DDL Definitions

All tables reside in the `public` schema using `snake_case` identifiers. Below are the core tables backing the BUILD MATE domain.

### 2.1 Identity & Profiles (`users`, `customer_profiles`, `customer_addresses`, `seller_profiles`)

    CREATE TABLE users (
        id uuid NOT NULL,
        phone_number varchar(15) NOT NULL,
        role varchar(20) NOT NULL,
        is_active boolean NOT NULL DEFAULT true,
        is_suspended boolean NOT NULL DEFAULT false,
        suspension_reason varchar(500) NULL,
        last_login_at_utc timestamptz NULL,
        created_at_utc timestamptz NOT NULL DEFAULT clock_timestamp(),
        updated_at_utc timestamptz NOT NULL DEFAULT clock_timestamp(),
        CONSTRAINT pk_users PRIMARY KEY (id),
        CONSTRAINT uq_users_phone_number UNIQUE (phone_number),
        CONSTRAINT ck_users_role CHECK (role IN ('CUSTOMER', 'SELLER', 'ADMIN'))
    );

    CREATE TABLE customer_profiles (
        id uuid NOT NULL,
        user_id uuid NOT NULL,
        full_name varchar(120) NOT NULL,
        company_or_builder_name varchar(150) NULL,
        preferred_language varchar(10) NOT NULL DEFAULT 'en',
        default_pincode varchar(6) NULL,
        created_at_utc timestamptz NOT NULL,
        updated_at_utc timestamptz NOT NULL,
        CONSTRAINT pk_customer_profiles PRIMARY KEY (id),
        CONSTRAINT uq_customer_profiles_user_id UNIQUE (user_id),
        CONSTRAINT fk_customer_profiles_users_user_id FOREIGN KEY (user_id)
            REFERENCES users (id) ON DELETE RESTRICT
    );

    CREATE TABLE customer_addresses (
        id uuid NOT NULL,
        customer_profile_id uuid NOT NULL,
        label varchar(60) NOT NULL,
        site_contact_name varchar(120) NOT NULL,
        address_line1 varchar(250) NOT NULL,
        landmark varchar(150) NULL,
        locality varchar(120) NOT NULL,
        city varchar(80) NOT NULL,
        state varchar(80) NOT NULL,
        pincode varchar(6) NOT NULL,
        latitude numeric(9,6) NULL,
        longitude numeric(9,6) NULL,
        is_default boolean NOT NULL DEFAULT false,
        is_deleted boolean NOT NULL DEFAULT false,
        created_at_utc timestamptz NOT NULL,
        updated_at_utc timestamptz NOT NULL,
        CONSTRAINT pk_customer_addresses PRIMARY KEY (id),
        CONSTRAINT fk_customer_addresses_customer_profiles_id FOREIGN KEY (customer_profile_id)
            REFERENCES customer_profiles (id) ON DELETE CASCADE,
        CONSTRAINT ck_customer_addresses_pincode CHECK (pincode ~ '^[1-9][0-9]{5}$')
    );

    CREATE TABLE seller_profiles (
        id uuid NOT NULL,
        user_id uuid NOT NULL,
        public_display_code varchar(30) NOT NULL,
        business_legal_name varchar(200) NOT NULL,
        gstin varchar(15) NULL,
        pan_number varchar(10) NULL,
        yard_locality varchar(120) NOT NULL,
        yard_city varchar(80) NOT NULL,
        yard_pincode varchar(6) NOT NULL,
        exact_yard_address_private varchar(300) NOT NULL,
        serviceable_pincodes text[] NOT NULL DEFAULT '{}',
        verification_status varchar(30) NOT NULL DEFAULT 'PENDING_REVIEW',
        verified_at_utc timestamptz NULL,
        verified_by_admin_id uuid NULL,
        average_rating numeric(3,2) NOT NULL DEFAULT 0.00,
        completed_orders_count integer NOT NULL DEFAULT 0,
        created_at_utc timestamptz NOT NULL,
        updated_at_utc timestamptz NOT NULL,
        CONSTRAINT pk_seller_profiles PRIMARY KEY (id),
        CONSTRAINT uq_seller_profiles_user_id UNIQUE (user_id),
        CONSTRAINT uq_seller_profiles_public_display_code UNIQUE (public_display_code),
        CONSTRAINT fk_seller_profiles_users_user_id FOREIGN KEY (user_id)
            REFERENCES users (id) ON DELETE RESTRICT,
        CONSTRAINT ck_seller_profiles_verification_status CHECK (
            verification_status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'SUSPENDED')
        )
    );

### 2.2 Material Catalog & Bundled Delivery Capacity (`material_categories`, `material_listings`)

    CREATE TABLE material_categories (
        id uuid NOT NULL,
        slug varchar(60) NOT NULL,
        name varchar(100) NOT NULL,
        standard_unit varchar(30) NOT NULL,
        display_order integer NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        CONSTRAINT pk_material_categories PRIMARY KEY (id),
        CONSTRAINT uq_material_categories_slug UNIQUE (slug),
        CONSTRAINT ck_material_categories_unit CHECK (
            standard_unit IN ('BRASS', 'CUBIC_FEET', 'METRIC_TON', 'PER_1000_BRICKS', 'TRUCK_LOAD')
        )
    );

    CREATE TABLE material_listings (
        id uuid NOT NULL,
        seller_profile_id uuid NOT NULL,
        category_id uuid NOT NULL,
        title varchar(160) NOT NULL,
        grade_or_specification varchar(120) NOT NULL,
        description varchar(1000) NOT NULL,
        vehicle_type varchar(40) NOT NULL,
        load_capacity_quantity numeric(10,2) NOT NULL,
        pricing_unit varchar(30) NOT NULL,
        base_material_price_paise bigint NOT NULL,
        bundled_delivery_charge_paise bigint NOT NULL,
        total_load_price_paise bigint NOT NULL,
        min_order_loads integer NOT NULL DEFAULT 1,
        max_order_loads integer NOT NULL DEFAULT 10,
        lead_time_hours integer NOT NULL DEFAULT 24,
        serviceable_pincodes text[] NOT NULL,
        status varchar(30) NOT NULL DEFAULT 'PENDING_MODERATION',
        is_deleted boolean NOT NULL DEFAULT false,
        created_at_utc timestamptz NOT NULL,
        updated_at_utc timestamptz NOT NULL,
        CONSTRAINT pk_material_listings PRIMARY KEY (id),
        CONSTRAINT fk_material_listings_seller_profiles_id FOREIGN KEY (seller_profile_id)
            REFERENCES seller_profiles (id) ON DELETE RESTRICT,
        CONSTRAINT fk_material_listings_material_categories_id FOREIGN KEY (category_id)
            REFERENCES material_categories (id) ON DELETE RESTRICT,
        CONSTRAINT ck_material_listings_prices_positive CHECK (
            base_material_price_paise > 0
            AND bundled_delivery_charge_paise >= 0
            AND total_load_price_paise = (base_material_price_paise + bundled_delivery_charge_paise)
        ),
        CONSTRAINT ck_material_listings_vehicle_type CHECK (
            vehicle_type IN ('TRACTOR_TROLLEY', 'MINI_TIPPER_1_BRASS', 'TIPPER_6_WHEEL_3_BRASS', 'HYVA_10_WHEEL_6_BRASS', 'HYVA_12_WHEEL')
        )
    );

### 2.3 Orders, State History & Financial Ledger (`orders`, `order_status_histories`, `commission_ledger_entries`)

    CREATE TABLE orders (
        id uuid NOT NULL,
        order_number varchar(32) NOT NULL,
        idempotency_key varchar(64) NOT NULL,
        customer_profile_id uuid NOT NULL,
        seller_profile_id uuid NOT NULL,
        material_listing_id uuid NOT NULL,
        status varchar(40) NOT NULL,
        ordered_loads_count integer NOT NULL,
        unit_load_price_snapshot_paise bigint NOT NULL,
        material_subtotal_paise bigint NOT NULL,
        delivery_charge_paise bigint NOT NULL,
        platform_commission_paise bigint NOT NULL,
        total_customer_payable_paise bigint NOT NULL,
        net_seller_payout_paise bigint NOT NULL,
        delivery_pincode varchar(6) NOT NULL,
        delivery_locality varchar(120) NOT NULL,
        delivery_address_snapshot_json jsonb NOT NULL,
        listing_snapshot_json jsonb NOT NULL,
        requested_delivery_date date NOT NULL,
        seller_response_deadline_utc timestamptz NOT NULL,
        accepted_at_utc timestamptz NULL,
        dispatched_at_utc timestamptz NULL,
        delivered_at_utc timestamptz NULL,
        cancelled_at_utc timestamptz NULL,
        cancellation_reason varchar(500) NULL,
        created_at_utc timestamptz NOT NULL,
        updated_at_utc timestamptz NOT NULL,
        CONSTRAINT pk_orders PRIMARY KEY (id),
        CONSTRAINT uq_orders_order_number UNIQUE (order_number),
        CONSTRAINT uq_orders_customer_idempotency UNIQUE (customer_profile_id, idempotency_key),
        CONSTRAINT fk_orders_customer_profiles_id FOREIGN KEY (customer_profile_id)
            REFERENCES customer_profiles (id) ON DELETE RESTRICT,
        CONSTRAINT fk_orders_seller_profiles_id FOREIGN KEY (seller_profile_id)
            REFERENCES seller_profiles (id) ON DELETE RESTRICT,
        CONSTRAINT fk_orders_material_listings_id FOREIGN KEY (material_listing_id)
            REFERENCES material_listings (id) ON DELETE RESTRICT,
        CONSTRAINT ck_orders_financial_integrity CHECK (
            ordered_loads_count > 0
            AND total_customer_payable_paise = (material_subtotal_paise + delivery_charge_paise)
            AND net_seller_payout_paise = (total_customer_payable_paise - platform_commission_paise)
        )
    );

---

## 3. High-Performance Indexing Strategy

To guarantee $< 25\text{ ms}$ ($p95$) query execution for hyperlocal material searches and dashboard filtering:

1. **GIN Index for Serviceable Pin Code Array Filtering:**
   Allows instant lookup of active listings serving a customer's 6-digit pin code (`WHERE serviceable_pincodes @> ARRAY['440001']`):

       CREATE INDEX ix_material_listings_serviceable_pincodes_gin
       ON material_listings USING gin (serviceable_pincodes)
       WHERE status = 'ACTIVE' AND is_deleted = false;

2. **Composite Partial Index for Public Catalog Search & Sorting:**

       CREATE INDEX ix_material_listings_category_status_price
       ON material_listings (category_id, total_load_price_paise ASC, created_at_utc DESC)
       WHERE status = 'ACTIVE' AND is_deleted = false;

3. **Trigram GIN Index for Keyword Search:**

       CREATE INDEX ix_material_listings_title_trgm
       ON material_listings USING gin (title gin_trgm_ops);

4. **Partial Unique Index for Single Default Customer Address:**
   Guarantees at the database level that a customer can have at most one default address:

       CREATE UNIQUE INDEX uq_customer_addresses_one_default_per_customer
       ON customer_addresses (customer_profile_id)
       WHERE is_default = true AND is_deleted = false;

5. **Outbox Worker Polling Index:**

       CREATE INDEX ix_outbox_messages_unprocessed
       ON outbox_messages (created_at_utc ASC)
       WHERE processed_at_utc IS NULL AND status != 'DEAD_LETTER';

---

## 4. pgAdmin 4 Administration & Query Tuning Workflows

### 4.1 Local & Staging Server Registration (`servers.json`)
In local development (`docker-compose.yml`), pgAdmin 4 runs on `http://localhost:5050`. Connect using:
* **Host name/address:** `postgres` (Docker internal DNS) or `localhost` (Host machine)
* **Port:** `5432`
* **Maintenance database:** `buildmate_db`
* **Username:** `postgres`

### 4.2 Mandatory Query Plan Verification in pgAdmin 4
Every search query or analytics query must be verified in pgAdmin 4's **Query Tool** using `EXPLAIN (ANALYZE, BUFFERS)` before merging:

    EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
    SELECT
        l.id,
        l.title,
        l.grade_or_specification,
        l.vehicle_type,
        l.load_capacity_quantity,
        l.total_load_price_paise,
        s.public_display_code,
        s.yard_locality,
        s.average_rating
    FROM material_listings l
    INNER JOIN seller_profiles s ON s.id = l.seller_profile_id
    WHERE l.category_id = '018f3a9c-0000-7000-8000-000000000001'
      AND l.status = 'ACTIVE'
      AND l.is_deleted = false
      AND s.verification_status = 'APPROVED'
      AND l.serviceable_pincodes @> ARRAY['440015']::text[]
    ORDER BY l.total_load_price_paise ASC
    LIMIT 20 OFFSET 0;

* **Acceptance Gate:** The pgAdmin 4 visual **Explain** tab must confirm an **Index Scan** on `ix_material_listings_serviceable_pincodes_gin` or `ix_material_listings_category_status_price` with execution time $< 15\text{ ms}$. Sequential Scans (`Seq Scan`) on `material_listings` or `orders` are rejected in code review.

### 4.3 Database Role Separation in pgAdmin 4
Configure two distinct PostgreSQL roles under **Login/Group Roles** in pgAdmin 4 for staging and production:
1. `buildmate_migrator`: Allowed to execute DDL (`CREATE`, `ALTER`, `INDEX`) during CI/CD migration deployment.
2. `buildmate_app_runtime`: Used by the running ASP.NET Core API; restricted strictly to `SELECT, INSERT, UPDATE, DELETE` on application tables, and `SELECT, INSERT` only on `audit_logs` (preventing any modification or deletion of audit history).