# Feature Specification 14 — Support, Complaints and Disputes

**Document ID:** BM-FEAT-14  
**Version:** 1.0  
**Status:** Proposed operational specification; policy decisions pending  
**Priority:** P1 — Required before broad public launch  
**Dependencies:** Features 01, 06–08 and admin dashboard foundations

---

## 1. Purpose

Provide a controlled way for customers and sellers to ask for help, report problems, raise order-related complaints and track resolution.

Because BUILD MATE coordinates third-party material and delivery offers, support must handle issues such as seller non-response, cancellation requests, quantity/specification concerns, delivery delay, incomplete delivery, suspected fraud, privacy complaints and payment/refund questions where those integrations are enabled.

A support ticket records an issue; it does not automatically establish that the customer or seller is correct. Dispute outcomes must follow a published policy and be traceable.

## 2. Outcomes

- Users can open a ticket connected to an order or a general platform issue.
- Customers and sellers can track their own tickets.
- Authorized support agents can triage, assign, communicate and resolve cases.
- Access to order data and evidence is restricted to the case's permitted scope.
- Order/payment/communication status remains separate from support-ticket status.
- Dispute decisions and administrative exceptions are auditable.
- Users receive honest updates and clear next steps.
- Critical safety, fraud and privacy complaints can be escalated through an approved process.

## 3. Scope

### Included
- Support-ticket creation.
- Order-linked and general platform tickets.
- Ticket categories and priorities.
- Ticket status and assignment.
- Customer/seller replies through an authorized interface.
- Evidence links/uploads where enabled by the media policy.
- Dispute linkage and resolution records.
- Admin/support case console.
- Notifications for meaningful case updates.
- Permission/audit controls.
- Required operational metrics and automated tests.

### Excluded until approved
- Automatic legal decisions or binding arbitration.
- Automated customer compensation or seller penalties.
- Unapproved refunds or account suspensions.
- Public disclosure of complaint details.
- Default call recording/transcription.
- Unlimited private-document export.
- Customer-to-driver dispute workflows outside the seller's bundled delivery responsibility.

## 4. Ticket categories

Initial categories may include:
- `ORDER_STATUS`
- `SELLER_NOT_RESPONDING`
- `CANCELLATION`
- `DELIVERY_DELAY`
- `QUANTITY_OR_SPECIFICATION`
- `MATERIAL_QUALITY`
- `DELIVERY_NOT_RECEIVED`
- `PAYMENT_OR_REFUND` — only when applicable.
- `PRIVACY_OR_CONTACT`
- `ACCOUNT_ACCESS`
- `SELLER_ONBOARDING`
- `LISTING_REPORT`
- `OTHER`

Use controlled reason codes rather than relying entirely on free text. The final list should reflect the pilot's actual operating process and must be maintained consistently across UI, API, reports and tests.

## 5. Ticket statuses

Suggested statuses:
- `Open`
- `InProgress`
- `WaitingForCustomer`
- `WaitingForSeller`
- `Resolved`
- `Closed`

The exact meaning of each state must be documented:
- `Open`: case created and awaiting triage.
- `InProgress`: support has accepted responsibility.
- `WaitingForCustomer`: a necessary customer response is awaited.
- `WaitingForSeller`: a necessary seller response is awaited.
- `Resolved`: a resolution has been recorded.
- `Closed`: the case is closed under the published process.

Status changes must be controlled by the backend. A user cannot arbitrarily set a ticket to `Resolved` by sending a string.

If a user reopens a case, define when and how that is permitted, rather than silently changing closed history.

## 6. User stories

### BM-SUPPORT-01 — Open a ticket
As a customer or seller, I want to report an issue so the platform can help me.

Acceptance:
- The caller is authenticated for private/order-linked cases.
- Required category, description and relevant order reference are validated.
- The caller can only attach a ticket to a resource they are permitted to reference.
- A public ticket number is generated.
- Initial status, creation timestamp and audit record are persisted.

### BM-SUPPORT-02 — Track a case
As the ticket creator, I want to see the case status and replies.

Acceptance:
- User can see only their permitted tickets.
- Status, safe timeline and messages are displayed accurately.
- Internal support notes are not exposed.
- Private evidence is visible only to authorized case participants.

