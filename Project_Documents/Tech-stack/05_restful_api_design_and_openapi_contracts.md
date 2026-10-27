# 05. RESTful API Design & OpenAPI Contracts (`05_api_design_and_contracts.md`)

## 1. REST Routing & Versioning Conventions
All BUILD MATE backend endpoints are hosted by `BuildMate.Api` and follow strict RESTful conventions:
* **Base URL Prefix:** `/api/v1`
* **Resource Naming:** Plural, lowercase `kebab-case` nouns (`/api/v1/listings`, `/api/v1/customer-addresses`, `/api/v1/seller-profiles`, `/api/v1/orders`).
* **Idempotency Support:** State-creating endpoints (`POST /api/v1/orders` and `POST /api/v1/payments/offline-record`) require an `Idempotency-Key` HTTP header (UUID) or request body field to prevent duplicate order placement when mobile clients retry over flaky networks.

---

## 2. Core Endpoint Inventory by Module

### 2.1 Authentication & Sessions (`/api/v1/auth`)
| Method | Route | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/otp/request` | `Anonymous` (Rate-Limited) | Issues a 6-digit SMS OTP challenge for a normalized Indian phone number |
| `POST` | `/api/v1/auth/otp/verify` | `Anonymous` (Rate-Limited) | Verifies OTP, creates/updates user session, sets `HttpOnly` auth cookies |
| `POST` | `/api/v1/auth/refresh` | `Cookie` | Rotates refresh token and issues a fresh access token cookie |
| `POST` | `/api/v1/auth/logout` | `Authenticated` | Revokes session in PostgreSQL and clears `HttpOnly` cookies |
| `GET` | `/api/v1/auth/me` | `Authenticated` | Returns current authenticated user ID, role, and profile summary |

### 2.2 Public Material Catalog & Search (`/api/v1/categories`, `/api/v1/listings`)
| Method | Route | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/categories` | `Anonymous` | Lists active construction material categories (Black Stone, Sand, Bricks, Murum) |
| `GET` | `/api/v1/listings` | `Anonymous` | Searches active, approved listings filtered by `pincode`, `categoryId`, `vehicleType`, and `sortBy` |
| `GET` | `/api/v1/listings/{id:guid}` | `Anonymous` | Returns public listing detail with contact-redacted seller summary |

### 2.3 Seller Onboarding & Listing Management (`/api/v1/seller`)
| Method | Route | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/seller/profile` | `Role: SELLER` | Retrieves seller's own profile and KYC verification status |
| `PUT` | `/api/v1/seller/profile` | `Role: SELLER` | Submits/updates business details, yard locality, and serviceable pincodes |
| `POST` | `/api/v1/seller/verification-documents` | `Role: SELLER` | Uploads private KYC/GST/Vehicle RC document metadata |
| `POST` | `/api/v1/seller/listings` | `Role: SELLER` | Creates a new material + vehicle delivery load listing |
| `PUT` | `/api/v1/seller/listings/{id:guid}` | `Role: SELLER` (Owner) | Updates pricing (in paise), capacity, or serviceable pincodes |

### 2.4 Orders, Lifecycle & Privacy Communications (`/api/v1/orders`)
| Method | Route | Access | Purpose |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/orders/quote` | `Role: CUSTOMER` | Calculates exact load subtotal, delivery fee, and platform fee snapshot |
| `POST` | `/api/v1/orders` | `Role: CUSTOMER` | Places a single-seller material order with `Idempotency-Key` |
| `GET` | `/api/v1/orders/{id:guid}` | `Role: CUSTOMER, SELLER, ADMIN` | Returns role-appropriate order view (redacts address until seller accepts) |
| `POST` | `/api/v1/orders/{id:guid}/accept` | `Role: SELLER` (Owner) | Transitions order from `PENDING_SELLER_RESPONSE` to `ACCEPTED` |
| `POST` | `/api/v1/orders/{id:guid}/reject` | `Role: SELLER` (Owner) | Transitions order to `REJECTED_BY_SELLER` with mandatory reason |
| `POST` | `/api/v1/orders/{id:guid}/dispatch` | `Role: SELLER` (Owner) | Transitions order to `DISPATCHED` with vehicle registration number |
| `POST` | `/api/v1/orders/{id:guid}/deliver` | `Role: SELLER` (Owner) | Transitions order to `DELIVERED` with delivery proof/OTP confirmation |
| `POST` | `/api/v1/orders/{id:guid}/messages` | `Role: CUSTOMER, SELLER` | Sends an order-linked message (filtered for phone/URL anti-bypass) |
| `POST` | `/api/v1/orders/{id:guid}/masked-call` | `Role: CUSTOMER, SELLER` | Initiates a cloud telephony masked call bridge between buyer and seller |

