# 04. Next.js & TypeScript Frontend Architecture (`04_nextjs_frontend_architecture.md`)

## 1. Frontend Architectural Overview
The BUILD MATE web application (`src/web`) is built with **Next.js (App Router)**, **React 18+**, **TypeScript 5.x**, and **Tailwind CSS**. It is engineered specifically for Indian construction buyers, site engineers, and local material suppliers who predominantly access the platform on mid-range Android smartphones under variable 4G/5G field connectivity, while also offering a dense multi-column operational console for desktop Admin moderators.

---

## 2. Next.js App Router Directory Structure

    src/web/
    ├── public/
    │   ├── icons/                        # Vehicle & material SVG icons (Tipper, Tractor, Sand, Stone)
    │   └── images/                       # Optimized WebP fallback placeholders
    ├── src/
    │   ├── app/
    │   │   ├── (public)/                 # Unauthenticated & SEO-indexed marketplace routes
    │   │   │   ├── page.tsx              # Landing page & category quick-selector
    │   │   │   ├── materials/
    │   │   │   │   ├── page.tsx          # Search & filter material listings (SSR + Client filters)
    │   │   │   │   └── [listingId]/
    │   │   │   │       └── page.tsx      # Public listing detail (Redacted seller contact)
    │   │   │   └── login/
    │   │   │       └── page.tsx          # Phone number + OTP authentication flow
    │   │   ├── (customer)/               # Protected Customer routes (Role: CUSTOMER)
    │   │   │   ├── checkout/[listingId]/
    │   │   │   │   └── page.tsx          # Single-seller load quote & order submission
    │   │   │   ├── orders/
    │   │   │   │   ├── page.tsx          # Customer order history list
    │   │   │   │   └── [orderId]/
    │   │   │   │       └── page.tsx      # Live delivery tracker, masked call & order chat
    │   │   │   └── addresses/
    │   │   │       └── page.tsx          # Saved site delivery addresses CRUD
    │   │   ├── (seller)/                 # Protected Seller Hub routes (Role: SELLER)
    │   │   │   ├── seller/
    │   │   │   │   ├── onboarding/       # KYC document upload, yard locality & serviceable pincodes
    │   │   │   │   ├── listings/         # Create/edit bundled material + vehicle load listings
    │   │   │   │   └── orders/           # Incoming order queue (Accept/Reject/Dispatch/Deliver)
    │   │   ├── (admin)/                  # Protected Admin Console routes (Role: ADMIN)
    │   │   │   └── admin/
    │   │   │       ├── sellers/          # Seller KYC & document verification queue
    │   │   │       ├── listings/         # Listing moderation & anti-bypass review
    │   │   │       ├── disputes/         # Support tickets & order dispute resolution
    │   │   │       └── analytics/        # GMV, commission ledger & CSV exports
    │   │   ├── error.tsx                 # Route-level error boundary
    │   │   ├── layout.tsx                # Root layout, fonts, QueryProvider, ToastProvider
    │   │   └── not-found.tsx             # Custom 404 page
    │   ├── components/
    │   │   ├── ui/                       # Atomic primitives (Button, Badge, Card, Sheet, Dialog)
    │   │   ├── layout/                   # MobileBottomNav, TopHeader, PincodeSelectorBar
    │   │   ├── catalog/                  # MaterialListingCard, VehicleCapacityBadge, FilterSheet
    │   │   ├── orders/                   # OrderStatusStepper, PriceBreakdownCard, MaskedCallButton
    │   │   └── seller/                   # IncomingOrderActionCard, ListingForm
    │   ├── lib/
    │   │   ├── api-client.ts             # Centralized typed fetch wrapper with cookie credentials
    │   │   ├── currency.ts               # Paise-to-INR formatting utilities
    │   │   └── utils.ts                  # Tailwind class merger (cn)
    │   ├── schemas/                      # Zod validation schemas (with anti-bypass regex)
    │   ├── services/                     # Domain API services & TanStack Query hooks
    │   ├── stores/                       # Zustand stores (active pincode, UI drawers)
    │   ├── types/                        # Shared TypeScript contracts & OpenAPI generated types
    │   └── middleware.ts                 # Edge route guard for role-based redirection
    ├── next.config.mjs
    ├── tailwind.config.ts
    └── tsconfig.json

---

## 3. Server Components (RSC) vs. Client Components Separation

