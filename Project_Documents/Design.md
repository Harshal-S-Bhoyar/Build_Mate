# BUILD MATE — Design System and UX Specification

**Document ID:** BM-DESIGN-001  
**Version:** 1.0  
**Status:** Proposed design baseline  
**Last updated:** 26 October 2026  
**Product:** Responsive construction-material marketplace  
**Brand:** BUILD MATE (provisional)

---

## 1. Purpose

This document establishes the interface and experience rules for BUILD MATE. It is intended for developers, UI designers, QA engineers and AI coding agents implementing the Next.js frontend.

The interface must make it easy for customers to find a suitable delivered material load, understand the complete price basis, place an order and follow delivery progress. Sellers must be able to maintain listings and respond to orders. Admins must be able to review seller verification, moderate listings and handle exceptions without exposing unnecessary private information.

The design must reinforce the core business model: **one listing equals material plus delivery from one seller**.

## 2. Design goals

1. Make material discovery and ordering straightforward on mobile devices.
2. Make quantities, units, delivery terms and prices understandable before order submission.
3. Establish trust through accurate information and explainable status indicators.
4. Keep seller/customer private contact details off public pages.
5. Make forms and errors easy to understand, including for users with limited technical familiarity.
6. Give sellers an efficient way to manage listings and order updates.
7. Provide accessible keyboard, screen-reader and low-bandwidth experiences.
8. Use consistent patterns so the AI coding agent does not invent a new visual style for every feature.

## 3. Brand direction

### 3.1 Brand personality
- Reliable and practical.
- Local and approachable.
- Transparent about prices and delivery.
- Professional without looking like a complex enterprise tool.
- Clear rather than flashy.

BUILD MATE is a provisional brand. Before production branding is finalized, check domain availability, relevant business-name availability and trademark risks.

### 3.2 Visual direction
Use a clean construction-oriented visual identity. A restrained neutral background, dark readable text and one strong accent color are preferred. Warm earth-inspired accent colors may be used for material categories, provided all text and interactive controls retain adequate contrast.

Do not use excessive gradients, glassmorphism, animations, tiny text, decorative dashboards on customer pages, or fake trust badges.

The design agent may propose a palette, but it must store all colors as design tokens rather than scattering arbitrary hex values across components.

### 3.3 Logo and imagery
- Use an approved wordmark or a simple text-based BUILD MATE brand treatment until a final logo exists.
- Do not fabricate partner, government, certification or payment-provider logos.
- Use genuine, licensed, owner-supplied or clearly marked sample material images.
- Do not present an illustrative stock image as proof that a specific seller owns or supplies that material.
- Use descriptive alt text for meaningful images and empty alt text for purely decorative imagery.

## 4. Design system tokens

Define tokens centrally using CSS variables, Tailwind theme configuration or an equivalent shared design-system file.

Required token groups:

- `color.background`
- `color.surface`
- `color.surface-muted`
- `color.text-primary`
- `color.text-secondary`
- `color.border`
- `color.primary`
- `color.primary-hover`
- `color.focus`
- `color.success`
- `color.warning`
- `color.danger`
- `color.info`
- `radius.sm`, `radius.md`, `radius.lg`
- `shadow.card`, `shadow.overlay`
- `spacing.*`
- `font.family`, `font.size.*`, `font.weight.*`, `line-height.*`
- `z-index.dropdown`, `z-index.sticky`, `z-index.modal`, `z-index.toast`
- `motion.duration-fast`, `motion.duration-normal`

Initial visual recommendation:
- Background: light neutral.
- Cards and forms: white or clearly differentiated surface.
- Primary text: deep charcoal/navy.
- Accent: construction orange or a similarly high-contrast, approved brand color.
- Status colors: only for status communication, with a text label as well as color.

The palette is a design proposal, not a requirement to use any particular commercial color code. Verify contrast before approving tokens. Never rely on color alone to communicate meaning.

## 5. Typography and layout

