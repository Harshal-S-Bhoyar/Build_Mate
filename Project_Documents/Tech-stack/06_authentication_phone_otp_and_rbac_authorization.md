# 06. Authentication, Phone OTP, and RBAC Authorization (`06_authentication_and_authorization.md`)

## 1. Authentication Overview & Threat Model
BUILD MATE uses **Phone Number + SMS OTP Verification** as its primary authentication mechanism, paired with **HttpOnly Cookie-Backed JWT Access Tokens** and **Stateful PostgreSQL Refresh Token Rotation**.

### Core Security Guarantees
1. **Zero Token Exposure to JavaScript:** Access and Refresh tokens are stored exclusively in `HttpOnly`, `Secure`, `SameSite=Strict` cookies (`bm_access_token` and `bm_refresh_token`), eliminating token theft via Cross-Site Scripting (XSS).
2. **Cryptographic OTP Storage:** Plaintext 6-digit OTPs are never stored in PostgreSQL or written to application logs. Only the salted `HMAC-SHA256` hash of the OTP is persisted in the `otp_challenges` table.
3. **Brute-Force & Enumeration Protection:** OTP request and verification endpoints enforce strict IP and phone-number rate limits and cap verification attempts at $3$ tries per challenge.
4. **Immediate Suspension Enforcement:** Suspended users or rejected sellers can have their active sessions revoked immediately in PostgreSQL.

---

## 2. Phone OTP Verification Workflow

### 2.1 PostgreSQL Schema for OTP Challenges & Sessions (`otp_challenges`, `user_sessions`)

    CREATE TABLE otp_challenges (
        id uuid NOT NULL,
        phone_number varchar(15) NOT NULL,
        otp_hash varchar(128) NOT NULL,
        purpose varchar(30) NOT NULL DEFAULT 'LOGIN',
        attempt_count integer NOT NULL DEFAULT 0,
        max_attempts integer NOT NULL DEFAULT 3,
        expires_at_utc timestamptz NOT NULL,
        consumed_at_utc timestamptz NULL,
        request_ip varchar(45) NOT NULL,
        created_at_utc timestamptz NOT NULL DEFAULT clock_timestamp(),
        CONSTRAINT pk_otp_challenges PRIMARY KEY (id)
    );

    CREATE INDEX ix_otp_challenges_phone_expires
    ON otp_challenges (phone_number, expires_at_utc DESC)
    WHERE consumed_at_utc IS NULL;

    CREATE TABLE user_sessions (
        id uuid NOT NULL,
        user_id uuid NOT NULL,
        refresh_token_hash varchar(128) NOT NULL,
        device_info varchar(250) NULL,
        ip_address varchar(45) NOT NULL,
        expires_at_utc timestamptz NOT NULL,
        revoked_at_utc timestamptz NULL,
        revocation_reason varchar(120) NULL,
        replaced_by_token_hash varchar(128) NULL,
        created_at_utc timestamptz NOT NULL DEFAULT clock_timestamp(),
        CONSTRAINT pk_user_sessions PRIMARY KEY (id),
        CONSTRAINT uq_user_sessions_refresh_token_hash UNIQUE (refresh_token_hash),
        CONSTRAINT fk_user_sessions_users_user_id FOREIGN KEY (user_id)
            REFERENCES users (id) ON DELETE CASCADE
    );

### 2.2 Step-by-Step OTP Lifecycle
1. **Request OTP (`POST /api/v1/auth/otp/request`):**
   * Normalize phone number to Indian E.164 format (`+91` followed by 10 digits starting with `6-9`).
   * Check cooldown: reject with `429 Too Many Requests` if an active challenge was created for the same phone number within the last $60\text{ seconds}$, or if $> 5$ challenges were requested within $1\text{ hour}$.
   * Generate a cryptographically random 6-digit code via `RandomNumberGenerator.GetInt32(100000, 1000000)`.
   * Compute `otp_hash = HMACSHA256(phone_number + ":" + otp_code, serverPepper)` and insert into `otp_challenges` with a Time-To-Live (TTL) of $5\text{ minutes}$ ($300\text{ seconds}$).
   * Enqueue an high-priority DLT-compliant SMS dispatch job.
2. **Verify OTP (`POST /api/v1/auth/otp/verify`):**
   * Retrieve the latest unconsumed, unexpired `otp_challenges` row for `phone_number` using `FOR UPDATE` row locking.
   * Increment `attempt_count`. If `attempt_count > max_attempts`, mark the challenge expired and return `400 Bad Request` (`OTP_MAX_ATTEMPTS_EXCEEDED`).
   * Compare the incoming OTP hash using constant-time comparison (`CryptographicOperations.FixedTimeEquals`).
   * Mark `consumed_at_utc = DateTimeOffset.UtcNow`.
   * Upsert the `User` record (`CUSTOMER` or `SELLER`), create a `UserSession` row in PostgreSQL, and attach the `HttpOnly` cookies to the HTTP response.

---

## 3. Cookie-Backed JWT & Refresh Token Configuration in ASP.NET Core

