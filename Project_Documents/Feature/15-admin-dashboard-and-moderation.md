# Feature Specification 15 — Admin Dashboard and Moderation

**Document ID:** BM-FEAT-15  
**Version:** 1.0  
**Status:** Proposed operational specification  
**Priority:** P0 for minimum operational controls; advanced reporting later  
**Dependencies:** Authentication, seller onboarding, listings, orders, support and audit logging

---

## 1. Purpose

Provide authorized BUILD MATE operators with a secure interface for managing seller verification, listing moderation, order exceptions, complaints, notification failures and essential marketplace operations.

The admin dashboard is an operational control surface, not an unrestricted database browser. Access should be task-specific, private information should be minimized, and high-impact actions must be permissioned and audited.

## 2. Outcomes

- Authorized admins can review seller applications and make documented decisions.
- Authorized moderators can approve, reject, pause or remove listings.
- Operators can inspect order state/history and help resolve exceptions.
- Support staff can manage assigned cases within their permissions.
- Integration failures and notification backlogs are visible.
- Sensitive actions record actor, time, target and reason.
- Reports use real persisted data and clearly documented definitions.
- The dashboard does not expose unnecessary private contacts or documents.

## 3. Scope

### P0 — Minimum operational dashboard
- Admin authentication/authorization.
- Seller verification queue.
- Listing moderation queue.
- Listing and seller eligibility controls.
- Order search by safe reference and status.
- Order history view.
- Support/dispute queue.
- Basic notification/provider failure status.
- Audit events for sensitive actions.
- Pagination, filters and safe error handling.

### Later phases
- Financial/refund operations.
- Commission and fee-policy administration.
- Advanced seller performance analytics.
- Controlled exports.
- Advanced fraud investigation.
- Multi-admin approval workflows.
- Scheduled reports and operational alerts.

Do not enable financial or account operations merely because a dashboard page exists. Their feature specification and permissions must also be implemented.

## 4. Admin roles and permissions

Do not use one implicit “admin can do everything” permission.

Suggested permission groups:
- Seller-verification review.
- Listing moderation.
- Order investigation.
- Support-case assignment/resolution.
- Notification operations.
- Fee-policy management.
- Payment/refund management.
- Audit-event access.
- Sensitive-data export.
- Account/role administration.
- Security configuration.

Example role strategy:
- `Admin`: standard approved operational functions.
- `Support`: assigned support cases and permitted order details.
- `Moderator`: seller/listing review actions specifically authorized.
- `FinanceAdmin`: payment/refund/fee operations when enabled.
- `SecurityAdmin`: sensitive access/role/security controls where needed.

Final roles and their exact permissions must be defined in code/configuration and reviewed. The values above are candidate roles, not a claim that they already exist.

## 5. Access-control rules

- All admin routes require authentication and a specific authorization policy.
- UI route protection is only a convenience; API permission checks remain authoritative.
- A support role does not automatically grant fee/refund/role-management permissions.
- A moderator does not automatically receive full payment information.
- Sensitive exports require separate authorization and audit.
- Private-document access is checked for each request.
- Any privileged decision records actor, target, timestamp and reason.
- Admin users cannot self-grant additional permissions through ordinary profile updates.
- Automated coding agents do not gain production admin authority from their project instructions.

Test every admin route directly through the API, not just through the visible dashboard.

## 6. Dashboard overview

The overview should provide operational summaries based on actual records, including:
- Pending seller verifications.
- Listings awaiting review.
- Active listings and stale-availability counts, if the freshness rule is configured.
- Orders awaiting seller response.
- Orders delayed or in an exception state, according to defined rules.
- Open support cases.
- Notification outbox backlog and failed events.
- Payment/refund/reconciliation exceptions only when financial integration is enabled.

Each metric needs:
- A clear label.
- A documented definition.
- A time window or current-state scope.
- A navigation path to the underlying authorized queue.
- An explicit empty/error state.

Do not invent statistics or derive “active sellers” from arbitrary activity such as a login unless the metric definition says so.

## 7. Seller verification queue

### Required fields
- Application reference.
- Seller display name.
- Application status.
- Submission timestamp.
- Required-evidence completeness.
- Assigned reviewer, if assignment is implemented.
- Last update and safe reason category.

### Actions
- Open application.
- Inspect permitted details and private evidence.
- Approve.
- Reject with documented reason.
- Request more information, if enabled.
- Suspend/reinstate an eligible seller under the seller policy.

