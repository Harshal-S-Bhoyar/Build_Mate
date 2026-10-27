# Feature Specification 19 — SEO, Performance and Accessibility

**Document ID:** BM-FEAT-19  
**Version:** 1.0  
**Status:** Proposed quality specification  
**Priority:** P0 for core accessibility/responsive behavior; SEO/performance work phased with launch  
**Dependencies:** Frontend shell, public listing/catalog pages, privacy policy and design system

---

## 1. Purpose

Define the public discoverability, performance, accessibility and technical quality requirements for the BUILD MATE website.

The website must be understandable and usable on common mobile devices, offer reliable performance on typical connections, and expose only appropriate public pages to search engines.

Search visibility must never override contact privacy, private order access, seller-document protection or other security constraints.

## 2. Objectives

- Make appropriate public marketplace and informational pages indexable.
- Prevent private or account-specific pages from being unintentionally indexed.
- Improve initial load and interaction performance.
- Deliver a usable mobile-first experience.
- Target WCAG 2.2 Level AA for applicable UI behavior.
- Maintain semantic metadata, stable URLs and accessible content.
- Provide measurable technical quality indicators.
- Avoid false product availability, review or structured-data claims.

## 3. Scope

### Included
- Public page metadata and canonical URLs.
- Robots/sitemap configuration.
- Public listing/category SEO.
- Protected-page indexing controls.
- Performance measurement and budgets.
- Responsive mobile behavior.
- Accessibility requirements and testing.
- Image optimization and loading strategy.
- Error pages and status behavior.
- Search-engine structured data where accurate and supported.
- Technical monitoring and regression criteria.

### Excluded
- Guarantees of specific search-engine ranking.
- Paid advertising campaign implementation.
- Fabricated reviews or product availability structured data.
- Indexing private customer/seller dashboards.
- Public exposure of private seller contacts for SEO.
- Performance claims unsupported by measurement.
- Full international SEO/multi-region strategy before market expansion.

## 4. Search-engine visibility policy

### Public pages that may be indexable
- Homepage.
- Public material category pages.
- Eligible public listing detail pages.
- How-it-works and informational pages.
- Approved seller public profiles, if such pages are part of the product.
- Published help, policy and editorial content.

### Pages that must not be publicly indexed by default
- Customer dashboard.
- Seller dashboard.
- Admin interface.
- Login/registration and sensitive recovery flows.
- Private order details.
- Message threads.
- Support tickets.
- Verification documents.
- Payment/refund pages.
- Private reports and exports.
- Internal API and health diagnostics beyond any separately approved public health route.

Use authentication/authorization to protect private pages. `robots.txt` or `noindex` is not a security control.

## 5. Metadata and canonical URLs

For public pages:
- Provide a unique and truthful title.
- Provide a meaningful meta description.
- Set canonical URLs where URL variants could create duplicates.
- Use the correct page language.
- Use descriptive, stable URLs where appropriate.
- Avoid putting private data, phone numbers or unnecessary user identifiers in public URLs.
- Prevent duplicate query-parameter versions from multiplying indexable pages unnecessarily.

Do not claim a listing is available, verified or certified in metadata unless the backend supports that claim at the relevant time.

When a listing expires or is removed, define whether it should:
- Return an appropriate not-found/gone response.
- Redirect to a relevant category where genuinely useful.
- Remain publicly visible as unavailable.
- Be removed from the sitemap.

Do not redirect every removed listing to the homepage without considering user/search intent.

## 6. Sitemap and robots behavior

- Generate a sitemap containing only eligible public URLs.
- Exclude private/account/admin pages.
- Avoid including paused, rejected, removed or otherwise non-public listings.
- Update sitemap content when public listing state changes.
- Use an accurate `robots.txt` policy.
- Avoid disclosing sensitive application route names unnecessarily.
- Remember that robots directives are advisory; access control is still enforced by the backend.

For dynamic listing pages, use a controlled generation strategy suitable for the current data volume. Do not generate an unbounded sitemap from every historical order/listing row.

## 7. Structured data

Structured data may help communicate public page content, but it must reflect real visible content and current eligibility.

Potential uses:
- Website/organization metadata when accurate.
- Breadcrumb information.
- Product/offer-like structured content only if the listing and price semantics genuinely satisfy the selected schema's definition and the owner approves that presentation.