- Use a readable, widely available sans-serif typeface.
- Use a clear hierarchy for page title, section heading, body text, helper text and labels.
- Avoid long lines of text and overly condensed fonts.
- Use an 8-point spacing rhythm where practical.
- Use consistent container widths and page gutters.
- Keep essential form labels visible; placeholder text is not a replacement for a label.
- Use tabular numerals for monetary values and quantities where they improve scanning.
- Format currency consistently, e.g. `₹12,500.00` where precision is necessary; avoid displaying meaningless trailing decimals when the product's price policy permits simpler formatting.
- Always show the applicable quantity unit alongside unit-based pricing.

The exact typography scale should be implemented centrally, not hand-coded per page.

## 6. Responsive behavior

The website must work on:
- Small mobile screens.
- Typical Android phones.
- Tablets.
- Laptop and desktop browsers.
- Keyboard-only navigation.
- Browser zoom and text enlargement.

Required behavior:
- No page-level horizontal scrolling at supported viewport widths.
- Search controls stack vertically on narrow screens.
- Listing cards reflow into one column when necessary.
- Tables use an accessible responsive treatment, such as a scrollable region with an announced label or stacked record layout.
- Modals fit smaller screens and retain usable close/submit actions.
- Fixed navigation must not cover content or keyboard focus.
- Touch targets should be comfortably usable and generally aim for approximately 44 by 44 CSS pixels.
- Important actions must not be available only through hover.

Test at a narrow mobile viewport, tablet, and desktop viewport in Playwright. Exact supported viewport breakpoints should be centralized and consistent with the chosen UI framework.

## 7. Primary site navigation

### 7.1 Public navigation
Recommended items:
- BUILD MATE logo/home.
- Materials/categories.
- How it works.
- Help/support.
- Log in.
- Register or a contextually appropriate primary action.

Keep navigation short. On mobile, use an accessible menu with visible focus, correct expanded state and keyboard support.

### 7.2 Customer navigation
- Browse materials.
- My orders.
- Saved addresses.
- Profile/account.
- Help and support.
- Sign out.

### 7.3 Seller navigation
- Overview.
- My listings.
- Orders.
- Verification status.
- Profile and service area.
- Help/support.
- Sign out.

### 7.4 Admin navigation
- Overview.
- Seller verification.
- Listing moderation.
- Orders and exceptions.
- Complaints/disputes.
- Notifications/integration health.
- Reports.
- Audit/search, where authorized.
- Account/permissions.

Do not treat navigation visibility as authorization. The API must check every privileged request.

## 8. Required public pages

### 8.1 Homepage
Purpose: quickly explain the service and start a material search.

Recommended content:
1. Clear heading: “Construction Materials Delivered to Your Site.”
2. Search controls for material, quantity/unit, delivery area and requested date.
3. Category cards for black stone, sand, bricks and murum.
4. Short explanation of the material-plus-delivery offer.
5. Trust explanations based on actual platform controls.
6. Seller onboarding call to action.
7. Help, terms, privacy and contact/support links.

Avoid fabricated customer statistics, “number one” claims, fake reviews or claims that every seller is verified if only some are.

### 8.2 Search results
Every result card should display, where available:
- Material image.
- Material category and meaningful specification.
- Seller display name.
- Genuine verification state/badge.
- Load quantity and unit.
- Minimum order quantity.
- Delivered price and pricing basis, or “Request a quote”.
- Delivery area/availability summary.
- Last availability confirmation where useful.
- Actual rating/count only when backed by eligible reviews.
- Primary action: “View details”.
- Secondary action: “Order” or “Request a quote”, as applicable.

Do not show private phone numbers, email addresses, personal WhatsApp links, private verification documents or unrelated seller data.

Filters should be explicit and removable. Include loading, no-results, partial-failure and error states. Do not present an empty result set as proof that materials are unavailable across an entire city.

### 8.3 Listing detail
Display:
- Material specification and images.
- Available load and supported unit.
- Minimum order and capacity limitations.
- Clear fixed delivered price or clearly labelled quote workflow.
- What delivery includes and any legitimate exclusions or additional charges.
- Service area and availability.
- Delivery window/lead time, labelled as an estimate unless confirmed.
- Seller display profile and truthful trust information.
- Cancellation and complaint policy links.
- Platform-mediated question/support action.
- Order/quote CTA.

The order summary must be recalculated by the backend before confirmation.

