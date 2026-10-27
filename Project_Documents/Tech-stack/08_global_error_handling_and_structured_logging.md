# 08. Global Error Handling & Structured Logging (`08_error_handling_and_logging.md`)

## 1. Error Handling Philosophy
Every unhandled exception or domain rule rejection in `BuildMate.Api` is intercepted by a single centralized **`GlobalExceptionHandler` (`IExceptionHandler`)** and translated into a standardized **RFC 7807 `ProblemDetails`** JSON payload.
* Raw C# stack traces, SQL table/constraint names, and internal file paths are **never** leaked to client responses in staging or production.
* Every error response includes a `correlationId` and a machine-readable `errorCode` so frontend components and support engineers can pinpoint the exact failure.

---

## 2. Exception-to-HTTP Status & Error Code Mapping Matrix

| Domain / Infrastructure Exception | HTTP Status | `errorCode` | Log Level |
| :--- | :--- | :--- | :--- |
| `ValidationException` (FluentValidation) | `400 Bad Request` | `VALIDATION_FAILED` | `Information` |
| `AntiBypassViolationException` | `400 Bad Request` | `ANTI_BYPASS_VIOLATION` | `Warning` |
| `InvalidOrderStateTransitionException` | `409 Conflict` | `INVALID_ORDER_STATE_TRANSITION` | `Warning` |
| `UnserviceablePincodeException` | `422 Unprocessable Entity` | `PINCODE_NOT_SERVICEABLE` | `Information` |
| `UnauthorizedAccessException` | `401 Unauthorized` | `AUTHENTICATION_REQUIRED` | `Information` |
| `ForbiddenResourceAccessException` | `403 Forbidden` | `FORBIDDEN_RESOURCE_ACCESS` | `Warning` |
| `EntityNotFoundException` | `404 Not Found` | `RESOURCE_NOT_FOUND` | `Information` |
| `DbUpdateConcurrencyException` (EF Core `xmin`) | `409 Conflict` | `CONCURRENCY_CONFLICT` | `Warning` |
| `PostgresException` (SQLState `23505` Unique) | `409 Conflict` | `DUPLICATE_RESOURCE` | `Warning` |
| Unhandled `Exception` | `500 Internal Server Error` | `INTERNAL_SERVER_ERROR` | `Error` |

---

## 3. ASP.NET Core `GlobalExceptionHandler` Implementation

    using System.Diagnostics;
    using BuildMate.Domain.Exceptions;
    using FluentValidation;
    using Microsoft.AspNetCore.Diagnostics;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.EntityFrameworkCore;
    using Npgsql;

    namespace BuildMate.Api.Middleware;

    public sealed class GlobalExceptionHandler(
        ILogger<GlobalExceptionHandler> logger,
        IHostEnvironment environment) : IExceptionHandler
    {
        public async ValueTask<bool> TryHandleAsync(
            HttpContext httpContext,
            Exception exception,
            CancellationToken cancellationToken)
        {
            var correlationId = Activity.Current?.Id ?? httpContext.TraceIdentifier;

            var (statusCode, errorCode, title, detail, errors) = MapException(exception);

            if (statusCode >= 500)
            {
                logger.LogError(
                    exception,
                    "Unhandled server exception for {Method} {Path} [CorrelationId: {CorrelationId}]",
                    httpContext.Request.Method,
                    httpContext.Request.Path,
                    correlationId);
            }
            else
            {
                logger.LogWarning(
                    "Domain/Request rejection {ErrorCode} ({StatusCode}) on {Method} {Path} [CorrelationId: {CorrelationId}]: {Detail}",
                    errorCode,
                    statusCode,
                    httpContext.Request.Method,
                    httpContext.Request.Path,
                    correlationId,
                    exception.Message);
            }

            var problemDetails = new ProblemDetails
            {
                Status = statusCode,
                Title = title,
                Detail = statusCode == 500 && !environment.IsDevelopment()
                    ? "An unexpected error occurred while processing your request. Please quote the correlation ID if contacting support."
                    : detail,
                Instance = httpContext.Request.Path
            };

            problemDetails.Extensions["errorCode"] = errorCode;
            problemDetails.Extensions["correlationId"] = correlationId;
            problemDetails.Extensions["timestampUtc"] = DateTimeOffset.UtcNow;

            if (errors is not null)
            {
                problemDetails.Extensions["errors"] = errors;
            }

            httpContext.Response.StatusCode = statusCode;
            httpContext.Response.ContentType = "application/problem+json";

            await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);
            return true;
        }

        private static (int Status, string Code, string Title, string Detail, IDictionary<string, string[]>? Errors)
            MapException(Exception ex) => ex switch
        {
            ValidationException vex => (
                StatusCodes.Status400BadRequest,
                "VALIDATION_FAILED",
                "One or more validation errors occurred.",
                "Please review the field errors and try again.",
                vex.Errors
                   .GroupBy(x => x.PropertyName)
                   .ToDictionary(g => g.Key, g => g.Select(x => x.ErrorMessage).ToArray())),

            AntiBypassViolationException abex => (
                StatusCodes.Status400BadRequest,
                "ANTI_BYPASS_VIOLATION",
                "Contact privacy policy violation.",
                abex.Message,
                null),

            InvalidOrderStateTransitionException ostex => (
                StatusCodes.Status409Conflict,
                "INVALID_ORDER_STATE_TRANSITION",
                "Invalid order status transition.",
                ostex.Message,
                null),

            EntityNotFoundException nfex => (
                StatusCodes.Status404NotFound,
                "RESOURCE_NOT_FOUND",
                "Requested resource was not found.",
                nfex.Message,
                null),

            ForbiddenResourceAccessException fex => (
                StatusCodes.Status403Forbidden,
                "FORBIDDEN_RESOURCE_ACCESS",
                "Access denied.",
                fex.Message,
                null),

            DbUpdateConcurrencyException => (
                StatusCodes.Status409Conflict,
                "CONCURRENCY_CONFLICT",
                "Record was modified by another user.",
                "The record you attempted to update was modified concurrently. Please refresh and try again.",
                null),

            DbUpdateException { InnerException: PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } } => (
                StatusCodes.Status409Conflict,
                "DUPLICATE_RESOURCE",
                "Duplicate record conflict.",
                "A record with the same unique identifier or idempotency key already exists.",
                null),

            _ => (
                StatusCodes.Status500InternalServerError,
                "INTERNAL_SERVER_ERROR",
                "Internal Server Error",
                ex.Message,
                null)
        };
    }