Requirements:
- Do not fabricate stock/availability, ratings or reviews.
- Do not mark quote-required listings as fixed-price offers.
- Do not publish private seller contact information via structured data.
- Ensure structured-data values match the visible page and backend state.
- Validate syntax and eligibility before deploying.

Construction materials sold as delivered loads may not fit every generic product schema without nuance. Verify the applicable schema specification rather than assuming that a common shopping example is appropriate.

## 8. Public URL and page-state rules

For listing pages:
- Use stable canonical URLs/identifiers.
- Render approved public fields only.
- Handle expired/paused/removed listings consistently with the backend's public-access policy.
- Do not expose internal rejection notes in page source or metadata.
- Ensure error/status pages do not return a false `200 OK` for a missing/removed resource when a more appropriate status is required.

For private pages:
- Require authentication and authorization at the backend.
- Avoid embedding private page content in shared cache responses.
- Apply appropriate response-cache policy to personalized data.
- Prevent authenticated responses from being stored in a public shared cache.

## 9. Performance objectives

Set budgets based on measurement and hosting capability, then review them periodically.

Recommended web-vitals targets, measured at the 75th percentile for real-user page visits when sufficient data exists:
- Largest Contentful Paint (LCP): at most 2.5 seconds.
- Interaction to Next Paint (INP): at most 200 milliseconds.
- Cumulative Layout Shift (CLS): at most 0.1.

These are target thresholds, not a claim that BUILD MATE currently meets them. Collect data before representing a site as passing real-user performance thresholds.

Additional targets:
- Minimize render-blocking assets.
- Avoid loading large UI libraries on simple pages.
- Use responsive images and appropriate formats.
- Keep API response times measurable.
- Limit oversized client-side bundles.
- Use bounded search pagination and efficient database queries.
- Avoid duplicate API requests for the same state.
- Provide sensible timeouts and cancellation.
- Ensure error handling does not cause infinite retries.

## 10. Frontend performance practices

- Use Next.js rendering strategies appropriate to each page's data/privacy needs.
- Prefer server rendering/static generation for suitable public informational/catalog content where correctness allows.
- Use client-side interaction only where it improves the user experience.
- Do not publicly cache personalized or restricted data.
- Optimize/crop images and set appropriate dimensions.
- Lazy-load below-the-fold imagery when useful.
- Prioritize the main visible content image when appropriate.
- Avoid layout shifts from images, fonts or delayed content.
- Limit unnecessary third-party scripts.
- Track JavaScript bundle sizes.
- Respect reduced-motion settings.
- Test on representative mobile viewport/network conditions.

Any static or cached listing data must follow a defined revalidation/invalidation strategy. The order/checkout API always revalidates current eligibility and price, regardless of what a public page previously displayed.

## 11. Backend and database performance

- Keep search results paginated and bounded.
- Avoid unbounded `Include()` chains and N+1 database behavior.
- Project EF Core queries into purpose-built DTOs.
- Add indexes only when supported by query patterns.
- Measure representative PostgreSQL query plans.
- Use request cancellation and bounded timeouts.
- Apply rate limits to abuse-sensitive endpoints.
- Use async request and background patterns where appropriate.
- Monitor p95/p99 latency and error rate as traffic grows.
- Avoid adding Redis or microservices before measured need justifies them.

## 12. Accessibility target

Target WCAG 2.2 Level AA for the applicable website experience.

### Structure and semantics
- One clear primary page heading.
- Logical heading hierarchy.
- Semantic landmarks.
- Buttons used for actions and links for navigation.
- Correct labels for inputs.
- Accessible names for icon-only controls.
- Tables with correct headers.
- Status messages programmatically available to assistive technology.

### Keyboard interaction
- All important functions usable by keyboard.
- Visible focus indicators.
- Logical tab order.
- Menus, dialogs and popovers operate correctly using keyboard.
- Modal dialogs manage focus and return focus upon close.
- No keyboard trap outside expected modal behavior.
- No important feature available only on hover.

### Visual and sensory behavior
- Adequate text/control contrast.
- Text resizes and page remains usable when enlarged.
- Color is not the only means of indicating a state.
- Motion is limited and respects reduced-motion preferences.
- Focus is not obscured by sticky headers or overlays.
- Touch targets are comfortably operable, aiming for approximately 44 by 44 CSS pixels where practical.

