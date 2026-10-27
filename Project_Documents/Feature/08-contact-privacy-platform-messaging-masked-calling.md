# Feature Specification 08 — Contact Privacy, Platform Messaging and Masked Calling

**Document ID:** BM-FEAT-08  
**Version:** 1.0  
**Status:** Privacy requirements mandatory; masked calling gated  
**Priority:** P0 for privacy and platform-mediated support; masked calling planned  
**Dependencies:** Feature 01 — Authentication; Feature 06 — Order/Quote; applicable order lifecycle features

---

## 1. Purpose

Enable customers, sellers and authorized support staff to communicate about enquiries and orders while keeping private contact details protected.

BUILD MATE is not a public seller directory. A customer must not need to visit a listing to obtain a seller's personal phone number or WhatsApp number. The platform should provide usable communication tools inside the customer journey.

Two distinct capabilities are covered:

1. **Platform messaging:** Messages stored and accessed through BUILD MATE under participant and resource permissions.
2. **Masked calling:** A provider-mediated call connection that protects personal caller-ID details, only if an actual provider supports and passes end-to-end privacy testing.

Masked calling is not a required condition for launching basic marketplace order flows. If it is unavailable, platform messaging and support remain the default.

## 2. Outcomes

- Public listing/search responses do not expose private seller contacts.
- Customer and seller can communicate through an authorized order/enquiry thread.
- Only thread participants and permitted case-support personnel can access messages.
- Contact/privacy abuse can be reported and handled under a defined moderation process.
- Masked calling is available only to eligible participants and orders.
- Provider and network failures are reported truthfully.
- Communication actions are auditable without retaining unnecessary private data.

## 3. Scope

### Included
- Thread creation and association with an authorized order or enquiry.
- Participant records and access checks.
- Send/read message APIs.
- Text-length and rate limits.
- Thread status and message timestamp.
- Basic reporting/moderation controls.
- Platform communication entry points in customer/seller screens.
- Optional masked-call request/session lifecycle.
- Communication-event metadata and audit controls.
- Security tests for privacy boundaries.

### Excluded
- Public access to seller phone/email/WhatsApp details.
- Unrestricted direct messages between any two users.
- Default audio recording or transcription.
- Public chat rooms.
- Unapproved media/attachment types.
- Automatic release of the seller's personal number as a fallback.
- A guarantee that all contact information embedded in free text can be detected or blocked.

## 4. Communication model

### 4.1 Threads
A thread has a unique ID, status and authorized participant list. It may relate to:
- An order.
- A permitted pre-order enquiry.
- A support/dispute case, through an explicitly defined association.

Specify exactly which relationship is required when creating each thread type. The implementation must not accept arbitrary IDs without validating resource existence and caller permission.

### 4.2 Participants
Each thread records its participants and roles. Participation is not inferred merely from knowing the thread UUID.

Every read, send, attachment, export and moderation request must check current authorization. If a user loses the required account/order access, access should be restricted according to the approved policy.

### 4.3 Messages
A message includes:
- Message ID.
- Thread ID.
- Sender user ID.
- Body.
- Moderation state.
- Created timestamp.
- Optional redaction metadata.

Messages are application data, not trusted system instructions. The content must never control tool permissions, database queries or other security-sensitive behavior.

## 5. User stories

### BM-COMMS-01 — Ask about a listing
As a customer, I want to ask a seller a question about an offer without being shown the seller's private phone number.

Acceptance:
- An eligible enquiry thread is created or reused according to policy.
- The customer is authorized to the related listing/enquiry.
- The seller sees the enquiry through the seller interface.
- Public listing response data remains private-contact-safe.

### BM-COMMS-02 — Message about an order
As a customer or seller, I want to communicate with the other authorized order participant.

Acceptance:
- The thread is associated with the relevant order.
- Both parties are authorized for that order/thread.
- Unrelated users cannot read/write messages.
- Message ordering/timestamps are consistent and visible.

### BM-COMMS-03 — Report a communication
As a participant, I want to report a suspicious or inappropriate message.

Acceptance:
- The report captures the relevant thread/message, reason and reporter.
- The report is accessible only to authorized moderation/support roles.
- The original message and report have an audit trail under the retention policy.

### BM-COMMS-04 — Start a masked call
As an eligible participant, I want to request a call through BUILD MATE without disclosing my personal phone number.

