# 07. Frontend State Management & Data Fetching (`07_state_management_and_fetching.md`)

## 1. Frontend State Architecture Matrix
The BUILD MATE Next.js + TypeScript frontend strictly separates state into four distinct layers so server data is never duplicated inside global client stores:

| State Category | Technology | Scope & Examples | Persistence Mechanism |
| :--- | :--- | :--- | :--- |
| **1. Initial Server Render State** | Next.js Server Components (`async page.tsx`) | Public material category lists, initial SEO catalog listings | HTTP response stream + Next.js Server Cache |
| **2. Interactive Server Cache** | TanStack Query v5 (`@tanstack/react-query`) | Live order status tracking, seller incoming order queue, saved addresses | In-memory `QueryClient` with configurable `staleTime` |
| **3. URL & Filter State** | Next.js `useSearchParams` & `useRouter` | Active material category slug, vehicle filter, sort order, page number | Browser URL query string (`?category=black-stone&pincode=440015`) |
| **4. Global Client UI State** | Zustand (`src/stores/*`) | Active delivery pincode preference, mobile filter drawer open state | Memory + `localStorage` (`persist` middleware) |

---

## 2. Deterministic Query Key Factory (`src/services/query-keys.ts`)

All TanStack Query hooks must consume keys from a centralized factory to guarantee accurate cache invalidation across customer, seller, and admin views:

    // src/services/query-keys.ts
    import type { ListingSearchFilters, OrderFilterParams } from '@/types/api';

    export const buildMateKeys = {
      auth: {
        me: ['auth', 'me'] as const,
      },
      categories: {
        all: ['categories'] as const,
      },
      listings: {
        all: ['listings'] as const,
        publicSearch: (filters: ListingSearchFilters) =>
          ['listings', 'public-search', filters] as const,
        publicDetail: (listingId: string) =>
          ['listings', 'public-detail', listingId] as const,
        sellerMine: () => ['listings', 'seller-mine'] as const,
      },
      orders: {
        all: ['orders'] as const,
        customerList: (params: OrderFilterParams) =>
          ['orders', 'customer-list', params] as const,
        sellerQueue: (params: OrderFilterParams) =>
          ['orders', 'seller-queue', params] as const,
        detail: (orderId: string) => ['orders', 'detail', orderId] as const,
        messages: (orderId: string) => ['orders', 'messages', orderId] as const,
      },
      addresses: {
        mine: ['customer-addresses', 'mine'] as const,
      },
    };

---

## 3. Live Order Status Tracking & Conditional Polling

Construction buyers waiting for a seller to accept a bulk material load (`PENDING_SELLER_RESPONSE`) or tracking an active tipper truck (`DISPATCHED`) require automatic status updates without manually refreshing the browser.

    // src/services/use-order-detail.ts
    import { useQuery } from '@tanstack/react-query';
    import { apiFetch } from '@/lib/api-client';
    import { buildMateKeys } from './query-keys';
    import type { ApiResponse, OrderDetailDto } from '@/types/api';

    const ACTIVE_TRANSIT_STATUSES = new Set([
      'PENDING_SELLER_RESPONSE',
      'ACCEPTED',
      'DISPATCHED',
    ]);

    export function useOrderDetailQuery(orderId: string) {
      return useQuery({
        queryKey: buildMateKeys.orders.detail(orderId),
        queryFn: async () => {
          const res = await apiFetch<ApiResponse<OrderDetailDto>>(
            `/orders/${orderId}`
          );
          return res.data;
        },
        // Poll every 12 seconds while order is active; stop polling once terminal
        refetchInterval: (query) => {
          const currentStatus = query.state.data?.status;
          return currentStatus && ACTIVE_TRANSIT_STATUSES.has(currentStatus)
            ? 12_000
            : false;
        },
        staleTime: 5_000,
      });
    }

---

## 4. Optimistic UI Updates for Seller & Customer Mutations