### Forms and errors
- Labels do not depend on placeholders.
- Required fields are identified in text.
- Errors are associated with the affected input.
- Instructions are clear before submission.
- Async validation/status changes are announced accessibly.
- Authentication and timeouts do not unexpectedly erase user-entered safe data.

### Media
- Meaningful images have descriptive alt text.
- Decorative images use empty alt text.
- Text embedded inside images is avoided where possible.
- Upload progress and failure states are announced accessibly.

Automated tools can detect some issues, but manual keyboard and representative screen-reader testing remains necessary.

## 13. Responsive design

Verify:
- Narrow mobile viewport.
- Typical Android phone dimensions.
- Tablet.
- Desktop/laptop.
- Browser zoom/text enlargement.
- Portrait and landscape where relevant.

Core pages must not have unintended horizontal scrolling. Search controls stack appropriately. Listing cards reflow. Tables have an accessible responsive treatment. Modal actions remain visible. Fixed navigation does not obscure content or focus.

Test primary customer, seller and admin workflows. The fact that the homepage is responsive does not prove that the order-review and seller-listing forms are responsive.

## 14. Images, fonts and third-party assets

- Use licensed, owner-supplied or otherwise permitted assets.
- Set image dimensions to reduce layout shift.
- Optimize responsive image sizes.
- Avoid loading all listing images at full resolution.
- Minimize unnecessary web-font variants.
- Use fallbacks when remote font loading fails.
- Do not embed tracking scripts without a documented purpose and approved privacy behavior.
- Keep payment/provider scripts only on pages that need them.
- Do not expose secrets in browser-visible asset URLs/configuration.

## 15. Core Web Vitals and monitoring

Measure using:
- Browser/page-level performance testing.
- Lighthouse or equivalent lab measurement.
- Real-user metrics when sufficient traffic and a lawful, privacy-reviewed collection mechanism exist.
- API response latency and error monitoring.
- PostgreSQL query performance and slow-query diagnostics.
- Frontend bundle-size monitoring.
- Build/CI regression checks.

Lab data and real-user data answer different questions. Do not claim good real-user metrics based only on one local Lighthouse test.

## 16. SEO and privacy interaction

SEO must not be used to expose contact details or private business data.

- Public seller display information must follow the approved field allowlist.
- Seller phone/email/personal WhatsApp remains private unless specific business information is intentionally approved for public release.
- Do not index account-specific dashboard content.
- Do not place private identifiers, addresses or transaction details in canonical URLs.
- Do not expose private content in sitemap, structured data, metadata or server-rendered page source.
- Use public caches only for eligible public content.

## 17. Required testing

### SEO tests
- Public metadata exists and is accurate.
- Canonical URLs are consistent.
- Sitemap contains only eligible public pages.
- Robots policy excludes unintended private routes.
- Structured data, if present, matches visible content.
- Expired/removed listing response and sitemap behavior follow policy.
- Public seller summaries contain no private contacts.

### Performance tests
- Main pages render with reasonable layout stability.
- Listing media is correctly sized/loaded.
- Search pagination is bounded.
- No unexpected waterfall of duplicate requests.
- API/database latency is measured on representative data.
- Build/bundle regressions are reviewed.
- Private data is not served through public caches.

### Accessibility tests
- Automated accessibility scan on primary pages.
- Keyboard-only customer order flow.
- Keyboard-only seller listing flow.
- Modal/dialog focus behavior.
- Form label/error association.
- Contrast checks.
- Representative screen-reader review.
- Narrow screen and zoom tests.

## 18. Acceptance checklist

- [ ] Public/private page indexability policy is documented.
- [ ] Metadata and canonical URLs are accurate.
- [ ] Sitemap includes only eligible public URLs.
- [ ] Protected pages remain protected regardless of SEO directives.
- [ ] Search listing content reflects real eligibility/price data.
- [ ] Core Web Vitals targets are measured rather than claimed.
- [ ] Images/assets are optimized and correctly licensed.
- [ ] Search and API paths are bounded.
- [ ] Accessibility is tested on primary workflows.
- [ ] Responsive behavior is validated on target screens.
- [ ] Private data is absent from metadata, structured data and public cache.
- [ ] Performance regressions have a review/mitigation path.

## 19. Completion gate

SEO, performance and accessibility work is complete when approved public pages are accurately discoverable, private pages remain protected, core journeys meet the agreed usability/accessibility criteria, and performance is evaluated with reproducible measurements.
