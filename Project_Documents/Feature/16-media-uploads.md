# Feature Specification 16 — Media Uploads and Asset Management

**Document ID:** BM-FEAT-16  
**Version:** 1.0  
**Status:** Proposed implementation specification  
**Priority:** P0 for listing-image safety; private-document support required when seller verification uses uploads  
**Dependencies:** Authentication, seller onboarding, listing management, object-storage adapter and security controls

---

## 1. Purpose

Provide a secure, maintainable way to upload, validate, store, review, serve and remove media used by BUILD MATE.

The feature supports two fundamentally different classes of files:

1. **Public listing media:** Approved material/listing images that customers are allowed to view.
2. **Private documents/evidence:** Seller-verification documents and any other approved evidence that must be available only to authorized users.

These classes must not share the same public access policy. A verification document must never become public merely because the same storage service also holds listing images.

## 2. Objectives

- Allow authorized sellers to upload relevant listing images.
- Support private seller-verification evidence where required.
- Validate file size, type and content on the server.
- Generate storage keys server-side.
- Keep private documents inaccessible to unauthorized users.
- Publish listing images only after required moderation/approval.
- Handle partial failures between object storage and PostgreSQL.
- Maintain traceable media ownership and moderation state.
- Support replacement, removal, retention and cleanup.
- Prevent uploads from becoming an execution, malware or data-leak path.

## 3. Scope

### Included
- Upload authorization and ownership.
- Configurable size/type limits.
- File signature/content validation where feasible.
- Private and public storage policies.
- Listing-media metadata.
- Verification-document metadata.
- Media moderation states.
- Authorized image/document retrieval.
- Cleanup of abandoned or orphaned objects.
- Upload failure handling and audit.
- Automated tests for content, ownership and visibility.

### Excluded by default
- Public uploads unrelated to approved marketplace features.
- Executable files or arbitrary HTML hosting.
- Unlimited video uploads.
- Audio recording of masked calls.
- AI image authenticity/quality certification.
- Automatic claims that an image proves material grade or source.
- Public access to private seller/customer evidence.

## 4. Storage architecture

Implement an application-level storage interface, such as `IObjectStorage`, with provider-specific code confined to the infrastructure layer.

The system must distinguish:

### 4.1 Public listing media
- Associated with a listing and seller.
- Stored under a controlled public-media policy.
- Served only after the listing/media moderation rules allow publication.
- Referenced in public DTOs through an approved public URL or safe asset identifier.
- Removable/unpublished when the asset or listing is rejected, paused or removed, as defined by policy.

### 4.2 Private documents
- Associated with a seller application, support case or other explicitly approved private resource.
- Stored in a private bucket/container or equivalent protected area.
- Never made public by a predictable object URL.
- Retrieved only after backend authentication and authorization.
- Preferably served via an authenticated download handler or short-lived signed URL created only after access checks.
- Excluded from public DTOs, general reports and routine logs.

### 4.3 Environment separation
Use distinct configuration and credentials for local development, testing, staging and production. Do not let the development storage account expose production files or vice versa.

## 5. Supported file types

The approved file-type list must be configured per upload purpose.

A starting policy may allow common raster images such as JPEG, PNG and WebP for listing images. Verification documents may require a separately approved list such as PDF and selected image formats.

This is a proposal, not a universal requirement. Confirm actual business needs before accepting more formats.

Rules:
- Validate file extension and content type as separate signals.
- Inspect the file signature/content where feasible.
- Do not trust the browser-provided MIME type.
- Do not allow executable formats.
- Avoid serving user-supplied HTML or active SVG as public content unless a reviewed sanitization and serving strategy exists.
- Define whether animated images are allowed.
- Reject unknown formats by default.

## 6. File size and resource limits

Set explicit, configurable limits for:
- Maximum file size by purpose.
- Maximum number of files per listing/application.
- Maximum number of upload attempts within a period.
- Maximum image dimensions/pixel count where image processing is used.
- Maximum filename and metadata lengths.
- Maximum request body size and request duration.

Apply limits at the proxy/hosting layer where possible, the ASP.NET Core application layer and the storage workflow. Do not depend solely on frontend checks.