When a Seller accepts or dispatches an order, or when a Customer switches their default site delivery address, the UI updates immediately using TanStack Query's `onMutate` optimistic snapshot pattern and rolls back automatically if the ASP.NET Core API returns an error:

    // src/services/use-seller-order-mutations.ts
    import { useMutation, useQueryClient } from '@tanstack/react-query';
    import { apiFetch } from '@/lib/api-client';
    import { buildMateKeys } from './query-keys';
    import type { AcceptOrderPayload, OrderDetailDto } from '@/types/api';

    export function useAcceptOrderMutation(orderId: string) {
      const queryClient = useQueryClient();
      const detailKey = buildMateKeys.orders.detail(orderId);

      return useMutation({
        mutationFn: (payload: AcceptOrderPayload) =>
          apiFetch(`/orders/${orderId}/accept`, {
            method: 'POST',
            body: JSON.stringify(payload),
          }),
        onMutate: async () => {
          await queryClient.cancelQueries({ queryKey: detailKey });
          const previousOrder = queryClient.getQueryData<OrderDetailDto>(detailKey);

          if (previousOrder) {
            queryClient.setQueryData<OrderDetailDto>(detailKey, {
              ...previousOrder,
              status: 'ACCEPTED',
              acceptedAtUtc: new Date().toISOString(),
            });
          }

          return { previousOrder };
        },
        onError: (_err, _variables, context) => {
          if (context?.previousOrder) {
            queryClient.setQueryData(detailKey, context.previousOrder);
          }
        },
        onSettled: () => {
          queryClient.invalidateQueries({ queryKey: detailKey });
          queryClient.invalidateQueries({ queryKey: buildMateKeys.orders.all });
        },
      });
    }

---

## 5. Idempotent Order Checkout Submission Pattern

To prevent accidental double-charging or duplicate tipper dispatches when a customer taps **"Confirm Order"** on a high-latency mobile connection:
1. Generate a deterministic `idempotencyKey` (`crypto.randomUUID()`) as soon as the checkout quote step mounts (`useRef(crypto.randomUUID())`).
2. Keep the same `idempotencyKey` across network retries for that checkout form instance.
3. Pass the key in the `Idempotency-Key` header to `POST /api/v1/orders`.

    // src/components/orders/CheckoutSubmitButton.tsx
    'use client';

    import { useRef } from 'react';
    import { useMutation } from '@tanstack/react-query';
    import { apiFetch } from '@/lib/api-client';
    import type { CreateOrderRequest, ApiResponse, OrderSummaryDto } from '@/types/api';

    export function useCreateOrderWithIdempotency() {
      const idempotencyKeyRef = useRef<string>(crypto.randomUUID());

      return useMutation({
        mutationFn: async (payload: CreateOrderRequest) => {
          const response = await apiFetch<ApiResponse<OrderSummaryDto>>('/orders', {
            method: 'POST',
            headers: {
              'Idempotency-Key': idempotencyKeyRef.current,
            },
            body: JSON.stringify(payload),
          });
          return response.data;
        },
        onSuccess: () => {
          // Rotate key only after order succeeds
          idempotencyKeyRef.current = crypto.randomUUID();
        },
      });
    }

---

## 6. Hyperlocal Pincode Context Store (`src/stores/locality-store.ts`)

Because material availability and bundled transport pricing depend on the customer's 6-digit delivery pin code, the active pin code and locality label are persisted in Zustand:

    // src/stores/locality-store.ts
    import { create } from 'zustand';
    import { persist } from 'zustand/middleware';

    interface LocalityState {
      pincode: string;
      localityName: string;
      setLocality: (pincode: string, localityName: string) => void;
    }

    export const useLocalityStore = create<LocalityState>()(
      persist(
        (set) => ({
          pincode: '440015',
          localityName: 'Pratap Nagar, Nagpur',
          setLocality: (pincode, localityName) => set({ pincode, localityName }),
        }),
        {
          name: 'bm-locality-storage',
        }
      )
    );