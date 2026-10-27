# Feature Specification 18 — Audit Logging and Privacy

**Document ID:** BM-FEAT-18  
**Version:** 1.0  
**Status:** Mandatory privacy and audit baseline  
**Priority:** P0 — Security foundation  
**Dependencies:** Authentication, seller verification, orders, media, support and admin controls

---

## 1. Purpose

Define how BUILD MATE records security-sensitive and business-critical activity, minimizes personal data, controls access, manages retention and supports privacy-related requests.

Audit logging and diagnostic logging are different systems with different purposes. Diagnostic logs help developers diagnose failures; audit records establish who performed a sensitive action, what resource was affected and what outcome was recorded.

Neither system should become an uncontrolled store of passwords, tokens, verification documents, full contact details or private messages.

## 2. Objectives

- Maintain a reliable trail of important administrative and financial actions.
- Make sensitive access and state changes attributable to an actor.
- Keep audit records protected from ordinary application-level modification.
- Minimize personal data collection and duplication.
- Apply role and resource permissions to private data.
- Document retention, deletion and legal-preservation handling.
- Redact secrets and unnecessary PII from logs.
- Support investigation of security/privacy incidents.
- Test that audit failures and privacy boundaries are handled correctly.

## 3. Scope

### Included
- Audit-event schema and capture rules.
- Security/business event catalogue.
- Diagnostic log redaction policy.
- Access controls and search for audit events.
- Personal-data classification and minimization.
- Retention/deletion/anonymization workflow requirements.
- Restricted export and document access controls.
- Privacy-request workflow requirements.
- Security incident evidence preservation.
- Required tests and monitoring.

### Excluded
- Recording every database read/write indiscriminately.
- Storing raw authentication secrets in logs.
- Default recording/transcription of telephone conversations.
- Indefinite retention of every user message and document.
- Using audit logs as a public analytics feed.
- Making unreviewed legal claims about retention, consent or regulatory compliance.

## 4. Logging categories

### 4.1 Diagnostic/application logs
Purpose: troubleshooting and operational monitoring.

May include:
- Timestamp.
- Environment and application version.
- Correlation/trace ID.
- Operation/route.
- Result status.
- Duration.
- Safe exception category.
- Resource ID where appropriate.
- Safe provider reference.

Must avoid passwords, OTPs, session cookies, authorization headers, reset links, payment secrets and unnecessary personal data.

### 4.2 Security logs
Purpose: detecting authentication and authorization abuse and supporting security investigations.

May include:
- Authentication success/failure events, where approved.
- Access-denial outcome.
- Rate-limit events.
- Account/session security changes.
- Privileged role/permission changes.
- Invalid webhook-signature events.
- Suspicious file-access or export attempts.
- Safe correlation and actor identifiers.

Use a defined policy so security logs are neither too sparse to investigate nor so detailed that they collect excessive personal data.

### 4.3 Business audit events
Purpose: trace important product and administrative changes.

Required event categories should include:
- Seller application submission and verification decision.
- Seller suspension/reinstatement.
- Listing moderation/override.
- Order status transition and authorized override.
- Cancellation/dispute resolution where sensitive.
- Fee-policy change and adjustment.
- Payment/refund operations when enabled.
- Role/permission change.
- Private document access where required.
- Sensitive-data export.
- Support case assignment/resolution.
- Privacy-request and retention actions.
- Provider enablement/disablement where operationally significant.

## 5. Audit-event model

Use the conceptual `audit_events` table in `Database.md`, with fields such as:
- Audit event UUID.
- Actor user ID, where known.
- Actor role/category.
- Action name.
- Entity type and entity ID.
- Correlation ID.
- Safe metadata.
- Timestamp.

Consider adding:
- Outcome.
- Reason code.
- Source/service actor category.
- Environment or deployment version where useful.
- A safe reference to an associated case/approval.
- Event schema version.

Avoid embedding large arbitrary JSON, complete request bodies or private documents in the metadata.

## 6. Audit integrity

- Ordinary application roles must not be able to update or delete audit records.
- Use append-only application behavior and suitably restricted database privileges.
- Restrict audit-table reads and exports to authorized roles.
- Record a new correction/compensating audit event rather than rewriting old history.
- Monitor write failures for high-impact actions.
- Consider stronger external/immutable log storage if threat and compliance needs justify it.
- Apply time synchronization and consistent UTC timestamps.
- Protect backups and replicas that contain audit records.

