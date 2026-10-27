# 02. Entity Framework Core Data Access Standards (`02_ef_core_data_access.md`)

## 1. Overview & Data Access Philosophy
BUILD MATE uses **Entity Framework Core 8.0** with the **`Npgsql.EntityFrameworkCore.PostgreSQL`** provider to interact with PostgreSQL 16.
* **Code-First Authority:** The C# entity configurations in `BuildMate.Infrastructure/Persistence/Configurations/` are the single source of truth for schema generation.
* **Pure Domain Entities:** Domain classes in `BuildMate.Domain` remain free of EF Core attributes (`[Table]`, `[Column]`, `[Index]`). All persistence mappings are defined via the Fluent API (`IEntityTypeConfiguration<TEntity>`).
* **Automatic `snake_case` Convention:** `.UseSnakeCaseNamingConvention()` is applied globally so C# `MaterialListing.BasePricePaise` maps cleanly to PostgreSQL `material_listings.base_price_paise`.

---

## 2. `BuildMateDbContext` & `NpgsqlDataSource` Setup

### 2.1 Infrastructure Registration (`DependencyInjection.cs`)

    using BuildMate.Application.Common.Interfaces;
    using BuildMate.Infrastructure.Persistence;
    using BuildMate.Infrastructure.Persistence.Interceptors;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.Extensions.Configuration;
    using Microsoft.Extensions.DependencyInjection;
    using Npgsql;

    namespace BuildMate.Infrastructure;

    public static class DependencyInjection
    {
        public static IServiceCollection AddInfrastructureServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is not configured.");

            // Configure singleton NpgsqlDataSource for connection pooling & JSONB support
            var dataSourceBuilder = new NpgsqlDataSourceBuilder(connectionString);
            dataSourceBuilder.EnableDynamicJson();
            var dataSource = dataSourceBuilder.Build();
            services.AddSingleton(dataSource);

            services.AddScoped<AuditableEntitySaveChangesInterceptor>();

            services.AddDbContext<BuildMateDbContext>((sp, options) =>
            {
                var auditInterceptor = sp.GetRequiredService<AuditableEntitySaveChangesInterceptor>();

                options.UseNpgsql(dataSource, npgsqlOptions =>
                {
                    npgsqlOptions.MigrationsAssembly(typeof(BuildMateDbContext).Assembly.FullName);
                    npgsqlOptions.MigrationsHistoryTable("__ef_migrations_history", "public");
                    npgsqlOptions.CommandTimeout(30);
                })
                .UseSnakeCaseNamingConvention()
                .AddInterceptors(auditInterceptor);
            });

            services.AddScoped<IApplicationDbContext>(sp => sp.GetRequiredService<BuildMateDbContext>());

            return services;
        }
    }

### 2.2 `BuildMateDbContext` Implementation

    using System.Reflection;
    using BuildMate.Application.Common.Interfaces;
    using BuildMate.Domain.Entities.Catalog;
    using BuildMate.Domain.Entities.Customers;
    using BuildMate.Domain.Entities.Identity;
    using BuildMate.Domain.Entities.Moderation;
    using BuildMate.Domain.Entities.Orders;
    using BuildMate.Domain.Entities.Sellers;
    using Microsoft.EntityFrameworkCore;

    namespace BuildMate.Infrastructure.Persistence;

    public sealed class BuildMateDbContext(
        DbContextOptions<BuildMateDbContext> options) : DbContext(options), IApplicationDbContext
    {
        public DbSet<User> Users => Set<User>();
        public DbSet<CustomerProfile> CustomerProfiles => Set<CustomerProfile>();
        public DbSet<CustomerAddress> CustomerAddresses => Set<CustomerAddress>();
        public DbSet<SellerProfile> SellerProfiles => Set<SellerProfile>();
        public DbSet<SellerVerificationDocument> SellerVerificationDocuments => Set<SellerVerificationDocument>();
        public DbSet<MaterialCategory> MaterialCategories => Set<MaterialCategory>();
        public DbSet<MaterialListing> MaterialListings => Set<MaterialListing>();
        public DbSet<Order> Orders => Set<Order>();
        public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
        public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
        public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        }
    }

---

## 3. Fluent API Entity Configuration Standards