Acceptance:
- Calling is available only if the feature and provider are enabled.
- Caller is authorized for the order.
- Provider creates an order-bound session/call according to its documented API.
- Personal number privacy has been verified from both participants' perspective.
- No direct-number fallback occurs.

## 6. Contact privacy contract

### 6.1 Public data
Public listing/search APIs must exclude:
- Seller private phone.
- Seller private email.
- Personal WhatsApp number/link.
- Private residential address.
- Payout or banking information.
- Verification document references/URLs.
- Internal verification or moderation notes.
- Private customer data.

Use dedicated public DTOs. Do not serialize the full seller object and rely on the UI to hide fields.

### 6.2 Order-specific data
A seller may need the delivery address and operational details for an accepted/eligible order. Access is limited to that specific order and to the point in the lifecycle defined by the approved policy.

The seller must not access:
- The customer's unrelated saved addresses.
- The customer's other orders.
- Another seller's customers or messages.
- Private fields that are not needed to fulfil the order.

Support/admin access to private contact data must be purpose-limited and permissioned.

### 6.3 Data in free-form messages
Users may attempt to enter a phone number, email address, WhatsApp link or other contact route into a message.

Possible controls include:
- Warning users about platform communication rules.
- Detecting common phone/email/link patterns.
- Rate limits and spam reporting.
- Moderation review.
- Blocking clearly disallowed contact patterns when the policy is approved.
- Context-sensitive handling for legitimate delivery instructions.

Do not claim full prevention of contact exchange unless the content-control design and its limitations are documented. Do not delete messages silently without applying a documented moderation/audit policy.

## 7. Authorization policy

### Customer
May:
- Read/write threads in which they are an authorized participant.
- Create an eligible enquiry linked to a listing.
- Communicate about their own order.
- Report a message.
- Initiate an approved masked call for an eligible order.

May not:
- Read another customer's thread.
- Join a thread by supplying its ID.
- Access seller-only verification data.
- Initiate a call concerning another user's order.

### Seller
May:
- Read/write authorized threads linked to their seller listings/orders.
- Communicate with a customer involved in the relevant enquiry/order.
- Initiate an eligible masked call if enabled.
- Report a message.

May not:
- Access unrelated customers or sellers.
- Read another seller's threads.
- Obtain the customer's complete saved-address list.
- Retrieve private customer contact data outside the approved order context.

### Support/admin
Access is role- and case-scoped. Elevated access is audited. A general admin role should not automatically make broad unfiltered export of all messages and private numbers permissible.

Enforce all rules on the server.

## 8. API contract

Proposed route family:
- `GET /api/v1/threads`
- `POST /api/v1/threads`
- `GET /api/v1/threads/{threadId}/messages`
- `POST /api/v1/threads/{threadId}/messages`
- `POST /api/v1/threads/{threadId}/reports`
- `POST /api/v1/orders/{orderId}/masked-calls` — enabled only after the call provider is validated.
- `GET /api/v1/orders/{orderId}/communications` — optional, scoped summary.

### API requirements
- Validate thread membership on every read/write.
- Validate related order/listing access before creating a thread.
- Use bounded page size and message length.
- Never accept arbitrary participant assignment from an untrusted client.
- Return message/thread DTOs rather than persistence entities.
- Do not reveal existence of unrelated private threads.
- Rate-limit message and call initiation.
- Use stable error responses for authorization denial, closed thread and provider unavailability.

## 9. Message behavior

Define and implement:
- Maximum message-body length.
- Allowed content/encoding.
- Whether edit/delete/redaction is supported.
- Moderation/reporting flow.
- Thread closure rules.
- Message pagination/order.
- Attachment support status (off by default unless explicitly implemented).
- Retention and legal-preservation policy.
- Notification behavior for new messages.

Recommended MVP behavior:
- Text-only messages.
- Server-generated timestamp.
- Message body escaped/rendered as text, not executable HTML.
- Explicit thread participants.
- Paginated message history.
- No arbitrary HTML rendering.
- No audio recording/transcription.

If attachments are later enabled, reuse the secure upload model from `Integration.md` and `Authentication-and-Security.md`.

## 10. Masked calling — enablement gate