---

## 3. Standard JSON Response Envelopes

### 3.1 Success Response Wrapper (`ApiResponse<T>`)
All successful `200 OK` and `201 Created` responses return a consistent JSON envelope:

    namespace BuildMate.Application.Common.Models;

    public sealed record ApiResponse<T>(
        bool IsSuccess,
        T Data,
        ApiMeta Meta)
    {
        public static ApiResponse<T> Success(T data, string? correlationId = null) =>
            new(true, data, new ApiMeta(DateTimeOffset.UtcNow, correlationId));
    }

    public sealed record ApiMeta(
        DateTimeOffset TimestampUtc,
        string? CorrelationId);

### Example `200 OK` Public Listing Search JSON Payload

    {
      "isSuccess": true,
      "data": {
        "items": [
          {
            "id": "018f3a9c-9120-7b12-a401-445566778899",
            "title": "20mm Crushed Black Stone Aggregate (Gitti)",
            "categoryName": "Black Stone",
            "gradeOrSpecification": "20mm ISI Grade",
            "vehicleType": "TIPPER_6_WHEEL_3_BRASS",
            "loadCapacityQuantity": 3.0,
            "pricingUnit": "BRASS",
            "baseMaterialPricePaise": 1050000,
            "bundledDeliveryChargePaise": 250000,
            "totalLoadPricePaise": 1300000,
            "leadTimeHours": 24,
            "sellerSummary": {
              "publicDisplayCode": "SL-8821",
              "yardLocality": "MIDC Hingna",
              "averageRating": 4.75,
              "completedOrdersCount": 64
            }
          }
        ],
        "pageNumber": 1,
        "pageSize": 20,
        "totalCount": 1,
        "totalPages": 1,
        "hasPreviousPage": false,
        "hasNextPage": false
      },
      "meta": {
        "timestampUtc": "2026-10-26T13:10:00Z",
        "correlationId": "00-98a1b2c3d4e5f60718293a4b5c6d7e8f-1122334455667788-01"
      }
    }

---

## 4. Standardized Error Contract (RFC 7807 `ProblemDetails`)

All `4xx` and `5xx` responses conform to RFC 7807 `application/problem+json` enriched with `errorCode`, `correlationId`, and field-level `errors`:

    {
      "type": "https://buildmate.in/errors/validation-error",
      "title": "One or more validation errors occurred.",
      "status": 400,
      "detail": "Please correct the highlighted fields and try again.",
      "instance": "/api/v1/orders/018f3a9c-1111-7222-8333-444455556666/messages",
      "errorCode": "ANTI_BYPASS_VIOLATION",
      "correlationId": "00-98a1b2c3d4e5f60718293a4b5c6d7e8f-1122334455667788-01",
      "errors": {
        "MessageBody": [
          "Sharing phone numbers, UPI IDs, or external links in order messages is prohibited by platform policy."
        ]
      }
    }

---

## 5. OpenAPI / Swagger Configuration (`BuildMate.Api`)

Configure Swagger in `BuildMate.Api/DependencyInjection.cs` so all enums, nullable properties, paise integer fields, and authentication schemes are documented accurately for frontend code generation:

    services.AddEndpointsApiExplorer();
    services.AddSwaggerGen(options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Title = "BUILD MATE Marketplace API",
            Version = "v1",
            Description = "Hyperlocal Construction Materials & Delivery Capacity Marketplace API"
        });

        options.SupportNonNullableReferenceTypes();
        options.UseInlineDefinitionsForEnums();

        // Document Cookie Authentication
        options.AddSecurityDefinition("CookieAuth", new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.ApiKey,
            In = ParameterLocation.Cookie,
            Name = "bm_access_token",
            Description = "HttpOnly JWT Access Token Cookie"
        });
    });