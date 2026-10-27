# Feature Specification 03 — Seller Onboarding and Verification

**Document ID:** BM-FEAT-03  
**Version:** 1.0  
**Status:** Implementation-ready specification, with verification-policy decisions pending  
**Priority:** P0 — MVP  
**Dependencies:** Feature 01 — Authentication and Sessions

---

## 1. Purpose

Allow a user to apply as a BUILD MATE seller, submit the information and evidence required by the approved onboarding policy, track the application status and, once approved, manage eligible marketplace offers.

A seller is accountable for the complete bundled offer: material plus delivery. The platform must not create a separate truck-owner role or independent truck-booking flow as part of this feature.

Seller verification is a platform eligibility process. It must not be represented as a government certification, guaranteed material quality, or proof of lawful sourcing unless the specific claim is supported by evidence and policy.

## 2. Outcomes

- Users can submit a seller application.
- Sellers can see their application and verification status.
- Required documents can be uploaded and stored privately.
- Authorized reviewers can approve, reject, suspend or request updated information according to the approved workflow.
- Only eligible sellers can publish orderable listings.
- Verification decisions and sensitive document access are traceable.
- Public seller summaries expose only approved display information.

## 3. Scope

### Included
- Seller profile/application.
- Seller status and verification status.
- Private document upload.
- Admin verification/review queue.
- Review decisions and reason codes.
- Seller activation/suspension controls.
- Audit events.
- Seller eligibility checks in listing publication.
- User-facing verification status and next-step guidance.

### Excluded
- Automatic legal identity verification unless a provider and process are approved.
- Public display of identity documents or legal contact information.
- Automated credit checks.
- Seller financing, lending or settlement services.
- Full material-origin compliance automation unless separately specified.
- Public claims of government certification based only on internal platform review.

## 4. Status model

Keep account, verification and seller operational status separate.

### 4.1 Seller verification status
Recommended values:
- `NotSubmitted`
- `PendingReview`
- `Approved`
- `Rejected`
- `Suspended`
- `Expired`

### 4.2 Seller operational status
Recommended values:
- `Active`
- `Paused`
- `Suspended`
- `Closed`

### 4.3 Listing/moderation status
Use the listing statuses specified in feature 04. Seller approval does not automatically approve every listing; moderation and listing eligibility remain separate.

### 4.4 Status-change policy
- Application submission moves verification to `PendingReview` after required inputs are present.
- Only an authorized reviewer may approve or reject an application.
- Re-submission rules for rejected applications must be configured and documented.
- Suspension immediately removes the seller's eligibility to publish/orderably offer loads according to policy.
- Expiry rules must use a documented reason/renewal process; do not invent a periodic expiry interval.
- All privileged changes record actor, timestamp, decision and reason.

## 5. User stories

### BM-SELLER-01 — Start an application
As a user with an authenticated account, I want to apply as a seller so I can offer material loads through BUILD MATE.

### BM-SELLER-02 — Provide seller information
As an applicant, I want to enter the business/display details and service area needed for review.

### BM-SELLER-03 — Upload evidence
As an applicant, I want to upload the evidence required by the approved onboarding policy.

### BM-SELLER-04 — Track review progress
As an applicant, I want to understand whether my application is incomplete, pending, approved, rejected or suspended and what action is needed.

### BM-SELLER-05 — Review an application
As an authorized reviewer, I want to inspect a seller application and supporting evidence so I can make a documented decision.

### BM-SELLER-06 — Restrict ineligible sellers
As a platform operator, I want a seller without the required approval to be prevented from publishing orderable listings.

## 6. Seller profile fields

Recommended profile fields:
- Seller profile UUID.
- Linked user UUID.
- Public display name.
- Legal business name, if required by the approved policy.
- Business type.
- Description.
- Service-area summary.
- Verification status.
- Seller operational status.
- Created/updated timestamps.

Do not assume every seller is an incorporated company. The supported applicant types and evidence requirements must be approved before validation rules are finalized.

Public seller DTOs should use an allowlist of display fields. The full internal seller profile must never be serialized directly to a public response.

## 7. Verification document handling

Recommended conceptual document fields:
- Document ID.
- Seller ID.
- Document type.
- Private storage key.
- Original filename, if operationally necessary.
- Content type.
- File size.
- Verification state.
- Reviewing user and review timestamp.
- Safe reason code.
- Created timestamp.

### File controls
- Store documents in private object storage.
- Generate storage keys server-side.
- Enforce request/file size limits.
- Validate allowed file types and inspect actual content where feasible.
- Reject unsupported active content.
- Do not use the user-supplied filename as a storage path.
- Do not expose storage keys or permanent document URLs publicly.
- Require authorization before issuing a temporary download URL.
- Redact document URLs and private content from logs.
- Apply a documented retention/deletion policy.

The allowed document types, sizes, required evidence and accepted formats must come from the approved onboarding policy. Do not invent legal requirements or request sensitive documents that have no defined operational purpose.

## 8. Application workflow

1. User signs in.
2. User opens the seller application.
3. System checks account eligibility and whether an application already exists.
4. User enters required seller/profile information.
5. User supplies required evidence using protected upload endpoints.
6. Backend validates completeness and creates/submits the application.
7. Verification status becomes `PendingReview`.
8. Authorized reviewer inspects the application and documents.
9. Reviewer makes a decision with an allowed reason code.
10. Application records decision, actor and timestamp.
11. Seller sees the updated status and any allowed next actions.
12. Listing publication remains blocked until all required eligibility conditions are satisfied.