### 10.1 Provider capability validation
The platform must verify:
- Whether the provider supports two-party number masking for the intended use case.
- Caller-ID behavior for both parties and supported carriers/devices.
- Number/session allocation and expiry.
- Call timeout, busy, unanswered, failure and retry semantics.
- Callback/webhook authentication.
- What data is visible in the provider dashboard and logs.
- Applicable country/region availability and operational constraints.
- Provider charges, limits and support process.

Do not assume that a click-to-call API or a hidden phone field equals masked calling.

### 10.2 Call initiation
When enabled:
1. Authenticate caller.
2. Verify caller participates in the specific order.
3. Verify order state and call eligibility.
4. Apply rate limits and abuse controls.
5. Request a short-lived provider session/connection.
6. Record provider reference and safe metadata.
7. Return a session result that does not expose the other party's protected number.
8. Process provider callback/events securely.
9. Display the actual call outcome.

### 10.3 No direct-number fallback
If the provider is unavailable or masking fails:
- Show a clear unavailable message.
- Offer platform messaging/support.
- Do not reveal personal phone numbers.
- Do not create a call session without checking authorization.
- Do not say a call was placed or connected unless the returned outcome supports that statement.

### 10.4 Audio recording
Recording is disabled by default. Any future recording, transcription or analytics feature requires separate approval for:
- Purpose and lawful basis.
- Notice/consent.
- Access permission.
- Storage encryption.
- Retention/deletion.
- Request/complaint handling.
- Provider capabilities and regional constraints.

## 11. Database and audit

Use the conceptual schema from `Database.md`:
- `message_threads`
- `message_thread_participants`
- `messages`
- `communication_events`
- Appropriate support/report records.

Important controls:
- Unique participant relationship per thread/user.
- Indexed thread message history.
- Foreign keys to relevant orders/users where applicable.
- Server-generated timestamps.
- Safe correlation/provider references.
- No raw call secret or private provider token.
- No audio stored by default.
- Message content and attachments handled under the approved retention policy.

## 12. Errors and edge cases

Handle:
- Caller is not a participant.
- Order/listing is inaccessible or ineligible.
- Thread is closed.
- Message exceeds limit.
- Rate limit triggered.
- Moderation/report failure.
- Provider disabled/misconfigured.
- Masked call session expires.
- Provider timeout or contradictory callback.
- Duplicate call request.
- User account becomes suspended.
- Delivery dispute requires access to historic messages.

Unknown provider outcome must be treated as uncertain, not successful. A retry must not create uncontrolled duplicate calls.

## 13. Required tests

### Authorization/privacy tests
- Customer A cannot read Customer B's thread.
- Seller A cannot access Seller B's threads.
- Caller who knows a UUID cannot join an unrelated thread.
- Seller cannot access unrelated saved addresses.
- Public listing DTO contains no private contacts.
- Support access is appropriately case-scoped.
- Private information is absent from logs/errors.

### Messaging tests
- Authorized participants can send/read messages.
- Message length/validation rules apply server-side.
- HTML/script content is rendered safely.
- Pagination ordering is stable.
- Closed-thread behavior matches policy.
- Reporting creates an authorized moderation record.

### Masked-call tests
- Unauthorized participant cannot initiate a call.
- Ineligible order cannot be used.
- Rate limiting applies.
- Disabled/misconfigured provider is reported safely.
- Duplicate request behavior is controlled.
- Invalid/forged provider callbacks are rejected.
- Caller ID privacy has been tested on both sides before release.
- Provider failure never triggers direct-number disclosure.
- Audio recording remains off unless separately approved.

## 14. Acceptance checklist

- [ ] Public listing responses expose no private contacts.
- [ ] Threads use explicit participant membership.
- [ ] Every message operation verifies current authorization.
- [ ] Message content is handled safely.
- [ ] Reporting/moderation path exists or is explicitly deferred with no false UI claim.
- [ ] Message limits and rate limits are enforced.
- [ ] Order-specific address disclosure follows an approved policy.
- [ ] Masked calling remains disabled until provider validation passes.
- [ ] No direct-contact fallback reveals private numbers.
- [ ] Communication events and admin access are audited appropriately.
- [ ] Tests cover wrong-owner, provider failure and privacy edge cases.

## 15. Completion gate

The privacy and messaging portion is complete when authenticated users can communicate only in authorized contexts and public interfaces cannot retrieve private contact details. Masked calling is complete only after documented two-party privacy tests pass with the selected provider.