Exact limits should reflect supported use cases, provider constraints, storage cost and mobile upload performance. Record the chosen values in configuration and operational documentation.

## 7. Upload workflow

Recommended upload flow:

1. Authenticated user selects a supported file.
2. Frontend performs preliminary checks for usability.
3. API authenticates the caller and verifies resource ownership/permission.
4. API validates upload category, size and allowed content type.
5. File is streamed or staged using a bounded mechanism.
6. Backend inspects content and applies required processing.
7. Server generates an opaque storage key and writes the file to the appropriate storage area.
8. Backend stores media metadata and its relationship to the listing/application.
9. Asset enters the appropriate moderation/processing state.
10. Public media becomes available only after approval and successful processing.
11. API returns a safe asset DTO with only the fields the caller is allowed to see.

A successful upload response does not automatically mean the image is approved or public.

## 8. Ownership and authorization

- A seller can upload media only for their own listing/application.
- A seller cannot attach a file to another seller's listing or application.
- A listing image can be publicly retrieved only when publication rules allow it.
- A private verification document is accessible only to authorized reviewers and other explicitly permitted actors under policy.
- A customer can access private evidence only when explicitly associated with an authorized order/support workflow.
- Support access is case-scoped and audited where required.
- Admin access to files is subject to role-specific permissions.
- Knowing an asset UUID or storage key does not grant access.
- Deletion/replacement is allowed only for permitted ownership/status conditions.

Enforce these rules in the backend on every upload, read, replace and delete request.

## 9. Metadata model

For listing media, use the `listing_media` concept in `Database.md`, including:
- Asset ID.
- Listing ID.
- Server-generated storage key.
- Optional alt text.
- Display order.
- Moderation state.
- Created timestamp.

For seller-verification documents, use the `seller_verification_documents` concept, including:
- Document ID.
- Seller/application association.
- Document type.
- Private storage key.
- File metadata.
- Verification state.
- Review actor and timestamp where applicable.
- Safe decision reason.
- Created timestamp.

Add fields for processing state, checksum or integrity verification where justified. Do not put sensitive document contents into PostgreSQL merely because metadata already resides there.

## 10. Image processing and safe serving

If server-side image processing is used:
- Verify supported decoder behavior.
- Bound pixel count and processing resources.
- Strip location and unnecessary EXIF metadata where appropriate.
- Generate safe output formats/dimensions.
- Avoid preserving untrusted executable metadata.
- Keep the original only when a justified retention policy requires it.
- Ensure processing failures do not produce a publicly accessible invalid asset.

For public listing images:
- Set correct content type.
- Apply appropriate browser/security headers.
- Use controlled caching behavior.
- Avoid user-controlled paths.
- Use safe filenames or opaque asset identifiers.
- Do not assume a file is safe because it has an image extension.

## 11. Moderation and publication

Candidate media states:
- `Pending`
- `Processing`
- `Approved`
- `Rejected`
- `Flagged`
- `Removed`
- `Failed`

Adopt a single canonical media state model or document how it interacts with the listing moderation state.

Rules:
- Unreviewed media must not appear publicly if policy requires pre-publication moderation.
- Rejected/removed media is not served publicly.
- A listing cannot become orderable if required media or listing moderation conditions fail.
- A moderator's decision is authorized and auditable.
- Replacement media does not erase historical evidence of a previous published/rejected asset where preservation is required.
- Public display should not imply certification, legal origin, exact grade or ownership based only on an image.

## 12. Replacement, removal and cleanup

Object storage and PostgreSQL do not normally share a transaction. Design for partial success.

Examples:
- Object written but DB record creation fails.
- DB metadata is created but storage write fails.
- Media is removed from a listing while a cached public reference remains.
- Deletion request succeeds in the database but storage deletion fails.
- Upload is abandoned before metadata completion.

Use a safe workflow:
1. Record the upload/processing intention.
2. Write the object.
3. Persist validated metadata/state.
4. On partial failure, mark the operation for controlled cleanup/retry.
5. Periodically find eligible orphan objects/metadata.
6. Delete or quarantine only after confirming ownership and retention requirements.
7. Record cleanup outcomes where operationally necessary.

