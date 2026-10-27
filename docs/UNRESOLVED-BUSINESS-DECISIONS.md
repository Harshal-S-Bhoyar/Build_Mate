# BUILD MATE — Unresolved Business & Commercial Decisions

**Document ID:** BM-DECISION-REGISTER-001  
**Version:** 1.0  
**Status:** Pending Product Owner Approval  
**Last Updated:** October 2026  

---

## 1. Operating Rule on Commercial Policies

> [!IMPORTANT]
> **Strict Policy Constraint:**  
> AI coding agents and engineering contributors **MUST NOT** invent, assume, or hardcode commercial terms, commission percentages, payment flows, refund rules, cancellation penalties, or legal policies.  
> All features touching these domains must remain behind feature gates, use configurable policy abstractions, or operate against mock/sandbox interfaces until the Product Owner explicitly signs off on these decisions.

---

## 2. Unresolved Commercial & Policy Register

### Decision 1: Platform Commission & Fee Structure
- **Affected Specifications:** [`12-commissions-and-fees.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/12-commissions-and-fees.md), [`Database.md`](file:///Users/siddharth/Building_Material/Project_Documents/Database.md)
- **Pending Questions:**
  1. What is the fee calculation model: fixed amount per load (e.g., ₹200/brass), percentage of material price, or percentage of total load price (material + delivery)?
  2. Who pays the platform fee: customer (added to subtotal), seller (deducted from payout), or split?
  3. Are there introductory fee waivers or tiered rates based on seller volume?
  4. Are taxes (GST at 18%) charged on top of the platform fee, and how is the GST invoice generated?
- **Engineering Recommendation:** Implement a database-driven `commission_policies` table with date ranges, percentage, and flat fee fields. In Phase 1, default to zero fee or configurable test percentage.

### Decision 2: Payment Collection Timing & Payout Mechanism
- **Affected Specifications:** [`11-payments-refunds-and-reconciliation.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/11-payments-refunds-and-reconciliation.md)
- **Pending Questions:**
  1. When is customer payment collected:
     - Option A: At checkout (authorized/captured upfront).
     - Option B: When seller clicks "Accept Order".
     - Option C: Cash / UPI on delivery (COD) at construction site.
     - Option D: Two-step escrow (held by platform until delivery confirmation).
  2. Selected Payment Gateway provider: Razorpay, Cashfree, or PayU?
  3. How are seller payouts executed: manual bank transfer (NEFT/RTGS), automated route transfers (e.g., Razorpay Route), or platform payout batches?
- **Engineering Recommendation:** Expose an `IPaymentGateway` interface. For initial test phases, use a sandbox/mock adapter that simulates success/failure events. Do not collect real customer funds until legal and merchant accounts are approved.

### Decision 3: Cancellation, Demurrage & Refund Policy
- **Affected Specifications:** [`07-order-lifecycle-and-delivery-status.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/07-order-lifecycle-and-delivery-status.md), [`11-payments-refunds-and-reconciliation.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/11-payments-refunds-and-reconciliation.md)
- **Pending Questions:**
  1. What is the cancellation window for customers:
     - Before seller acceptance? (Yes, zero penalty)
     - After seller acceptance but before dispatch? (Penalty allowed?)
     - After vehicle dispatch? (Materials like sand/gravel in transit incur fuel and loading costs)
  2. Can dumped construction materials be returned? (Once tipped at a construction site, bulk materials cannot physically be "returned" into a tipper)
  3. Is there a demurrage fee if a tipper waits $> 1\text{ hour}$ at site due to customer delay?
  4. Who approves refunds: automated system rules or mandatory admin approval?
- **Engineering Recommendation:** In Phase 1, allow customer cancellation only while status is `PENDING_SELLER_RESPONSE`. Once `ACCEPTED`, cancellation requests trigger an operational support ticket rather than instant refund.

### Decision 4: Proof of Delivery (PoD) & Auto-Completion
- **Affected Specifications:** [`07-order-lifecycle-and-delivery-status.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/07-order-lifecycle-and-delivery-status.md), [`14-support-complaints-disputes.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/14-support-complaints-disputes.md)
- **Pending Questions:**
  1. What constitutes valid Proof of Delivery:
     - Customer 4-digit delivery confirmation OTP entered into seller's app?
     - Photo of dumped material and vehicle number plate at the site?
     - Signed delivery challan / weighbridge slip?
  2. If customer fails to confirm delivery, what is the auto-completion window (e.g., 24 hours, 48 hours)?
- **Engineering Recommendation:** Implement a 4-digit Delivery Confirmation OTP generated on customer app, verified by seller on delivery. Photo upload can serve as secondary proof.

### Decision 5: Seller Onboarding & KYC Verification Standards
- **Affected Specifications:** [`03-seller-onboarding-and-verification.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/03-seller-onboarding-and-verification.md), [`15-admin-dashboard-and-moderation.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/15-admin-dashboard-and-moderation.md)
- **Pending Questions:**
  1. Are both GSTIN and PAN strictly mandatory, or can small individual tractor operators onboard with PAN + Aadhaar?
  2. Is vehicle registration certificate (RC) verification required per vehicle, or does the seller self-attest vehicle capacity?
  3. Manual admin verification SLA (e.g., 24-48 business hours)?
- **Engineering Recommendation:** Support configurable KYC requirements in `seller_profiles` (`PENDING_REVIEW`, `APPROVED`, `REJECTED`). Store private documents in encrypted storage.

### Decision 6: Masked Calling & Cloud Telephony Provider
- **Affected Specifications:** [`08-contact-privacy-platform-messaging-masked-calling.md`](file:///Users/siddharth/Building_Material/Project_Documents/Feature/08-contact-privacy-platform-messaging-masked-calling.md)
- **Pending Questions:**
  1. Cloud telephony provider: Exotel, Twilio, or Knowlarity?
  2. Are voice calls recorded for dispute resolution, and is user consent obtained?
  3. Who absorbs the telecom call per-minute cost?
- **Engineering Recommendation:** Deliver in-app platform messaging first. Keep masked calling feature-flagged and disabled until telecom contracts and call compliance are approved.