### BM-SUPPORT-03 — Triage and assign
As a support agent, I want to categorize, prioritize and assign a case.

Acceptance:
- The actor has the required support permission.
- Status and assignment changes are validated.
- A safe reason/comment is recorded where required.
- The action is audited.

### BM-SUPPORT-04 — Resolve a dispute
As an authorized operator, I want to record a resolution and explain it to permitted parties.

Acceptance:
- The order and relevant evidence are reviewed within permitted access.
- The resolution reason and outcome are recorded.
- Any required order/payment workflow is handled through its dedicated domain service.
- The ticket is not marked resolved before the required actions have the recorded outcomes.
- The customer receives an appropriate status update.

## 7. Data model

Use the `support_tickets` concept in `Database.md`, including:
- Ticket ID and public ticket number.
- Creator user.
- Optional related order.
- Category/type and priority.
- Status.
- Subject and description.
- Assigned support user.
- Resolution code.
- Created/updated/resolved timestamps.

Additional tables may be introduced for:
- Ticket messages/replies.
- Ticket event history.
- Assignments.
- Evidence references.
- Linked dispute records.
- Restricted internal notes.

Use foreign keys, explicit indexes and documented delete/retention rules. Preserve the record of status and resolution changes.

## 8. Ticket creation workflow

1. User selects help/support.
2. UI asks the user to choose a category and optionally a related order.
3. API authenticates the caller when required.
4. Backend validates ticket category, description length and order ownership/participant permission.
5. If evidence upload is enabled, backend validates and stores evidence using private storage.
6. Ticket is created with initial state and public reference.
7. History/audit/outbox records are added as appropriate.
8. User receives a confirmed ticket summary.
9. Ticket becomes visible to the permitted support queue.
10. Authorized support staff triage and assign the ticket.

Do not allow a caller to link a ticket to another user's order merely by knowing its UUID or public order number.

## 9. Authorization model

### Ticket creator
Can view permitted fields for tickets they created, receive replies and submit additional information when the case is open for their response.

### Customer/seller related to an order
May receive relevant case updates and provide information when permitted by the case/order policy. Do not automatically expose all messages from a ticket just because both parties belong to the same order.

### Support agent
Access only to assigned or queue-authorized cases within the agent's support role. Case access and data reveal must follow least-privilege policy.

### Administrator
Can access defined moderation/escalation controls. Financial approval, refund and account suspension actions require their own permissions.

### Internal notes
Internal notes must be stored separately or explicitly marked and must never appear in ordinary customer/seller response DTOs.

## 10. Disputes versus support tickets

A support ticket is a general workflow record. A dispute is an order-related state/process with possible consequences for delivery completion, payment/refund, seller eligibility or commercial resolution.

Do not merge all ticket status changes into the order state machine.

When an order dispute is opened:
- Verify the order and caller eligibility.
- Validate the reason and permitted time window if configured.
- Update the order to `Disputed` only through the order domain service and allowed transition policy.
- Link the ticket/dispute to the order.
- Preserve the original order history/snapshot.
- Notify the relevant permitted parties.
- Restrict sensitive case evidence.

Resolving the ticket does not automatically prove that the financial or order state has been resolved. Apply any required order/refund action through the relevant authorized workflow and record its result.

## 11. Dispute handling process

Recommended operational sequence:
1. Intake and acknowledgment.
2. Categorization and initial risk/urgency assessment.
3. Assignment to an authorized case owner.
4. Evidence collection from permitted participants.
5. Seller/customer communication through approved platform channels.
6. Review of the order snapshot, delivery history and applicable terms.
7. Decision under the published resolution policy.
8. Execute any permitted cancellation/refund/account/listing action through its dedicated service.
9. Record resolution reason and evidence references.
10. Notify relevant participants.
11. Allow appeal/reopen only under an approved policy.
12. Close or preserve the record according to retention rules.

The specific timelines, compensation rules, refund rights and escalation deadlines must be approved and published before the relevant workflows are enabled.

## 12. Evidence and attachments

