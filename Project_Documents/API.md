# BUILD MATE — REST API Specification

**Document ID:** BM-API-001  
**Version:** 1.0  
**Status:** Proposed API contract  
**Last updated:** 26 October 2026  
**API style:** REST/JSON  
**Base path:** `/api/v1`  
**Backend:** ASP.NET Core Web API on .NET 10 LTS  
**Database:** PostgreSQL via Entity Framework Core/Npgsql

---

## 1. Purpose

Define a consistent, secure and testable API for the BUILD MATE marketplace. The API is the boundary between the Next.js web frontend and backend business logic.

The backend is authoritative for identity, permissions, listing eligibility, pricing, quantity validation, order creation, status transitions, payment results and private-data access. Frontend values are untrusted inputs.

The core business model is one seller offering a bundled material-and-delivery load. An MVP order references one customer, one seller and one listing.

## 2. API principles

1. Use JSON request/response bodies for normal resource operations.
2. Use `/api/v1` for the first stable version.
3. Use explicit request and response DTOs; never serialize EF Core entities directly.
4. Use backend-generated totals and state transitions.
5. Return only the data needed by the caller for that endpoint.
6. Authenticate and authorize every private request.
7. Use stable error codes, appropriate HTTP status codes and correlation IDs.
8. Use pagination and bounded query limits for list endpoints.
9. Make retry-sensitive mutations idempotent.
10. Keep provider-specific request formats behind backend adapters.
11. Never expose private contacts, verification document keys, credentials or payment secrets through public DTOs.
12. Document all production-enabled routes in OpenAPI.

## 3. Base URL and environments

Use environment configuration rather than hardcoding server URLs.

Examples:
- Local frontend: `http://localhost:3000`
- Local API: `http://localhost:5000` or the HTTPS URL assigned by the local .NET profile.
- Production: approved HTTPS API host.

The ports above are examples. Developers must use the actual ports configured in the project.

Production traffic must use HTTPS. Never commit production API credentials or secrets.

## 4. Headers and request conventions

### 4.1 Common headers
- `Content-Type: application/json` for JSON bodies.
- `Accept: application/json`.
- `X-Correlation-ID: <opaque-id>` may be accepted for trace correlation; the backend must validate or replace unreasonable values.
- `Idempotency-Key: <unique-key>` on operations that can create duplicate orders/payments or other duplicate effects.
- Anti-CSRF header required by the selected cookie-authentication configuration for state-changing browser requests.

Do not accept an arbitrary user-supplied correlation ID as proof of identity, authorization or ownership.

### 4.2 Identifiers and timestamps
- Use UUIDs for internal resource identifiers.
- Use a safe public order/ticket reference for customer-visible support interactions.
- Serialize timestamps in ISO 8601 format with timezone information.
- Persist timestamps in UTC.
- Use decimal JSON numbers for numeric amounts/quantities, with explicit currency/unit fields, or documented decimal strings where the client runtime needs to avoid precision loss.
- All price and fee calculations are performed by the backend.

### 4.3 Naming
Use one consistent JSON naming policy, preferably camelCase. Use stable enum names rather than database ordinal values.

Example:
`{ "orderStatus": "PendingSellerResponse" }`

Do not return C# exception messages, stack traces, database table names or SQL errors to clients.

## 5. Response conventions

### 5.1 Successful requests
- `200 OK`: successful read or update.
- `201 Created`: resource created; include a resource link or identifier when appropriate.
- `202 Accepted`: work accepted for asynchronous processing but not yet complete.
- `204 No Content`: successful action with no response body.

### 5.2 Client and state errors
- `400 Bad Request`: malformed request or general request validation failure.
- `401 Unauthorized`: login/session required or no longer valid.
- `403 Forbidden`: authenticated caller lacks permission.
- `404 Not Found`: resource does not exist or its existence should not be disclosed to this caller.
- `409 Conflict`: incompatible resource state, concurrency conflict or idempotency conflict.
- `410 Gone`: a deliberately expired resource that the API chooses to identify as expired.
- `413 Content Too Large`: upload exceeds allowed size.
- `415 Unsupported Media Type`: unsupported request content type.
- `422 Unprocessable Content`: optional for domain-validation failures if consistently adopted; otherwise return a documented `400`/`409` model.
- `429 Too Many Requests`: rate limit exceeded.
- `500 Internal Server Error`: unexpected server error.
- `502`/`503`/`504`: appropriate upstream or service availability failures.

