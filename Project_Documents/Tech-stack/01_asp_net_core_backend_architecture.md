# 01. ASP.NET Core Backend Architecture (`01_backend_architecture.md`)

## 1. Architectural Pattern: Clean Architecture Modular Monolith
The BUILD MATE backend is structured as a **Clean Architecture Modular Monolith** on **ASP.NET Core 8.0 (C# 12)**. This architecture provides strict compile-time separation between domain business rules and infrastructure concerns while keeping deployment, database transactions, and debugging simple.

### Dependency Rule
Dependencies flow strictly inward toward the `BuildMate.Domain` core:

    +-------------------------------------------------------------------+
    |                          BuildMate.Api                            |
    |        (Controllers, Middleware, Filters, Program.cs)             |
    +-------------------------------------------------------------------+
                     |                                  |
                     v                                  v
    +---------------------------------+  +------------------------------+
    |     BuildMate.Infrastructure    |  |    BuildMate.Application     |
    | (EF Core, PostgreSQL, External) |->| (Services, DTOs, Validators) |
    +---------------------------------+  +------------------------------+
                                                        |
                                                        v
                                         +------------------------------+
                                         |       BuildMate.Domain       |
                                         | (Entities, State Machines,   |
                                         |  Value Objects, Exceptions)  |
                                         +------------------------------+

* **`BuildMate.Domain`** has **zero** external NuGet package dependencies.
* **`BuildMate.Application`** references only `BuildMate.Domain`.
* **`BuildMate.Infrastructure`** references `BuildMate.Application` and `BuildMate.Domain`.
* **`BuildMate.Api`** references `BuildMate.Application` and `BuildMate.Infrastructure` (for DI registration only).

---

## 2. Layer Responsibilities & Domain Modules

### 2.1 Logical Business Modules
Within each layer, code is organized by feature module folders so boundaries remain crisp:
1. **`Identity`**: Users, OTP verification challenges, refresh sessions, role assignments (`Customer`, `Seller`, `Admin`).
2. **`Customers`**: Customer profiles, saved delivery addresses, pin code preferences.
3. **`Sellers`**: Seller business profiles, KYC/GST verification documents, service pin codes, fleet capacities.
4. **`Catalog`**: Material categories (Black Stone, Sand, Bricks, Murum), seller listings, unit pricing in paise, minimum/maximum load capacities.
5. **`Orders`**: Order quotes, price snapshots, seller acceptance/rejection, delivery status state machine.
6. **`Communications`**: Order-linked in-app messaging, contact anti-bypass filtering, masked call session bridges, SMS/WhatsApp outbox notifications.
7. **`Finance`**: Payment intents, COD/UPI offline ledger entries, platform commission rules, refunds.
8. **`Moderation`**: Admin verification queues, disputes, support tickets, immutable audit logs.

### 2.2 Detailed Layer Rules
* **`BuildMate.Domain`:**
  * Contains rich domain entities with private setters (`Order`, `MaterialListing`, `SellerProfile`) that enforce invariants through domain methods (e.g., `order.AcceptBySeller(sellerId, estimatedDeliveryWindow)`).
  * Defines custom domain exceptions (`DomainRuleViolationException`, `InvalidOrderStateTransitionException`, `EntityNotFoundException`).
* **`BuildMate.Application`:**
  * Defines C# `record` Request and Response DTOs (`CreateOrderRequest`, `PublicListingDto`, `SellerOrderDetailDto`).
  * Implements application orchestration services (`OrderApplicationService`, `ListingSearchService`).
  * Houses all `FluentValidation` validators (`AbstractValidator<T>`).
  * Defines abstractions (`IApplicationDbContext`, `ISmsGatewayClient`, `IObjectStorageService`, `ICurrentUserContext`).

---

## 3. Dependency Injection (DI) Configuration

Each layer exposes a clean `IServiceCollection` extension method so `Program.cs` stays concise and readable.

### 3.1 Application Layer Registration (`BuildMate.Application/DependencyInjection.cs`)

    using System.Reflection;
    using FluentValidation;
    using Microsoft.Extensions.DependencyInjection;

    namespace BuildMate.Application;

    public static class DependencyInjection
    {
        public static IServiceCollection AddApplicationServices(this IServiceCollection services)
        {
            var assembly = Assembly.GetExecutingAssembly();

            // Register all FluentValidation validators in Application assembly
            services.AddValidatorsFromAssembly(assembly, ServiceLifetime.Scoped);

            // Register modular application services
            services.AddScoped<IAuthApplicationService, AuthApplicationService>();
            services.AddScoped<ICustomerAddressService, CustomerAddressService>();
            services.AddScoped<ISellerOnboardingService, SellerOnboardingService>();
            services.AddScoped<IMaterialListingService, MaterialListingService>();
            services.AddScoped<IOrderLifecycleService, OrderLifecycleService>();
            services.AddScoped<ICommissionCalculationService, CommissionCalculationService>();
            services.AddScoped<IAdminModerationService, AdminModerationService>();

            return services;
        }
    }

### 3.2 Service Lifetime Standards

| Component Type | DI Lifetime | Justification |
| :--- | :--- | :--- |
| `BuildMateDbContext` | `Scoped` | Bound to a single HTTP request; `DbContext` is not thread-safe. |
| Application Services | `Scoped` | Shares the request-scoped `BuildMateDbContext` unit of work. |
| `ICurrentUserContext` | `Scoped` | Extracts authenticated `UserId`, `Role`, and `CorrelationId` from `IHttpContextAccessor`. |
| `NpgsqlDataSource` | `Singleton` | Manages the physical PostgreSQL TCP connection pool across the app lifetime. |
| `BackgroundService` Workers | `Singleton` | Long-running hosted services that create explicit scopes via `IServiceScopeFactory`. |

---

## 4. ASP.NET Core Middleware Pipeline (`Program.cs`)

The HTTP middleware execution order in `BuildMate.Api/Program.cs` is strictly standardized to ensure security, observability, and consistent error handling:

    var builder = WebApplication.CreateBuilder(args);

    // 1. Structured Logging (Serilog)
    builder.Host.UseSerilog((context, services, loggerConfig) =>
        loggerConfig.ReadFrom.Configuration(context.Configuration)
                    .ReadFrom.Services(services)
                    .Enrich.FromLogContext()
                    .Enrich.WithMachineName()
                    .Enrich.WithEnvironmentName());

    // 2. Layer Registrations
    builder.Services.AddApplicationServices();
    builder.Services.AddInfrastructureServices(builder.Configuration);
    builder.Services.AddApiPresentationServices(builder.Configuration);

    var app = builder.Build();

    // 3. Ordered Middleware Pipeline
    app.UseMiddleware<CorrelationIdMiddleware>();      // 1st: Assigns/propagates X-Correlation-Id
    app.UseSerilogRequestLogging();                    // 2nd: Logs single structured HTTP summary event
    app.UseExceptionHandler();                         // 3rd: Catches unhandled exceptions -> RFC 7807 ProblemDetails

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }
    else
    {
        app.UseHsts();
    }

    app.UseHttpsRedirection();
    app.UseCors("BuildMateFrontendPolicy");            // 4th: Strict Next.js origin policy
    app.UseRateLimiter();                              // 5th: Protects OTP & public endpoints from abuse
    app.UseAuthentication();                           // 6th: Validates HttpOnly session/JWT cookie
    app.UseAuthorization();                            // 7th: Enforces RBAC & ownership policies

    app.MapHealthChecks("/health/live");
    app.MapHealthChecks("/health/ready");
    app.MapControllers();

    app.Run();