---

## 4. Structured Logging & Sensitive Data Redaction (Serilog)

### 4.1 Production `appsettings.json` Serilog Configuration

    {
      "Serilog": {
        "Using": [ "Serilog.Sinks.Console" ],
        "MinimumLevel": {
          "Default": "Information",
          "Override": {
            "Microsoft.AspNetCore": "Warning",
            "Microsoft.EntityFrameworkCore.Database.Command": "Warning",
            "System.Net.Http.HttpClient": "Warning"
          }
        },
        "WriteTo": [
          {
            "Name": "Console",
            "Args": {
              "formatter": "Serilog.Formatting.Compact.RenderedCompactJsonFormatter, Serilog.Formatting.Compact"
            }
          }
        ]
      }
    }

### 4.2 Custom PII Redaction Policy (`PiiRedactingDestructuringPolicy.cs`)
To enforce BUILD MATE's strict contact privacy and security requirements, any DTO logged via Serilog automatically masks sensitive properties:
* **Never Logged in Plaintext:** `OtpCode`, `RefreshToken`, `AccessToken`, `GstDocumentUrl`, `PanNumber`, `AddressLine1`, `ExactYardAddressPrivate`.
* **Phone Number Masking Helper:**

      public static string MaskIndianPhoneNumber(string? phone)
      {
          if (string.IsNullOrWhiteSpace(phone) || phone.Length < 6)
              return "***REDACTED***";

          return $"{phone[..3]}******{phone[^4..]}"; // e.g., "+91******4321"
      }

---

## 5. Next.js Frontend Error Handling & Form Error Mapping

When a mutation fails with an `ApiClientError` (`400 Bad Request` containing `problem.errors`), bind the server validation messages directly onto the `react-hook-form` instance:

    // src/lib/form-error-mapper.ts
    import type { FieldValues, Path, UseFormSetError } from 'react-hook-form';
    import { ApiClientError } from './api-client';

    export function applyServerValidationErrors<TForm extends FieldValues>(
      error: unknown,
      setError: UseFormSetError<TForm>
    ): string | null {
      if (!(error instanceof ApiClientError)) {
        return 'A network error occurred. Please check your connection and try again.';
      }

      const fieldErrors = error.problem.errors;
      if (fieldErrors) {
        for (const [field, messages] of Object.entries(fieldErrors)) {
          const camelField = (field.charAt(0).toLowerCase() + field.slice(1)) as Path<TForm>;
          if (messages && messages.length > 0) {
            setError(camelField, { type: 'server', message: messages[0] });
          }
        }
      }

      return error.problem.detail || error.problem.title;
    }