### 8.4 Public informational pages
Create plain-language pages for:
- How BUILD MATE works.
- Customer help/FAQ.
- Seller onboarding overview.
- Terms of service.
- Privacy notice.
- Cancellation/refund policy.
- Seller policy and complaint process.

Production policies must be reviewed and approved before public launch. Do not create authoritative legal text by inventing unapproved terms.

## 9. Customer screens

### 9.1 Authentication
- Clear form title and next action.
- Visible field labels.
- Inline validation and concise general error messages.
- Loading and resend states for any OTP/passwordless flow.
- Safe response messages that do not disclose whether a private account exists when enumeration could be abused.
- Rate-limit messages that do not expose security implementation details.
- No OTP, session token or password in URL parameters, analytics or logs.

The exact login method must follow the approved authentication design.

### 9.2 Address management
- Support labelled saved addresses.
- Provide required delivery-address fields.
- Provide a way to mark one default address.
- Explain the purpose of any precise location request.
- Avoid requesting GPS permission as a mandatory first step.
- Clearly distinguish saved profile address from the address snapshot for a particular order.

### 9.3 Order submission
Show a review screen with:
- Material and specification.
- Quantity/unit.
- Seller.
- Delivery address.
- Fixed delivered price or accepted quote.
- Platform fee, taxes and discounts where applicable.
- Total due or explicit quote state.
- Delivery details and cancellation terms.
- Required policy acceptance with links.

Require a clear confirmation action. Prevent accidental duplicate submissions in the UI, while relying on server-side idempotency for correctness.

### 9.4 Order detail
Show:
- Public order number.
- Current order status and last update time.
- Agreed material/quantity/price snapshot.
- Delivery-address snapshot, visible only to authorized parties.
- Seller response and progress timeline.
- Available cancellation/issue actions under policy.
- Platform messaging/support.
- Payment/refund state, if enabled.
- Delivery evidence when applicable.
- Review action only for an eligible completed order.

Use text labels and timestamps in addition to any progress indicators.

## 10. Seller screens

### 10.1 Onboarding and verification
- Explain what information is required and why.
- Show status and next step: not submitted, pending, approved, rejected, suspended or expired, as applicable.
- Provide clear re-submission instructions after rejection.
- Do not expose private document links in logs or browser URLs without appropriate protection.
- Only tell the user the precise verification outcome actually returned by the backend.

### 10.2 Listing editor
Group fields into sections:
1. Material and specification.
2. Load size and unit.
3. Minimum and available quantity.
4. Delivered pricing or quote-required setting.
5. Delivery inclusions/exclusions.
6. Service area and availability.
7. Truck/delivery capacity details.
8. Images and description.
9. Preview, submit for review and save draft.

Display a persistent reminder that material and delivery must be offered together. Block publication when `delivery_included` is false or another mandatory rule fails.

### 10.3 Seller order dashboard
Prioritize incoming orders awaiting seller response. Include:
- Order reference.
- Material, quantity and delivery location summary.
- Requested delivery timing.
- Response deadline where configured.
- Accept/reject actions with confirmation where useful.
- Allowed next-status actions.
- Customer communication through platform controls only.
- History of status updates.

Hide unrelated customer addresses and private contact records.

## 11. Admin and support interface

Use compact, task-oriented tables with search, filters, pagination and explicit action permissions.

For destructive or high-impact actions:
- Show a confirmation dialog.
- State the affected entity and action.
- Require a reason code where appropriate.
- Submit the change to a server-side permission check.
- Show the result and audit reference where available.

High-impact actions include seller suspension, listing removal, order override, refund approval, fee-policy change, access changes, and sensitive-data exports.

Use masked/redacted fields in list views. Full private data should be available only where a defined operational purpose and authorization permit it.

## 12. Common components

Build reusable components for:
- App shell/header/footer.
- Navigation menu.
- Page title/breadcrumbs.
- Button and icon button.
- Text field, select, date input, quantity input and textarea.
- Currency/quantity formatter.
- Listing card and listing detail sections.
- Status badge with text.
- Order timeline.
- Seller-verification status panel.
- Loading skeleton.
- Empty state and recoverable error state.
- Toast/inline alert.
- Confirmation dialog.
- Pagination.
- Accessible table.
- File uploader with size/type progress.
- Support/chat panel.
- Consent/terms checkbox.
- Protected private-information display.

