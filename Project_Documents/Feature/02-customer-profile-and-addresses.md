# Feature Specification 02 — Customer Profile and Addresses

**Document ID:** BM-FEAT-02  
**Version:** 1.0  
**Status:** Implementation-ready specification  
**Priority:** P0 — MVP  
**Dependencies:** Feature 01 — Authentication and Sessions

---

## 1. Purpose

Allow authenticated customers to maintain their basic profile and saved delivery addresses. These details support order creation and site delivery while preserving privacy and accurate order history.

A saved address is mutable profile data. An address snapshot on a confirmed order is historical commercial/fulfilment data. The two must not be treated as interchangeable.

## 2. Outcomes

- Customers can read/update their own permitted profile fields.
- Customers can add, edit, view and delete their own saved addresses where policy permits.
- Each customer can maintain at most one default address.
- A delivery address can be selected during order submission.
- Existing orders retain the agreed address snapshot even if the customer later edits the saved address.
- Exact address information is not exposed publicly or to unrelated users/sellers.

## 3. Scope

### Included
- Customer profile record linked to authenticated identity.
- Basic profile edit flow.
- Saved-address CRUD.
- Default-address management.
- Validation and ownership checks.
- Address snapshots for subsequent order workflows.
- Privacy controls and automated tests.

### Excluded
- Public customer profile pages.
- Shared family/company address books.
- Complex geofencing and route planning.
- Live location tracking.
- Automatic address verification by a third party.
- Editing an already-confirmed order's delivery address without a specific approved order-change workflow.

## 4. User stories

### BM-CUST-01 — View profile
As a customer, I want to see my own profile so I can confirm the account details linked to my orders.

### BM-CUST-02 — Update profile
As a customer, I want to update permitted profile fields without changing my account identity or privileged roles.

### BM-CUST-03 — Save an address
As a customer, I want to store a delivery address so I can order material for a particular site without retyping the details every time.

### BM-CUST-04 — Set a default address
As a customer with multiple addresses, I want to select my usual delivery location.

### BM-CUST-05 — Edit/delete an address
As a customer, I want to update or remove an address when it is no longer accurate, subject to any historical order/retention constraints.

### BM-CUST-06 — Use an address for an order
As a customer, I want to select a valid saved address during order submission and see it summarized before confirming.

## 5. Data model

Use the conceptual tables defined in `Database.md`.

### 5.1 Customer profile
Recommended fields:
- `id`
- `user_id` — unique relationship to authenticated identity.
- `preferred_name` — optional.
- `created_at_utc`
- `updated_at_utc`

The identity record remains the source of truth for login channels and verification state. Do not duplicate password/identity management into the customer profile.

### 5.2 Saved address
Recommended fields:
- `id`
- `customer_user_id`
- `label` — e.g. “Home”, “Construction site A”.
- `recipient_name`
- `recipient_phone_private`
- `address_line_1`
- `address_line_2` — optional.
- `locality`
- `city`
- `district` — optional if not needed.
- `state`
- `postal_code`
- Optional latitude/longitude only when the feature and privacy policy justify them.
- `delivery_instructions` — optional and size-limited.
- `is_default`
- `created_at_utc`
- `updated_at_utc`

Use explicit length limits and postal-code validation suitable for supported service regions. Do not assume all valid future addresses share a single city or district.

## 6. API contract

Expected route family:
- `GET /api/v1/customers/me`
- `PATCH /api/v1/customers/me`
- `GET /api/v1/customers/me/addresses`
- `POST /api/v1/customers/me/addresses`
- `GET /api/v1/customers/me/addresses/{addressId}`
- `PATCH /api/v1/customers/me/addresses/{addressId}`
- `DELETE /api/v1/customers/me/addresses/{addressId}`
- `PUT /api/v1/customers/me/addresses/{addressId}/default`

The `me` route family intentionally avoids letting the caller choose an arbitrary customer user ID.

### API requirements
- Derive the authenticated customer identity from the server-side session/principal.
- Validate all input fields on the server.
- Return DTOs, not EF Core entities.
- Do not include unrelated account data or private addresses in profile summaries.
- Validate address ownership for all operations.
- Use `404` or another safe documented response when a resource should not be disclosed to a non-owner.
- Make default selection atomic and enforceable by the database as well as application logic where feasible.

## 7. Business rules