### Controls
- Only authorized verification roles can read private documents or decide an application.
- Review actions validate current status and completeness.
- Concurrent decisions must not overwrite one another silently.
- A successful decision updates the authoritative seller state.
- The decision creates an audit event.
- Public seller DTOs do not reveal internal review notes/documents.

## 8. Listing moderation queue

### Required fields
- Listing reference and title.
- Seller display name.
- Material category/specification.
- Quantity/unit.
- Delivered-price/quote mode.
- Delivery inclusion.
- Submitted/updated timestamps.
- Moderation state.
- Reason for prior rejection, where permitted.

### Actions
- Inspect listing detail and eligible media.
- Approve.
- Reject with reason.
- Flag for further review.
- Pause/remove from orderable state where authorized.
- Re-evaluate seller/listing eligibility.

### Moderation rules
- Check that material and delivery are bundled.
- Check required category attributes, quantity/unit and price mode.
- Check supported service area/availability information.
- Check media is appropriate and permitted.
- Check the seller is eligible.
- Do not approve based on appearance alone when required information is missing.
- A later seller suspension must block orderability even if the listing itself still says `Active`.
- Historical orders and audit records remain preserved after listing removal.

## 9. Order operations console

The order console should allow authorized operators to:
- Search by public order reference or bounded filters.
- Inspect current state, timestamp history and relevant snapshot.
- Identify eligible delayed/unanswered orders based on configured rules.
- View relevant communication/provider event references where permitted.
- See related support/dispute cases.
- Record an authorized exception or escalation.

The console must not expose another customer's complete address book, other sellers' order data, private phone numbers or payout data without a specific permission and operational need.

### Exception handling
An admin override must:
- Require a dedicated permission.
- Check the current order state.
- Require a reason code and optional safe note.
- Use the domain order service rather than directly editing a status field.
- Append status history and audit records.
- Prevent duplicate effects under retries.
- Clearly communicate the actual result.

Never provide a generic direct database-edit action for order state.

## 10. Support and disputes console

Support staff should see:
- Public ticket reference.
- Category/priority/status.
- Creator and permitted participant summary.
- Assigned agent.
- Related order reference.
- Last activity.
- Required next action.

Case actions:
- Assign/reassign within permission scope.
- Change permitted priority/status.
- Request information.
- Reply through the approved support channel.
- Record resolution code and outcome.
- Escalate where appropriate.

Internal notes must remain separate from external messages. Refunds, account suspensions and order overrides use their own permissions and dedicated workflows, even if initiated during support resolution.

## 11. Notification and provider-health console

Where the outbox/provider features are implemented, show:
- Pending backlog and oldest pending item.
- Failed/dead-lettered count.
- Error categories and safe provider references.
- Attempt counts and next retry time.
- Provider enabled/disabled/configuration state.
- A bounded retry/requeue action for authorized operators.
- Relevant correlation IDs.

Controls:
- Do not retry events blindly if the send/payment outcome is uncertain.
- Respect idempotency behavior.
- Do not display full phone numbers, credentials, OTPs or sensitive message bodies by default.
- A requeue operation must be audited and visible in history.
- Provider failures do not automatically make the associated order fail.

## 12. Financial admin controls

When feature 11/12 is enabled, financial administration must be separated and more tightly permissioned.

Potential capabilities:
- Inspect payment/refund status and provider references.
- Investigate reconciliation exceptions.
- Draft/approve fee policies.
- Request/approve/execute refunds under the approved policy.
- Record adjustments with reason and audit.
- Generate restricted financial reports.

Do not let a general admin:
- Edit a payment amount to force a success.
- Mark a failed payment as successful.
- Change a historic commission silently.
- Create an unsupported refund.
- Modify provider webhook history.
- Export broad private financial data without permission.

Financial state must be updated through application/domain services that enforce idempotency, consistency and audit.

## 13. Audit console

Audit events should be searchable by authorized staff using:
- Time window.
- Actor ID.
- Action.
- Entity type/reference.
- Correlation ID.
- Outcome/severity where recorded.

Audit records should be append-only for ordinary application roles. Any sensitive export must be permissioned and itself audited.

Do not expose raw credential material, private message bodies or unnecessary personal information in audit search results. A forensic evidence process should be separately defined for security incidents.

## 14. Data export controls

Export features are not required for a basic MVP unless operations specifically needs them.