A database owner or compromised infrastructure administrator may still alter ordinary database records. If stronger tamper resistance is required, it needs a separate threat model and infrastructure design; do not claim that a normal table is tamper-proof.

## 7. Audit transaction rules

Where an action requires audit to be trustworthy:
- Persist the business change and audit record in the same transaction where practical.
- If required audit creation fails, follow an explicit fail-safe rule for that action.
- Do not silently carry out a high-impact permission/refund/order override without its required trace.
- For asynchronous/external actions, audit the intention and the later outcome with suitable correlation.
- Ensure duplicate retries do not create misleading repeated business effects.

For provider operations, record the request/attempt and actual outcome separately if that distinction matters. Never mark an external transaction successful merely because an audit event was written.

## 8. Event names and reason codes

Use stable, explicit action names, for example:
- `seller.application.submitted`
- `seller.verification.approved`
- `seller.status.suspended`
- `listing.moderation.rejected`
- `order.status.changed`
- `order.override.applied`
- `payment.refund.requested`
- `payment.refund.completed`
- `fee.policy.activated`
- `access.private_document.viewed`
- `report.export.created`
- `privacy.request.recorded`

These are illustrative names. Create a central event catalogue and do not generate arbitrary uncontrolled action names from user input.

Reason codes should come from controlled sets for high-impact operations. Optional notes must be length-limited, handled as untrusted text and kept private where appropriate.

## 9. Redaction requirements

Sensitive values that should not appear in ordinary logs include:
- Passwords.
- OTPs.
- Session cookies and session tokens.
- Access/refresh tokens.
- Password-reset and verification links.
- API keys and provider credentials.
- Payment credentials.
- Full card/account data.
- Private document content or signed URLs.
- Full message bodies unless a specific justified process exists.
- Full phone/email/address values unless a documented security/operational need authorizes them.

Prefer allowlisted logging DTOs over logging a complete request object and attempting to redact fields afterward.

Test redaction explicitly with synthetic secrets so regressions can be caught.

## 10. Personal-data classification

Classify data based on its sensitivity and use. A starting scheme:

### Public
Approved material category, listing description, public listing images and approved seller display fields.

### Internal
Operational status summaries, non-sensitive error codes, aggregate dashboard values.

### Confidential/personal
Account email/phone, saved addresses, order details, private messages and support information.

### Highly restricted
Authentication secrets, provider credentials, sensitive verification documents, payment secrets and other specially protected materials.

This classification is an engineering policy proposal. Final classification and legal obligations must be reviewed for the actual business and data collected.

## 11. Data minimization and purpose limitation

For every stored personal-data field, document:
- Why it is needed.
- Which feature uses it.
- Who can access it.
- Whether a less sensitive alternative works.
- How long it is needed.
- How it is corrected/deleted/anonymized if permitted.
- Whether it is shared with a third-party provider.

Examples:
- Do not collect precise GPS coordinates if locality/postal-code selection meets the delivery requirement.
- Do not display a recipient phone number in a general order list unless the workflow needs it.
- Do not store a complete SMS body as the permanent event history unless justified.
- Do not collect identity documents from sellers without an approved verification purpose.
- Do not copy all customer contact data into analytics tables.
- Do not expose an address book to a seller when one order-specific address is sufficient.

## 12. Privacy notices and user-facing transparency

Before production, provide approved, accessible notices explaining relevant data practices, including:
- Types of personal information collected.
- Purposes of collection.
- Relevant sharing with sellers/service providers.
- Communication-channel behavior and preferences.
- Retention/deletion principles.
- How a user can contact support or submit an appropriate privacy request.
- Applicable account and legal limitations.

The notice must accurately reflect actual system behavior and provider relationships. Do not state that data is never shared when specific order details are necessarily provided to a seller for fulfilment.

Have applicable legal/privacy requirements reviewed by qualified advisers for the actual operating entity, users and services.

## 13. Retention and deletion

Define a retention schedule per data class rather than one global “delete after X days” rule.

Data categories may include:
- Authentication/security records.
- Customer profiles and saved addresses.
- Seller applications/documents.
- Listings/media.
- Orders and commercial snapshots.
- Payment/refund/ledger records.
- Messages and support tickets.
- Audit events.
- Operational logs and analytics events.
- Backups.

The exact retention duration depends on operational needs and applicable obligations; it must be explicitly decided rather than invented here.