Do not return `200 OK` for a rejected order, failed payment or failed external notification.

### 5.3 Error response shape

Use the standard ASP.NET Core Problem Details pattern and add safe extension fields.

Example:

```json
{
  "type": "https://api.example.invalid/problems/validation",
  "title": "The request is invalid.",
  "status": 400,
  "detail": "Review the fields and try again.",
  "instance": "/api/v1/orders",
  "errorCode": "VALIDATION_FAILED",
  "correlationId": "opaque-correlation-id",
  "errors": {
    "quantity": ["Quantity must meet the listing minimum."]
  }
}
```

The sample domain is illustrative. Replace `.invalid` links with a real documentation URI only after the error catalog is approved.

The backend must not include secret values, private documents, full payment data or internal stack traces in a public error response.

## 6. Authentication and authorization model

The browser authentication baseline is a server-managed session using Secure, HttpOnly cookies with appropriate SameSite and anti-CSRF protections, as defined in `Authentication-and-Security.md`.

- Public endpoints require no login.
- Customer endpoints are limited to the authenticated customer's own resources.
- Seller endpoints are limited to the authenticated seller's resources and eligible orders/listings.
- Admin/support routes require explicit server-side authorization policies.
- Resource ownership must be checked after identifying the resource.
- Private contact details and exact delivery addresses are returned only when the business policy authorizes that caller and purpose.
- UI visibility does not grant permission.

If a later approved decision uses bearer tokens for service-to-service calls, document that flow separately. Do not put long-lived bearer tokens in browser localStorage.

## 7. Proposed endpoint inventory

These endpoints are a target contract. Some are later-release features and must remain disabled or return a documented not-enabled response until their backing policies and providers are ready.

### 7.1 Health and service information
- `GET /api/v1/health/live` — process liveness.
- `GET /api/v1/health/ready` — readiness, with safe dependency checks.
- `GET /api/v1/meta` — optional public API capabilities/version information.

Health responses must not disclose database credentials, connection strings, secret values or sensitive internal topology.

### 7.2 Authentication and session
- `POST /api/v1/auth/register` — create a user account, subject to approved registration rules.
- `POST /api/v1/auth/login` — begin/complete the selected login flow.
- `POST /api/v1/auth/logout` — revoke/clear the current session.
- `GET /api/v1/auth/session` — return minimal current-user/session status.
- `POST /api/v1/auth/verification/send` — send a verification code, if OTP is enabled.
- `POST /api/v1/auth/verification/confirm` — verify a code, if OTP is enabled.
- `POST /api/v1/auth/password/forgot` — request password recovery, if password login is enabled.
- `POST /api/v1/auth/password/reset` — complete a valid password reset, if enabled.

The precise registration, login, recovery and OTP shapes depend on the approved identity configuration. Responses must avoid account enumeration and rate-limit abuse.

### 7.3 Customer profile
- `GET /api/v1/customers/me` — read own profile.
- `PATCH /api/v1/customers/me` — update allowed profile fields.
- `GET /api/v1/customers/me/addresses` — list own addresses.
- `POST /api/v1/customers/me/addresses` — create an address.
- `GET /api/v1/customers/me/addresses/{addressId}` — retrieve one own address.
- `PATCH /api/v1/customers/me/addresses/{addressId}` — update one own address.
- `DELETE /api/v1/customers/me/addresses/{addressId}` — delete if permitted by retention/order rules.
- `PUT /api/v1/customers/me/addresses/{addressId}/default` — atomically set default address.

Never allow a client to update another user's profile by supplying a different user ID.

### 7.4 Public catalog and search
- `GET /api/v1/material-categories` — active public categories.
- `GET /api/v1/material-categories/{code}` — category details.
- `GET /api/v1/listings` — public search/list of eligible active listings.
- `GET /api/v1/listings/{listingId}` — approved public listing detail.
- `GET /api/v1/listings/{listingId}/availability` — optional public availability summary.

Supported search parameters may include:
- `category`
- `quantity`
- `unit`
- `postalCode`
- `locality`
- `deliveryDate`
- `minPrice`
- `maxPrice`
- `sort`
- `page`
- `pageSize`