Do not delete historical order evidence simply because a listing is removed. Apply the approved retention rules.

## 13. API contract

Potential routes:
- `POST /api/v1/sellers/me/verification/documents`
- `DELETE /api/v1/sellers/me/verification/documents/{documentId}` — where deletion is allowed.
- `POST /api/v1/sellers/me/listings/{listingId}/media`
- `GET /api/v1/sellers/me/listings/{listingId}/media`
- `DELETE /api/v1/sellers/me/listings/{listingId}/media/{mediaId}`
- Restricted admin/moderation routes for media review.
- Protected retrieval endpoint or short-lived authorized URL for private documents.

Use a request format appropriate to the selected upload architecture, such as multipart form-data or an approved presigned-upload flow. Do not assume that presigned upload is always safer; it needs explicit authorization, short expiry, content/size enforcement and post-upload validation.

## 14. Error handling

Handle:
- Unauthenticated request.
- Wrong resource owner.
- Unsupported type.
- Invalid file signature/content.
- File too large.
- Image dimensions exceed limits.
- Storage unavailable.
- Request timeout.
- Database persistence failure after storage write.
- Moderation failure.
- Deleted/missing object.
- Expired private-download URL.
- Quota/rate limit.
- Unauthorized direct URL access.

Return safe error codes and actionable user messages without leaking storage infrastructure, private keys or raw provider exceptions.

## 15. Required tests

### Unit tests
- File type/size validation.
- Ownership policy.
- Media-state transitions.
- Publication eligibility.
- Safe filename/key generation.
- Processing outcome mapping.

### Integration tests
- Authorized seller uploads listing media.
- Seller cannot upload to another seller's listing.
- Private document is not accessible to anonymous users.
- Unauthorized seller cannot retrieve another seller's evidence.
- Unapproved listing image is not public.
- Rejected media is not served.
- Upload failure does not leave a falsely successful record.
- Cleanup does not delete retained evidence.
- Private storage key does not appear in public DTOs.
- Rate/size limits are enforced server-side.

### Browser tests
- Seller sees upload progress and failures.
- Unsupported file is rejected.
- Approved image appears in the listing where permitted.
- Rejected/removed image is not shown publicly.
- Mobile photo upload is usable.
- Authorized review/download paths work correctly.

## 16. Privacy and retention

- Define why each document type is required.
- Minimize collected personal information.
- Restrict access and preserve an access audit where required.
- Define retention/deletion rules before production.
- Avoid exposing storage keys and signed URLs in logs/analytics.
- Make sure temporary URLs cannot be reused beyond their intended scope/lifetime.
- Keep private documents outside public CDN paths.
- Apply legal-preservation requirements where applicable.
- Do not store seller documents indefinitely without a documented purpose.

## 17. Operational monitoring

Monitor:
- Upload successes/failures.
- Average upload size/duration.
- Rejected file types.
- Processing failures.
- Orphan objects.
- Storage cost/quota.
- Private-access denials.
- Moderation backlog.
- Cleanup retry backlog.

Do not log full document contents or unnecessarily expose private filenames/URLs in general-purpose metrics.

## 18. Acceptance checklist

- [ ] Public and private storage policies are distinct.
- [ ] Server-side upload authorization exists.
- [ ] Type/content and size limits are enforced.
- [ ] Storage keys are generated by the server.
- [ ] Public media requires appropriate approval.
- [ ] Private documents require authorization on every retrieval.
- [ ] Partial storage/database failures are handled.
- [ ] Cleanup respects retention and historical order evidence.
- [ ] Media state and moderation behavior are consistent.
- [ ] Logs omit private keys and unnecessary personal data.
- [ ] Unit, integration and browser tests pass.
- [ ] Production storage credentials and access policies are reviewed.

## 19. Completion gate

Media uploads are complete when files are validated and stored according to their privacy class, assets are served only to authorized viewers, partial failures are recoverable, and the feature cannot turn an uploaded file into a public data leak or unsafe executable resource.