If implemented:
- Define export purposes and allowed fields.
- Require explicit permissions.
- Apply row/field-level filtering.
- Avoid exporting secrets and unnecessary PII.
- Record actor, filter criteria, reason and timestamp.
- Protect generated files and time-limited download links.
- Apply retention/expiry.
- Prevent arbitrary unbounded exports.
- Do not allow exports to bypass the permissions of the source API.

## 15. API contract

Use the route families in `API.md`:
- `/api/v1/admin/sellers`
- `/api/v1/admin/seller-verifications`
- `/api/v1/admin/listings`
- `/api/v1/admin/orders`
- `/api/v1/admin/support/tickets`
- `/api/v1/admin/notifications`
- `/api/v1/admin/fees` — only when enabled.
- `/api/v1/admin/reports`
- `/api/v1/admin/audit-events`

Implement focused operation endpoints for approval, rejection, pause, assignment, resolution and financial actions. Avoid generic unrestricted `PATCH` endpoints that permit arbitrary status/permission changes.

All endpoints need validation, authorization, safe DTOs, bounded pagination and appropriate audit behavior.

## 16. UI and accessibility

- Use task-oriented queues rather than overwhelming dashboards with decorative charts.
- Clearly label current status and available actions.
- Include search, filters and stable pagination.
- Show stale/loading/error/empty states.
- Confirm high-impact actions.
- Require reason codes for defined sensitive actions.
- Make tables keyboard-usable and responsive.
- Do not rely on color alone for statuses.
- Provide accessible labels, focus order and dialog focus behavior.
- Use masked data in list views.
- Prevent double-submission and show authoritative server results.

## 17. Error and edge cases

Handle:
- Unauthorized/admin session expired.
- Reviewer lacks action permission.
- Application/listing/order already changed by another user.
- Concurrent moderation decisions.
- Evidence upload/view failure.
- Database/provider outage.
- Unknown notification outcome.
- Attempt to override a terminal order.
- Invalid/missing reason code.
- Disabled financial integration.
- Export exceeds allowed scope/size.
- Search criteria are invalid or excessive.

Use safe, actionable messages. Do not suppress failures or show success before the server confirms the action.

## 18. Required tests

### Authorization tests
- Customer cannot access admin APIs.
- Seller cannot access admin moderation.
- Support cannot execute financial actions without explicit permission.
- Moderator cannot access restricted payment/customer fields unless permitted.
- Admin without the required role cannot view private evidence/export.
- Direct API requests cannot bypass the UI restrictions.

### Workflow tests
- Authorized admin approves a complete seller application.
- Incomplete/unauthorized application approval is rejected.
- Listing moderation updates orderability.
- Seller suspension prevents new orderable offers.
- Order exception creates status history and audit.
- Notification retry is bounded and idempotent.
- Financial action uses its own permission and domain service.
- Concurrent decisions are handled safely.
- All privileged changes use the approved audit path.

### Browser tests
- Admin sees relevant queues and current status.
- Unauthorized user receives access denial.
- Approval/rejection requires the correct information.
- High-impact actions require confirmation.
- Error states are shown honestly.
- Responsive tables/actions remain accessible.

## 19. Security and operational monitoring

Monitor:
- Repeated admin authorization denials.
- Sensitive-data access patterns.
- Verification/listing review backlog.
- Unusual order overrides.
- Refund/fee adjustment activity where applicable.
- Notification backlog.
- Failed uploads and document-access errors.
- High-volume exports.
- Audit write failures.

If an audit event is required for a high-impact action and the audit write cannot be completed, define a fail-safe policy; do not silently execute the action without the required traceability.

## 20. Acceptance checklist

- [ ] Admin capabilities are divided into explicit permissions.
- [ ] Seller verification queue is implemented.
- [ ] Listing moderation and orderability are connected.
- [ ] Order history/exception actions use the domain service.
- [ ] Support access is case-scoped.
- [ ] Provider failures are visible and safely retryable.
- [ ] Financial controls are disabled until their own policy/implementation is approved.
- [ ] Sensitive actions are audited.
- [ ] Export controls are absent or permissioned/audited.
- [ ] Direct API authorization tests pass.
- [ ] Responsive/accessibility tests pass.

## 21. Completion gate

The minimum admin feature is complete when authorized staff can verify sellers, moderate listings, inspect operational order history and handle support exceptions without bypassing backend rules or exposing unnecessary private information.

Advanced financial control, broad exports and production security administration require separate implementation and release approval.