### 3.1 Token Lifespans & Claims
* **Access Token (`bm_access_token`):**
  * **Lifespan:** $15\text{ minutes}$.
  * **Claims:** `sub` (`User.Id`), `role` (`CUSTOMER`, `SELLER`, `ADMIN`), `seller_status` (`APPROVED`, `PENDING_REVIEW`), `jti` (Unique Token ID).
* **Refresh Token (`bm_refresh_token`):**
  * **Lifespan:** $14\text{ days}$ sliding window.
  * **Rotation & Reuse Detection:** Every call to `POST /api/v1/auth/refresh` invalidates the previous refresh token hash and issues a new token pair. If a previously revoked refresh token is presented, all active `user_sessions` for that `user_id` are immediately revoked to counter token theft.

### 3.2 Reading JWTs from `HttpOnly` Cookies (`Program.cs`)

    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = builder.Configuration["Jwt:Issuer"],
                ValidAudience = builder.Configuration["Jwt:Audience"],
                IssuerSigningKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(builder.Configuration["Jwt:SecretKey"]!)),
                ClockSkew = TimeSpan.Zero
            };

            // Extract JWT directly from the HttpOnly cookie
            options.Events = new JwtBearerEvents
            {
                OnMessageReceived = context =>
                {
                    if (context.Request.Cookies.TryGetValue("bm_access_token", out var token))
                    {
                        context.Token = token;
                    }
                    return Task.CompletedTask;
                }
            };
        });

### 3.3 Cookie Issuing Helper (`AuthCookieService.cs`)

    public static void SetAuthCookies(HttpResponse response, string accessToken, string refreshToken)
    {
        var accessCookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.Strict,
            Path = "/",
            Expires = DateTimeOffset.UtcNow.AddMinutes(15)
        };

        var refreshCookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.Strict,
            Path = "/api/v1/auth",
            Expires = DateTimeOffset.UtcNow.AddDays(14)
        };

        response.Cookies.Append("bm_access_token", accessToken, accessCookieOptions);
        response.Cookies.Append("bm_refresh_token", refreshToken, refreshCookieOptions);
    }

---

## 4. Role-Based Access Control (RBAC) & Custom Policies

### 4.1 Platform Roles & Authorization Matrix
| Policy Name | Required Role | Additional Claim / DB Check | Target Endpoints |
| :--- | :--- | :--- | :--- |
| `CustomerOnly` | `CUSTOMER` | `is_suspended == false` | Address CRUD, Order Quote, Order Checkout, Reviews |
| `SellerOnly` | `SELLER` | `is_suspended == false` | Seller Profile Onboarding, KYC Document Upload |
| `VerifiedSellerOnly` | `SELLER` | `seller_status == "APPROVED"` | Publishing Active Listings, Accepting/Dispatching Orders |
| `AdminOnly` | `ADMIN` | `is_active == true` | Seller KYC Approval, Listing Moderation, Disputes, Analytics |

### 4.2 Policy Registration in ASP.NET Core

    builder.Services.AddAuthorizationBuilder()
        .AddPolicy(AuthPolicies.CustomerOnly, policy =>
            policy.RequireAuthenticatedUser().RequireRole(AppRoles.Customer))
        .AddPolicy(AuthPolicies.SellerOnly, policy =>
            policy.RequireAuthenticatedUser().RequireRole(AppRoles.Seller))
        .AddPolicy(AuthPolicies.VerifiedSellerOnly, policy =>
            policy.RequireAuthenticatedUser()
                  .RequireRole(AppRoles.Seller)
                  .RequireClaim("seller_status", "APPROVED"))
        .AddPolicy(AuthPolicies.AdminOnly, policy =>
            policy.RequireAuthenticatedUser().RequireRole(AppRoles.Admin));

---

## 5. Resource Ownership Authorization & IDOR Prevention

Role checks alone are insufficient: a logged-in `CUSTOMER` must never be able to view or cancel another customer's order, and a `SELLER` must never be able to accept or modify another seller's order or listing.

### 5.1 Query-Level Ownership Enforcement (Mandatory Pattern)
Every Application service method that reads or mutates a user-owned resource must include the authenticated user's profile ID (`ICurrentUserContext.ProfileId`) directly in the EF Core `WHERE` clause:

    // Inside OrderLifecycleService.cs
    public async Task<SellerOrderDetailDto> AcceptOrderAsync(
        Guid orderId,
        AcceptOrderRequest request,
        CancellationToken ct)
    {
        var currentSellerProfileId = currentUser.GetRequiredSellerProfileId();

        // Ownership enforced directly in SQL query predicate
        var order = await dbContext.Orders
            .FirstOrDefaultAsync(
                o => o.Id == orderId && o.SellerProfileId == currentSellerProfileId,
                ct)
            ?? throw new ForbiddenResourceAccessException(
                $"Order '{orderId}' does not exist or does not belong to the authenticated seller.");

        order.AcceptBySeller(request.EstimatedDeliveryWindow, TimeProvider.System.GetUtcNow());
        await dbContext.SaveChangesAsync(ct);

        return OrderMapper.ToSellerDetailDto(order);
    }