### 3.1 Server Component Usage (Default)
* **SEO & Initial Catalog Load:** `(public)/page.tsx`, `(public)/materials/page.tsx`, and `(public)/materials/[listingId]/page.tsx` execute as React Server Components. They fetch public, contact-redacted material listings directly from the ASP.NET Core API (`GET /api/v1/listings`) and stream pre-rendered HTML with complete OpenGraph and JSON-LD structured metadata.
* **Zero Secret Exposure:** Server-only environment variables (`INTERNAL_API_BASE_URL`) remain strictly on the server and are never bundled into client JavaScript.

### 3.2 Client Component Usage (`'use client'`)
Add `'use client'` only to interactive leaf components:
* `OtpLoginForm.tsx` (manages countdown timer and 6-digit OTP input state).
* `MaterialFilterBar.tsx` (manages category pills, pincode selector, vehicle type filters, and price sorting via URL `useSearchParams`).
* `OrderActionPanel.tsx` (handles Seller Accept/Reject/Dispatch/Mark-Delivered mutations with confirmation modals).
* `OrderChatTimeline.tsx` (manages order-linked messaging and anti-bypass input validation).

---

## 4. Financial Formatting & Currency Utility (`src/lib/currency.ts`)

Because the ASP.NET Core backend and PostgreSQL store and transmit all monetary figures as integer **paise** (`number` in TypeScript), the frontend uses a dedicated formatting utility to display Indian Rupees (`₹`) with Indian numbering grouping (`en-IN`):

    // src/lib/currency.ts

    /**
     * Converts integer paise (e.g., 1450000) to formatted INR string (e.g., "₹14,500")
     */
    export function formatPaiseToInr(
      amountInPaise: number,
      options: { showDecimals?: boolean } = {}
    ): string {
      const amountInRupees = amountInPaise / 100;
      return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        minimumFractionDigits: options.showDecimals ? 2 : 0,
        maximumFractionDigits: options.showDecimals ? 2 : 0,
      }).format(amountInRupees);
    }

    /**
     * Converts user-entered Rupee form input to exact integer paise for API submission
     */
    export function rupeesToPaise(rupees: number): number {
      return Math.round(rupees * 100);
    }

---

## 5. Tailwind CSS & Mobile-First Construction UX Design System

### 5.1 Outdoor Readability & Touch Targets
Construction site supervisors and truck/tipper owners often use the app outdoors in bright sunlight:
1. **High-Contrast Color Palette (`tailwind.config.ts`):**
   * **Primary Brand (Construction Amber/Orange):** `amber-600` (`#D97706`) with dark slate text (`slate-950`) for high visibility.
   * **Structural Neutral (Stone Slate):** `slate-900` (`#0F172A`) for headers and primary typography.
   * **Semantic Status Badges:**
     * `PENDING_SELLER_RESPONSE`: `bg-amber-100 text-amber-900 border-amber-300`
     * `ACCEPTED` / `IN_TRANSIT`: `bg-blue-100 text-blue-900 border-blue-300`
     * `DELIVERED`: `bg-emerald-100 text-emerald-900 border-emerald-300`
     * `REJECTED` / `CANCELLED` / `DISPUTED`: `bg-red-100 text-red-900 border-red-300`
2. **Minimum Touch Target Size:** Every interactive button, filter chip, and status toggle must have a minimum height of $48\text{ px}$ (`min-h-12`) to prevent mis-taps on mobile screens.

### 5.2 Standard `MaterialListingCard` Visual Hierarchy
Every listing card in search results must clearly display the bundled load proposition without exposing private seller contact details:
1. **Top Row:** Material Category Badge (`Black Stone 20mm`) + Verified Seller Badge (`Verified Supplier • Code: #SL-409`) + Yard Locality (`Hingna Road Area`).
2. **Middle Section:** Vehicle & Load Capacity Callout (`6-Wheel Tipper • 3 Brass Guaranteed Load`).
3. **Price Breakdown Box:**
   * All-Inclusive Load Price (`₹13,500 / load`) prominently displayed in `text-2xl font-bold`.
   * Explicit sub-caption: `Includes Material (₹11,000) + Delivery (₹2,500) to Pincode 440016`.
4. **Bottom Action Bar:** Primary CTA (`Get Instant Quote / Book Load`) + Lead Time (`Est. Delivery: Within 24 hrs`).