---

## 5. Structured Logging Standards & Privacy Redaction

1. **Correlation Tracking:** Every incoming HTTP request is assigned a `CorrelationId` (`X-Correlation-Id` header or generated `Guid`). This ID is pushed into Serilog's `LogContext` and returned in every response and `ProblemDetails` payload.
2. **Structured Message Templates:** Always use named placeholders rather than C# string interpolation in log calls so log aggregators can index properties:
   * **Correct:** `logger.LogInformation("Order {OrderId} transitioned to {NewStatus} by Seller {SellerId}", order.Id, order.Status, sellerId);`
   * **Prohibited:** `logger.LogInformation($"Order {order.Id} transitioned to {order.Status}");`
3. **Mandatory PII & Contact Privacy Redaction:**
   * Never log plaintext OTP codes, session tokens, passwords, bank account numbers, GST document URLs, or full customer street addresses.
   * Phone numbers in logs must be masked to the last 4 digits (`+91******4821`).

---

## 6. Controller Design & C# 12 Coding Standards

Controllers in `BuildMate.Api/Controllers/` act strictly as HTTP transport adapters:
* Use C# 12 **Primary Constructors** and mark all controllers `sealed`.
* Never inject `BuildMateDbContext` directly into a controller.
* Always accept `CancellationToken ct` and forward it to the Application service.

    namespace BuildMate.Api.Controllers.V1;

    [ApiController]
    [Route("api/v1/listings")]
    public sealed class MaterialListingsController(
        IMaterialListingService listingService) : ControllerBase
    {
        [HttpGet]
        [AllowAnonymous]
        [ProducesResponseType(typeof(ApiResponse<PagedResult<PublicMaterialListingDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> SearchListings(
            [FromQuery] SearchListingsQuery query,
            CancellationToken ct)
        {
            var result = await listingService.SearchPublicListingsAsync(query, ct);
            return Ok(ApiResponse<PagedResult<PublicMaterialListingDto>>.Success(result));
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Seller)]
        [ProducesResponseType(typeof(ApiResponse<SellerListingDetailDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateListing(
            [FromBody] CreateMaterialListingRequest request,
            CancellationToken ct)
        {
            var created = await listingService.CreateSellerListingAsync(request, ct);
            return CreatedAtAction(
                nameof(GetSellerListingById),
                new { id = created.Id },
                ApiResponse<SellerListingDetailDto>.Success(created));
        }
    }