A browser redirect or successful file upload is not proof that the entire application was submitted. Display the authoritative backend state.

## 9. Proposed API contract

Expected route family:
- `GET /api/v1/sellers/me`
- `POST /api/v1/sellers/applications`
- `PATCH /api/v1/sellers/me`
- `GET /api/v1/sellers/me/verification`
- `POST /api/v1/sellers/me/verification/documents`
- `DELETE /api/v1/sellers/me/verification/documents/{documentId}` — only if permitted by policy.
- `GET /api/v1/admin/seller-verifications`
- `GET /api/v1/admin/seller-verifications/{applicationId}`
- `POST /api/v1/admin/seller-verifications/{applicationId}/approve`
- `POST /api/v1/admin/seller-verifications/{applicationId}/reject`
- `POST /api/v1/admin/seller-verifications/{applicationId}/request-information` — if this workflow is approved.
- `POST /api/v1/admin/sellers/{sellerId}/suspend`
- `POST /api/v1/admin/sellers/{sellerId}/reinstate` — when policy allows.

These are proposed routes. Use the shared API conventions and publish OpenAPI for implemented endpoints.

## 10. Authorization requirements

- The applicant can edit only their own application and permitted seller profile fields.
- A seller cannot approve their own application or change their verification status.
- Only authorized review roles can access private verification documents.
- Reviewer permissions must be explicitly defined.
- Support access to documents is denied by default unless a specific case policy grants it.
- Public users cannot download verification evidence.
- A seller cannot use direct API requests to bypass approval and publish an orderable listing.
- Suspended/ineligible sellers cannot create new orderable offers.
- Existing order obligations for a suspended seller require an explicit operational policy; do not silently delete or rewrite orders.
- All sensitive admin actions are audited.

## 11. Admin review experience

The review screen should show:
- Application reference and submission date.
- Applicant's permitted seller details.
- Current verification status.
- Required evidence checklist.
- Evidence preview/download through an authorized protected path.
- Existing review decisions and safe reason codes.
- Approve/reject/request-information actions only when allowed.
- Confirmation and reason input for high-impact decisions.

Never display a private document in a public page or send its URL to an untrusted client. Avoid keeping temporary download URLs in logs or analytics.

## 12. Review rules

- A decision requires the reviewer to have current permission.
- Approval requires the configured completeness checks.
- Rejection should use a documented reason code and an appropriate user-facing explanation.
- Internal review notes must remain private.
- Status changes must be atomic with the audit event where practical.
- Concurrent reviewers must not silently overwrite each other's decisions.
- A repeated approval/rejection request must be handled predictably and idempotently where appropriate.
- A status transition that is no longer valid should return a safe conflict response.

## 13. Errors and edge cases

Handle:
- Duplicate application.
- Incomplete required fields.
- Missing required evidence.
- Unsupported/oversized upload.
- Upload accepted but metadata/database persistence fails.
- Storage provider timeout/failure.
- Applicant attempts another user's application/document.
- Reviewer lacks permission.
- Application already decided.
- Seller suspended after an existing listing was published.
- Document no longer available or has been removed under retention policy.
- Invalid/missing reason code.
- Concurrent review decision.

Failures must be visible and must not imply that evidence or a decision was successfully stored when it was not.

## 14. Audit, privacy and retention

Audit at least:
- Application submitted.
- Verification decision.
- Evidence added/removed.
- Sensitive document accessed where required.
- Seller suspended/reinstated/closed.
- Privileged override.
- Review permission change.

Audit metadata must not contain document contents, secrets or unnecessary personal information.

Set access and retention rules with the approved privacy policy and applicable legal advice. Avoid retaining private evidence indefinitely just because storage is inexpensive.

## 15. Required tests

### Unit tests
- Seller status and eligibility policies.
- Verification status transitions.
- Required-field and evidence validation.
- Decision reason-code validation.
- Listing eligibility from seller state.

### Integration tests
- Authenticated user submits own application.
- Duplicate application is rejected/handled.
- Applicant cannot read another seller's application.
- Unauthorized user cannot upload/download verification documents.
- Unverified seller cannot publish orderable listings.
- Approved seller still requires listing moderation where configured.
- Suspended seller becomes ineligible for new offers.
- Reviewer permission is enforced.
- Every privileged decision writes an audit event.
- Concurrent review requests do not silently overwrite outcomes.
- Storage failure is handled safely.

### Browser tests
- Applicant can submit and see pending status.
- Missing evidence produces clear validation.
- Approved/rejected state is displayed accurately.
- Unauthorized users cannot see the review console.
- Admin decision requires the appropriate action and recorded reason.
- Upload progress/failure is shown clearly.

## 16. Acceptance checklist

- [ ] Seller application is linked to authenticated identity.
- [ ] Application and seller status models are separate.
- [ ] Required fields/evidence come from an approved policy.
- [ ] Documents are stored privately.
- [ ] Upload validation runs on the server.
- [ ] Document download checks authorization.
- [ ] Review actions are permissioned and audited.
- [ ] Seller eligibility is checked by listing creation/publication logic.
- [ ] Public seller information uses an explicit allowlist.
- [ ] Failures and concurrent review actions are handled.
- [ ] Unit, integration and browser tests pass.
- [ ] Retention and re-submission rules are documented.

## 17. Completion gate

This feature is complete when an applicant can safely submit an application, a qualified reviewer can make an auditable decision, and the backend reliably prevents ineligible sellers from publishing orderable offers. No unsupported legal or certification claims may be presented as verification results.