The backend must validate the allowed sort fields, numeric ranges and date semantics. Do not concatenate arbitrary SQL/order-by expressions from query parameters.

Only active, approved, eligible listings should be returned. Public listing DTOs must not include seller phone, private email, payout data, verification documents or customer data.

### 7.5 Seller onboarding and profile
- `GET /api/v1/sellers/me` — read own seller profile.
- `POST /api/v1/sellers/applications` — submit seller application.
- `PATCH /api/v1/sellers/me` — update allowed seller profile fields.
- `GET /api/v1/sellers/me/verification` — read own verification status and required actions.
- `POST /api/v1/sellers/me/verification/documents` — upload a private verification document.
- `DELETE /api/v1/sellers/me/verification/documents/{documentId}` — remove a document where policy permits.
- `GET /api/v1/sellers/me/listings` — list own listings.
- `POST /api/v1/sellers/me/listings` — create a draft/listing submission.
- `GET /api/v1/sellers/me/listings/{listingId}` — get own listing.
- `PATCH /api/v1/sellers/me/listings/{listingId}` — edit an eligible listing.
- `POST /api/v1/sellers/me/listings/{listingId}/submit` — submit for moderation.
- `POST /api/v1/sellers/me/listings/{listingId}/pause` — pause an eligible listing.
- `POST /api/v1/sellers/me/listings/{listingId}/resume` — request/resume active status when permitted.

Verify seller ownership on every resource operation. Approved seller and moderation checks remain server-side.

### 7.6 Customer orders and quote requests
- `POST /api/v1/orders` — submit a valid order request.
- `GET /api/v1/orders` — list current customer's orders.
- `GET /api/v1/orders/{orderId}` — read own order.
- `POST /api/v1/orders/{orderId}/cancel` — request cancellation under policy.
- `POST /api/v1/orders/{orderId}/confirm-delivery` — customer confirmation if enabled.
- `POST /api/v1/orders/{orderId}/disputes` — open an eligible complaint/dispute.
- `POST /api/v1/quote-requests` — submit a quote request if quote mode is enabled.
- `GET /api/v1/quote-requests/{quoteId}` — read an authorized quote.
- `POST /api/v1/quote-requests/{quoteId}/accept` — accept an active quote and create/confirm an order as specified by the approved design.

Fixed-price order and quote flows must remain distinguishable. A quote request is not a confirmed order until the required acceptance conditions are satisfied.

### 7.7 Seller order operations
- `GET /api/v1/sellers/me/orders` — list orders for the authenticated seller.
- `GET /api/v1/sellers/me/orders/{orderId}` — read an eligible seller order.
- `POST /api/v1/sellers/me/orders/{orderId}/accept` — accept a pending order.
- `POST /api/v1/sellers/me/orders/{orderId}/reject` — reject a pending order.
- `POST /api/v1/sellers/me/orders/{orderId}/start-preparation` — move to preparing when permitted.
- `POST /api/v1/sellers/me/orders/{orderId}/dispatch` — mark out for delivery when permitted.
- `POST /api/v1/sellers/me/orders/{orderId}/mark-delivered` — mark delivery complete under evidence/policy rules.

The API must enforce allowed state transitions, seller ownership and required evidence. The frontend may not supply an arbitrary new state as a generic string update.

### 7.8 Messaging and platform-mediated communication
- `GET /api/v1/threads` — list current user's authorized threads.
- `POST /api/v1/threads` — create an authorized enquiry/order thread.
- `GET /api/v1/threads/{threadId}/messages` — read permitted messages.
- `POST /api/v1/threads/{threadId}/messages` — send a message.
- `POST /api/v1/orders/{orderId}/masked-calls` — request a provider-backed masked call, only when enabled.
- `GET /api/v1/orders/{orderId}/communications` — optional limited history for authorized participants/support.

Thread membership and order participation must be checked on every request. Do not return another order's thread merely because a caller knows its UUID.

### 7.9 Notifications
- `GET /api/v1/notification-preferences` — read permitted preferences.
- `PATCH /api/v1/notification-preferences` — update permitted preferences.
- Provider callbacks/webhooks use separate provider-specific routes and verification logic; they are not ordinary user endpoints.

Example application-managed callback route:
- `POST /api/v1/webhooks/payments/{providerCode}`

The final webhook paths and authentication rules must be documented once a provider is chosen. Verify signatures/authenticity, apply replay/duplicate controls and record safe provider references.