Every entity is configured in its own class implementing `IEntityTypeConfiguration<T>`. Below is the production configuration for `Order`:

    using BuildMate.Domain.Entities.Orders;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.EntityFrameworkCore.Metadata.Builders;

    namespace BuildMate.Infrastructure.Persistence.Configurations;

    public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
    {
        public void Configure(EntityTypeBuilder<Order> builder)
        {
            builder.ToTable("orders");

            builder.HasKey(o => o.Id)
                .HasName("pk_orders");

            builder.Property(o => o.OrderNumber)
                .IsRequired()
                .HasMaxLength(32);

            builder.HasIndex(o => o.OrderNumber)
                .IsUnique()
                .HasDatabaseName("uq_orders_order_number");

            // Store Enum as readable string in PostgreSQL for clarity in pgAdmin 4
            builder.Property(o => o.Status)
                .HasConversion<string>()
                .HasMaxLength(40)
                .IsRequired();

            // Financial amounts stored strictly in integer paise (bigint)
            builder.Property(o => o.MaterialSubtotalPaise).IsRequired();
            builder.Property(o => o.DeliveryChargePaise).IsRequired();
            builder.Property(o => o.PlatformFeePaise).IsRequired();
            builder.Property(o => o.TotalPayablePaise).IsRequired();

            // Snapshot of delivery address at order placement time (jsonb)
            builder.Property(o => o.DeliveryAddressSnapshotJson)
                .HasColumnType("jsonb")
                .IsRequired();

            // Optimistic concurrency via PostgreSQL xmin system column
            builder.Property(o => o.RowVersion)
                .IsRowVersion();

            // Foreign Keys & Composite Indexes for Seller & Customer dashboards
            builder.HasIndex(o => new { o.SellerId, o.Status, o.CreatedAtUtc })
                .HasDatabaseName("ix_orders_seller_id_status_created_at");

            builder.HasIndex(o => new { o.CustomerId, o.CreatedAtUtc })
                .HasDatabaseName("ix_orders_customer_id_created_at");
        }
    }

---

## 4. EF Core Migrations Management via CLI

All schema changes are tracked via EF Core migrations located in `src/backend/BuildMate.Infrastructure/Persistence/Migrations`.

### 4.1 Standard CLI Commands (Executed from Repository Root)
* **Create a New Migration:**

      dotnet ef migrations add <MigrationName> \
        --project src/backend/BuildMate.Infrastructure \
        --startup-project src/backend/BuildMate.Api \
        --output-dir Persistence/Migrations

* **Apply Pending Migrations to Local PostgreSQL:**

      dotnet ef database update \
        --project src/backend/BuildMate.Infrastructure \
        --startup-project src/backend/BuildMate.Api

* **Generate Idempotent Production SQL Script (for pgAdmin 4 Review):**

      dotnet ef migrations script --idempotent \
        --project src/backend/BuildMate.Infrastructure \
        --startup-project src/backend/BuildMate.Api \
        --output artifacts/idempotent_migration.sql

* **Revert Local Database to a Specific Migration:**

      dotnet ef database update <TargetMigrationName> \
        --project src/backend/BuildMate.Infrastructure \
        --startup-project src/backend/BuildMate.Api

---

## 5. Transaction Management & Atomic Outbox Persistence

### 5.1 Single-SaveChangesAsync Unit of Work
By default, EF Core wraps a single call to `await dbContext.SaveChangesAsync(ct)` in an implicit PostgreSQL database transaction (`BEGIN ... COMMIT`). When an order state changes, the updated `Order` row, the new `OrderStatusHistory` row, the `AuditLog` entry, and the `OutboxMessage` notification payload are all staged in the `BuildMateDbContext` change tracker and committed atomically in a single `SaveChangesAsync(ct)` call.

### 5.2 Explicit Multi-Step Transactions with Pessimistic Locking
When an operation requires locking a row prior to validation (such as preventing double-acceptance or concurrent refund processing), use an explicit `IsolationLevel.ReadCommitted` transaction combined with `FOR UPDATE`:

    await using var transaction = await dbContext.Database.BeginTransactionAsync(ct);
    try
    {
        var order = await dbContext.Orders
            .FromSqlInterpolated($"SELECT * FROM orders WHERE id = {orderId} FOR UPDATE")
            .FirstOrDefaultAsync(ct)
            ?? throw new EntityNotFoundException(nameof(Order), orderId);

        order.AcceptBySeller(currentSellerId, estimatedDeliveryAtUtc);

        dbContext.OrderStatusHistories.Add(OrderStatusHistory.Create(
            order.Id,
            OrderStatus.PendingSellerResponse,
            OrderStatus.AcceptedBySeller,
            currentSellerId));

        dbContext.OutboxMessages.Add(OutboxMessage.Create(
            new OrderAcceptedIntegrationEvent(order.Id, order.CustomerId, order.SellerId)));

        await dbContext.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
    }
    catch
    {
        await transaction.RollbackAsync(ct);
        throw;
    }

---

## 6. Concurrency Handling & Query Performance Rules

1. **Optimistic Concurrency (`DbUpdateConcurrencyException`):**
   * Every mutable aggregate root (`Order`, `MaterialListing`, `SellerProfile`) configures `.IsRowVersion()`, which binds to PostgreSQL's hidden `xmin` transaction ID column (`uint`).
   * If two requests attempt to modify the same record concurrently, EF Core sees `WHERE id = @p0 AND xmin = @p1` affect $0$ rows and throws `DbUpdateConcurrencyException`.
   * The global exception handler translates `DbUpdateConcurrencyException` into an HTTP `409 Conflict` `ProblemDetails` response instructing the client to refresh and retry.
2. **Mandatory `.AsNoTracking()` for Read Queries:**
   * All search, catalog, and dashboard queries must chain `.AsNoTracking()` and project directly to safe DTOs via `.Select(...)` so private seller fields (`PhoneNumber`, `GstNumber`, `ExactYardAddress`) are never loaded into memory on public endpoints.
3. **Avoid Cartesian Explosion:**
   * When loading an entity with multiple collection navigations, always chain `.AsSplitQuery()`.