If evidence uploads are included:
- Use the secure media-upload design from `Integration.md`.
- Keep evidence private.
- Validate file types/size/content.
- Associate evidence with a ticket/order and uploader.
- Restrict download to authorized participants/support.
- Log sensitive document access where required.
- Avoid permanent public URLs.
- Define retention/deletion.
- Provide a safe failure path when upload succeeds but ticket persistence fails.

Do not request evidence that is unnecessary for investigating the case.

## 13. API contract

Potential routes:
- `POST /api/v1/support/tickets`
- `GET /api/v1/support/tickets`
- `GET /api/v1/support/tickets/{ticketId}`
- `POST /api/v1/support/tickets/{ticketId}/messages`
- `POST /api/v1/support/tickets/{ticketId}/close`
- Restricted admin/support routes for queue, assignment, priority, status, internal notes and resolution.
- `POST /api/v1/orders/{orderId}/disputes` for eligible order dispute creation.

Enforce authentication, resource ownership, role policy, pagination, length validation and DTO separation. Do not expose internal notes or unrelated users' private information.

## 14. Notifications and communication

Send a notification only when a meaningful persisted event occurs, such as:
- Ticket created.
- Case assigned.
- Support requests more information.
- Relevant party replies.
- Resolution recorded.
- Case closed/reopened under policy.

Use the outbox provider pattern. In ordinary email/SMS/WhatsApp messages, provide a safe ticket reference and link to the authenticated platform rather than including sensitive evidence or full private order details.

Provider failure must not be shown as ticket failure if the ticket itself was created successfully.

## 15. Errors and edge cases

Handle:
- Unauthenticated ticket creation where login is required.
- Ticket linked to an inaccessible order.
- Invalid category/priority/status.
- Oversized description or attachment.
- Closed ticket reply.
- Unauthorized assignment/status change.
- Assigned agent loses permission or access.
- Concurrent updates.
- Missing evidence.
- Duplicate ticket submission after network retry.
- Database/storage/provider outage.
- Dispute opened after the permitted window.
- Financial resolution fails after ticket decision.

The policy must define whether a late dispute can still be reviewed as a support exception. Do not silently reject every late report if a safety/privacy incident requires a different escalation.

## 16. Required tests

### Unit tests
- Ticket validation.
- Category/status transition policy.
- Assignment and priority permissions.
- Dispute eligibility.
- Resolution-code validation.
- Notification event creation.

### Integration tests
- Customer creates a ticket about own order.
- Customer cannot link the ticket to another user's order.
- Seller cannot read a private unrelated ticket.
- Internal notes never appear in customer DTOs.
- Support assignment requires permission.
- Invalid status transitions are rejected.
- Duplicate creation is handled safely where idempotency is used.
- Evidence access is restricted.
- Order is transitioned through the correct domain service when a dispute is opened.
- Resolution actions are separately authorized/audited.
- Notification failure does not erase the ticket.

### Browser tests
- Customer creates and tracks a ticket.
- Seller sees only permitted case information.
- Support agent triages and responds.
- Customer sees a safe reply without internal notes.
- Evidence upload errors are understandable.
- Resolved/closed ticket actions match the documented policy.

## 17. Operations and metrics

Track:
- Tickets by category/status/priority.
- Time to first response.
- Time to resolution.
- Reopened cases.
- Disputes by order outcome.
- Cases awaiting a customer/seller response.
- Cases blocked by provider/storage failures.
- Escalation rate.
- Complaint rate per completed order, with the denominator explicitly defined.

Do not optimize solely for closing tickets quickly; premature closure can hide unresolved customer issues.

## 18. Acceptance checklist

- [ ] Ticket categories and states are defined.
- [ ] Ticket/order relationships are permission-checked.
- [ ] Customer/seller can track only permitted cases.
- [ ] Support access and internal notes are restricted.
- [ ] Dispute actions use the order domain policy.
- [ ] Refund/cancellation actions use their dedicated workflows.
- [ ] Evidence remains private.
- [ ] Notifications follow the outbox flow.
- [ ] Status/assignment/resolution actions are audited.
- [ ] Policy timelines and resolution rules are approved.
- [ ] Required tests pass.

## 19. Completion gate

The feature is complete when users can raise and track issues, authorized staff can investigate and resolve them through a clear workflow, and any resulting order/financial actions are separately validated and audited.