Prefer components that encode business rules consistently. A reusable price component must always state the unit and must not imply that a quote-required listing has a confirmed final price.

## 13. Form design and validation

- Every form control has a programmatic label.
- Required fields are identified in text.
- Client validation improves usability; server validation remains authoritative.
- Preserve safe, non-sensitive user inputs after a validation failure when practical.
- Associate field errors with the relevant controls.
- Use clear messages such as “Enter a valid quantity” instead of internal exception names.
- Quantity validation checks positivity, unit compatibility, minimum order and listing capacity.
- Date validation handles past dates, timezone semantics and service availability.
- File upload validates allowed types and size in both frontend and backend.
- Do not rely on the HTML `required` flag alone.

## 14. Accessibility requirements

Target WCAG 2.2 Level AA as the design objective; validate actual pages rather than assuming framework components are accessible.

Required practices:
- Semantic headings and landmarks.
- Full keyboard navigation.
- Visible focus indicators.
- Adequate text/control contrast.
- Accessible names for buttons and controls.
- Error summaries for complex forms where useful.
- Correct dialog focus management and focus return.
- Accessible status announcements for asynchronous updates.
- Respect reduced-motion preferences.
- No meaning communicated solely by color, image or icon.
- Useful alt text for material imagery.
- Tables with appropriate headers.
- Avoid focus traps outside active modal dialogs.

Automated accessibility checks are helpful but do not replace keyboard and screen-reader testing.

## 15. Loading, empty, error and offline states

Every data-driven screen must define:
- Initial loading state.
- Empty state.
- Validation/error state.
- Permission-denied state.
- Session-expired state.
- Recoverable network failure.
- Partial provider failure where applicable.
- Success confirmation.

Use plain language and provide a safe next action. Avoid infinite spinners. Do not automatically repeat a financial/order mutation without an idempotency strategy.

If the connection fails during an order submission, show an uncertain-outcome message and allow the client to check the order by a safe request/idempotency reference rather than immediately creating a second order.

## 16. Content and localization

Initial UI language can be English, but strings should be centralized to support future Marathi and Hindi localization.

Requirements:
- Do not concatenate translated sentences from fragments where grammar changes.
- Format INR, quantities, dates and times consistently.
- Store canonical timestamps in UTC and render them in the selected/local display timezone.
- Use plain-language wording for construction-material units and specifications.
- Keep internal enum names out of user-facing copy.
- Use consistent terminology for “delivered price”, “request a quote”, “seller”, “load”, “quantity”, “delivery address” and “order status”.

Marathi/Hindi production copy should be reviewed by fluent speakers before launch.

## 17. Frontend implementation rules

- Use Next.js App Router and TypeScript.
- Use the backend API as the source of truth; the browser must not connect directly to PostgreSQL.
- Keep feature-specific components within clear feature folders.
- Keep design tokens central.
- Use shared API client and error mapping.
- Validate forms with reusable schemas where appropriate.
- Do not duplicate authorization logic in the frontend as the only protection.
- Never place secrets in `NEXT_PUBLIC_*` variables.
- Do not log tokens, OTPs, full private addresses or verification-document URLs.
- Do not introduce large UI dependencies without a clear need.
- Respect existing linting, formatting and testing conventions.

## 18. Visual QA acceptance checklist

- [ ] Mobile layout has no unintended horizontal overflow.
- [ ] Primary customer journey is clear without instruction.
- [ ] Every listing shows quantity/unit and pricing basis.
- [ ] Material plus delivery is presented as one bundled offer.
- [ ] Quote-required offers are never shown as fixed-price orders.
- [ ] Seller and customer private contact information is absent from public views.
- [ ] Forms have labels, validation and useful errors.
- [ ] Loading, empty and failure states exist.
- [ ] Keyboard focus is visible and dialogs behave correctly.
- [ ] Contrast and status semantics do not depend on color alone.
- [ ] Customer, seller and admin screens respect permissions.
- [ ] No fake ratings, verification badges, pricing or delivery claims.
- [ ] Production legal/policy links point to approved content.
- [ ] Core journeys pass Playwright E2E tests.