### 7.10 Payments, fees and refunds
Potential endpoints, disabled until the financial design is approved:
- `POST /api/v1/orders/{orderId}/payments` — create/initiate an allowed payment.
- `GET /api/v1/orders/{orderId}/payments` — return permitted payment summary.
- `GET /api/v1/orders/{orderId}/receipt` — retrieve a receipt when available.
- `GET /api/v1/sellers/me/fees` — read own fee/settlement summary when the model is active.

Refunds, fee-policy administration and payout operations belong to tightly permissioned admin/application use cases, not public customer actions. Do not enable collection of platform fees until the terms, calculation, refund rules and reconciliation design are approved.

### 7.11 Reviews
- `POST /api/v1/orders/{orderId}/reviews` — submit an eligible review.
- `GET /api/v1/sellers/{sellerId}/reviews` — public approved reviews only.
- `GET /api/v1/customers/me/reviews` — own reviews, where needed.
- `PATCH /api/v1/reviews/{reviewId}` — only where the product policy permits editing/moderation.

A review must belong to an eligible completed order. One order should not produce multiple independent reviews unless a future approved product rule explicitly allows it.

### 7.12 Support
- `POST /api/v1/support/tickets` — create a ticket.
- `GET /api/v1/support/tickets` — list own tickets.
- `GET /api/v1/support/tickets/{ticketId}` — read an authorized ticket.
- `POST /api/v1/support/tickets/{ticketId}/messages` — submit a permitted support reply.
- `POST /api/v1/support/tickets/{ticketId}/close` — close where permitted.

Support access to another user's information is limited to assigned, authorized cases and documented operational need.

### 7.13 Admin
Recommended route family:
- `/api/v1/admin/sellers`
- `/api/v1/admin/seller-verifications`
- `/api/v1/admin/listings`
- `/api/v1/admin/orders`
- `/api/v1/admin/support/tickets`
- `/api/v1/admin/fees`
- `/api/v1/admin/notifications`
- `/api/v1/admin/reports`
- `/api/v1/admin/audit-events`

Use dedicated policies for each sensitive capability. Do not make all authenticated admin users automatically authorized to read or export every private field.

## 8. Example search contract

Request:

```http
GET /api/v1/listings?category=SAND&postalCode=440001&quantity=10&unit=TON&page=1&pageSize=20
Accept: application/json
```

Illustrative response:

```json
{
  "items": [
    {
      "id": "9b7b16e3-20b4-4fd1-a4b7-1e8e6df6a123",
      "title": "Construction sand — sample load",
      "categoryCode": "SAND",
      "quantityUnit": "TON",
      "minimumOrderQuantity": 10,
      "priceMode": "FixedDeliveredPrice",
      "deliveredUnitPrice": 1800.00,
      "currency": "INR",
      "deliveryIncluded": true,
      "seller": {
        "id": "7e836c49-7d61-47da-a2c5-72ef39c78510",
        "displayName": "Example Seller",
        "verificationStatus": "Approved"
      }
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalItems": 1,
  "hasNextPage": false
}
```

All identifiers, prices and seller data above are illustrative. Never use them as real production seed data. The public seller summary deliberately excludes phone, email and private verification details.

## 9. Example order submission contract

Request shape:

```json
{
  "listingId": "9b7b16e3-20b4-4fd1-a4b7-1e8e6df6a123",
  "quantity": 10,
  "quantityUnit": "TON",
  "deliveryAddressId": "7b9fcb42-1d44-4f5c-90dc-e71344c3f812",
  "requestedDeliveryAt": "2026-11-02T09:00:00+05:30",
  "customerNote": "Please coordinate the site entry through the platform."
}
```

The server must:
1. Authenticate the customer.
2. Validate the idempotency key.
3. Load the current listing and seller.
4. Validate listing/seller status, quantity, unit, area, availability and price mode.
5. Load and authorize the customer's address.
6. Calculate the price and applicable fees/taxes from approved rules.
7. Persist the order and commercial/address snapshots.
8. Persist initial status history, required audit event and notification outbox item atomically where practical.
9. Return a safe order response DTO.

The client must not submit a trusted `totalAmount`, `sellerId`, `orderStatus`, platform fee or tax amount. These are determined by the backend.

Example response:

```json
{
  "id": "1a4c5e25-44c0-49f6-978e-9cd7ca03e521",
  "publicOrderNumber": "BM-EXAMPLE-0001",
  "orderStatus": "PendingSellerResponse",
  "paymentStatus": "NotRequired",
  "currency": "INR",
  "totalAmount": 18000.00,
  "createdAtUtc": "2026-10-26T11:30:00Z"
}
```

Return `201 Created` when an order is created successfully. The actual payment/total behavior depends on the approved financial policy.

## 10. Pagination, filtering and sorting

Use a consistent query scheme:
- `page`: starts at 1.
- `pageSize`: positive and capped by server policy.
- `sort`: allowlisted value such as `price_asc`, `price_desc`, `newest` or another documented option.
- Filters: validated independently.

Reject unreasonable page sizes. Consider cursor pagination for large/high-churn histories later; do not add it without a clear need.

Never interpolate raw filter/sort strings into SQL. Use parameterized EF Core queries and allowlisted sort mappings.

## 11. Idempotency and concurrency

Use an idempotency strategy for order submission, payment initiation, webhook handling and other operations with external effects.

- Scope keys by authenticated actor and operation.
- Store a safe request hash and result reference.
- Reusing the same key for the same request returns the original outcome where policy allows.
- Reusing the same key for a different request returns a documented conflict.
- Protect order capacity and price validation inside a consistent transaction/concurrency strategy.
- Provider callbacks must be deduplicated using provider references and/or event IDs.
- Never assume disabling a frontend button prevents duplicate operations.

## 12. Upload API rules

- Set explicit maximum body/file sizes.
- Use an allowlist of file types and validate actual content, not only filename extensions or client MIME headers.
- Generate storage keys on the server; never accept arbitrary filesystem paths or object keys from the client.
- Keep verification documents in private storage.
- Serve private files only after authorization and preferably through short-lived access mechanisms.
- Use a separate policy and storage area for approved public listing photos.
- Reject executable or unsupported content.
- Add safe image processing/metadata removal where appropriate.
- Log upload outcomes without logging private document URLs or sensitive contents.

## 13. OpenAPI and API evolution

- Publish an OpenAPI document for implemented endpoints.
- Document authentication, roles, DTOs, statuses, error codes and rate limits.
- Keep the production OpenAPI surface controlled; do not expose internal-only operations indiscriminately.
- Add optional fields compatibly where possible.
- Introduce new `/api/v2` only when a breaking contract change is necessary and migration is planned.
- Update frontend types, examples, tests and this document in the same change.
- Do not claim an endpoint exists until it is implemented and covered by tests.

## 14. Rate limits and abuse controls

Apply limits appropriate to endpoint risk, with stricter controls for:
- Login and password recovery.
- OTP send/verify.
- Listing search and scraping-sensitive queries.
- Order submission.
- Messaging.
- Uploads.
- Masked-call initiation.
- Support-ticket creation.
- Payment initiation and provider callbacks.

Use server-side rate limits and monitoring. Return `429` with a safe retry hint where appropriate. Do not rely solely on IP limits; authenticated identity, phone/email and operation-specific counters may also be needed.

## 15. Logging and observability

Record:
- Correlation ID.
- Route/operation and result status.
- Duration and safe error code.
- Authenticated actor ID where appropriate.
- Order/listing reference where appropriate.
- Provider request/correlation reference when safe.

Do not log passwords, OTPs, full cookie values, access/refresh tokens, payment secrets, private verification-document URLs or unnecessary full contact/address data. Audit logs and diagnostic logs serve different purposes and must have separate access/retention policies.

## 16. API test requirements

For every implemented endpoint, test:
- Valid request and expected result.
- Invalid request.
- Unauthenticated access.
- Authenticated caller with the wrong role.
- Wrong resource owner.
- Missing/expired resource.
- Invalid status transition.
- Concurrent/retried request where relevant.
- No private-data leakage.
- External provider failure where relevant.

Use xUnit and ASP.NET Core integration tests with a controlled test database. Do not let tests accidentally call live SMS, WhatsApp, telephony, storage or payment services.

## 17. Definition of API complete

An endpoint is complete when its DTO and behavior are documented, authentication/authorization are enforced server-side, domain rules are covered by tests, sensitive values are redacted, OpenAPI is updated, integration failures are handled and the frontend consumes the contract without duplicating business logic.