1. Only the authenticated customer can manage that customer's addresses.
2. A customer may have at most one default address.
3. Creating the first address should follow the approved default-address behavior; document whether it becomes default automatically.
4. Setting a new default must unset the previous default atomically.
5. Required address fields must be present and valid.
6. Optional fields may be empty/null but must respect size limits.
7. Deleting an address must not delete or mutate an existing order's historical snapshot.
8. An address referenced by an active workflow may be protected from hard deletion if the approved policy requires it; the UI should explain any restriction.
9. An order snapshots the selected address when the order is confirmed under the approved order flow.
10. The backend must not trust address fields submitted as a copied arbitrary object when the workflow requires a saved address ID and ownership check.
11. If one-time delivery addresses are supported later, they need their own validation and snapshot contract.
12. Exact addresses must not appear in public search/listing responses.

## 8. Validation

Validate:
- Recipient name length and requiredness.
- Recipient phone format under the selected supported-country policy.
- Address lines and locality.
- City/state.
- Postal code length/format for the supported region.
- Instruction field length and content handling.
- Coordinates are within allowed numeric ranges if captured.
- Default-address update only targets an existing address owned by the current customer.

Do not depend only on browser validation. Avoid rejecting legitimate addresses solely because they do not match a narrow hardcoded pattern.

## 9. Privacy and access rules

- Address list/detail endpoints require authentication.
- A customer can only access addresses belonging to their account.
- Sellers must not access a customer's complete address book.
- A seller may receive the delivery details necessary for an eligible order under the order/privacy policy.
- Other sellers and other customers must never receive that address.
- Public listing DTOs do not include customer addresses or recipient phone data.
- Address data must be minimized in logs and analytics.
- If coordinates are collected, explain why and permit manual location entry when practical.
- Any export/download must be authenticated and access controlled.

## 10. Frontend screens

### Profile
- Display basic permitted fields.
- Make identity/verified channel status clear without exposing secrets.
- Save changes and show success only after API confirmation.
- Provide field-level errors.

### Address list
- Show label, concise locality summary and default state.
- Do not show full recipient phone unnecessarily in summary cards.
- Include add, edit, delete and set-default actions where permitted.
- Provide a meaningful empty state.

### Address form
- Use visible labels and required-field indicators.
- Separate required address data from optional delivery instructions.
- Explain how the address will be used.
- Do not force GPS permission.
- Preserve safe form inputs after a recoverable validation failure.

### Order address selection
- Show a concise selected-address summary and an edit/change path before confirmation.
- Verify current address validity with the backend.
- The eventual order detail uses the stored snapshot rather than displaying a live reference that could change unexpectedly.

## 11. Concurrency and integrity

The default-address rule can be violated by simultaneous updates if implemented as separate unchecked reads/writes.

Use an appropriate transaction and database constraint, such as a partial unique index for default addresses per customer. Handle uniqueness/concurrency conflicts with a retry or a clear safe response.

Address CRUD operations should not create an unintended second default address. Tests must verify the outcome under concurrent updates where practical.

## 12. Error handling

Cover:
- Unauthenticated request.
- Wrong-owner address access.
- Invalid/missing required fields.
- Duplicate/default concurrency conflict.
- Address not found.
- Address cannot be deleted under the approved policy.
- Database/service unavailable.
- Expired session or CSRF failure.
- Invalid coordinate or postal-code input.

Errors should explain what the customer can safely do next and must not expose another user's address.

## 13. Required tests

### Unit tests
- Address DTO validation.
- Allowed profile-field updates.
- Default-selection business policy.
- Address snapshot mapping.
- Optional-field boundary cases.

### Integration tests
- Customer can create/list/edit/delete an eligible own address.
- Customer cannot read/update/delete another customer's address.
- Default flag remains unique.
- Removing or updating an address does not mutate an existing order snapshot.
- Invalid address input is rejected server-side.
- Address DTOs do not appear in public API responses.
- Seller access is restricted to the required order context.
- Deletion/retention rules work as documented.

### Browser tests
- Add and edit an address from mobile and desktop layouts.
- Set a default address and verify the displayed state.
- Handle validation and network errors.
- Select the address in the order-review flow.
- Confirm that the order address summary remains stable after the profile address is edited later.

## 14. Acceptance checklist

- [ ] Profile is linked to the authenticated identity.
- [ ] A customer can update only allowed profile fields.
- [ ] Address CRUD is implemented and validated.
- [ ] Server-side ownership is enforced.
- [ ] At most one default address exists per customer.
- [ ] Database constraints and transactions protect default selection.
- [ ] Order address snapshot contract is supported.
- [ ] Existing orders remain stable after address edits.
- [ ] Public responses do not expose saved addresses or recipient phone numbers.
- [ ] UI covers empty/loading/error/access-denied states.
- [ ] Tests cover wrong-owner and concurrency cases.

## 15. Completion gate

This feature is complete when address data is securely managed, the default-address invariant is enforced, and downstream order creation can use a stable address snapshot without exposing the customer's entire address book.