### Deletion/anonymization workflow
1. Authenticate/requestor identity as required.
2. Determine the data subject and records in scope.
3. Check identity, ownership and any valid retention/legal-hold constraints.
4. Evaluate linked orders, financial records, disputes and audit obligations.
5. Execute permitted deletion/anonymization in a traceable workflow.
6. Delete dependent media where permitted.
7. Record an appropriately minimized audit result.
8. Explain the outcome and any lawful limitations to the requester.
9. Consider backup lifecycle and restoration behavior.

Do not promise immediate physical removal from every backup or provider when the actual architecture cannot guarantee it. Document the backup expiry and restoration/deletion reconciliation process.

## 14. Privacy request handling

Potential request types:
- Access to personal data.
- Correction of inaccurate data.
- Account closure.
- Deletion/anonymization where permitted.
- Communication/notification preference update.
- Complaint about privacy or unauthorized access.

Requirements:
- Authenticate the requester appropriately.
- Verify ownership without unnecessarily collecting additional sensitive data.
- Define response owner and workflow.
- Restrict exported information to records in scope.
- Redact other users' private data.
- Record request status and action.
- Use approved response templates and timelines.
- Escalate legal/retention uncertainty rather than making unsupported promises.

This specification does not assign a statutory response deadline. Confirm applicable obligations through qualified legal advice.

## 15. Third-party sharing

Document every provider that receives personal data, such as:
- SMS gateway.
- WhatsApp Business provider.
- Masked-calling provider.
- Payment gateway.
- Object-storage provider.
- Email provider.
- Monitoring/analytics provider.

For each provider, maintain:
- Purpose and data categories shared.
- Data required by the provider.
- Credentials/access ownership.
- Provider retention/deletion terms where known.
- Region/location considerations where applicable.
- Callback/webhook security.
- Access/deactivation process.
- Relevant contract/consent/notice needs.

Minimize the data sent in each request. Do not provide a provider with customer addresses, messages or identity documents just because its SDK accepts them.

## 16. Access logging and sensitive reads

Not every database read needs a dedicated business audit event, but sensitive-access requirements must be explicit.

Consider audit events for:
- Private verification-document access.
- Sensitive record export.
- Broad order/customer-data search.
- Admin viewing of restricted payment information.
- Security-policy changes.
- Access to a case outside a user's ordinary self-service context.

Balance investigation usefulness with storage and privacy. Define thresholds and purposes rather than turning every ordinary profile view into a long-term detailed behavioral record.

## 17. Incident response

The operational plan must support:
1. Identifying the incident and its owner.
2. Limiting further unauthorized access.
3. Disabling affected credentials/features/providers where appropriate.
4. Preserving relevant logs/audit records.
5. Identifying affected records/users.
6. Rotating exposed secrets.
7. Restoring safe operation.
8. Assessing notification/incident obligations with the responsible adviser.
9. Recording root cause and remediation.
10. Adding tests and updating the threat model.

Never put exposed secrets into a new ticket or audit note as a way to document them. Use a safe reference and restricted evidence process.

## 18. Required tests

- Sensitive actions produce expected audit events.
- High-impact operation fails safely when required audit recording fails.
- Audit records cannot be modified by ordinary application roles.
- Private data/credentials are absent from logs.
- Public DTOs omit restricted fields.
- Role-based audit access is enforced.
- Export access and data scope are restricted.
- Privacy-request workflow checks identity and retention constraints.
- Deletion/anonymization preserves required links/financial history appropriately.
- Provider data sharing uses approved DTOs.
- Backup/restoration behavior respects documented retention handling.
- No default call recording occurs.

## 19. Acceptance checklist

- [ ] Diagnostic, security and business audit logs are distinguished.
- [ ] Required audit-event catalogue is defined.
- [ ] Audit permissions and integrity controls are implemented.
- [ ] Log redaction is tested.
- [ ] Data classifications and purposes are documented.
- [ ] Retention rules exist for all major data classes.
- [ ] Account closure/deletion/anonymization has a safe workflow.
- [ ] Third-party data sharing is inventoried.
- [ ] Privacy notices reflect actual product behavior.
- [ ] Privacy requests have an owner and tracked workflow.
- [ ] Incident response and credential rotation are documented.
- [ ] Sensitive reads/exports are appropriately audited.

## 20. Completion gate

Audit and privacy controls are complete when sensitive operations are traceable, personal data is collected/shared only for documented purposes, logs do not become a secret store, and privacy requests and incidents can be handled through a defined operational process.
