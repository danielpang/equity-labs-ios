# iOS Subscription Flow — Sequence Diagram

> See the rendered diagram: [`ios-subscription-flow.png`](./ios-subscription-flow.png)

![iOS Subscription Flow](./ios-subscription-flow.png)

---

## Flow 1: iOS In-App Purchase

```
User ──▶ iOS App ──▶ StoreKit ──▶ App Store ──▶ Backend ──▶ Apple ──▶ MongoDB + Clerk
```

1. User taps **Subscribe** in iOS app
2. `SubscriptionManager.purchase()` calls `Product.purchase()` via StoreKit
3. StoreKit processes payment with the App Store
4. On success, iOS calls `transaction.finish()`
5. iOS reads the App Store receipt from `Bundle.main.appStoreReceiptURL`
6. iOS sends receipt to backend:
   ```
   POST /api/subscriptions/validate-ios-receipt
   { receiptData: "<base64>", productId: "com.equitylabs.premium.monthly" }
   ```
7. Backend verifies receipt with Apple servers (`verifyAppleReceipt`)
8. Backend validates bundle ID and extracts subscription info
9. Backend updates **MongoDB**:
   ```
   tier: "paid"
   subscriptionMethod: "app_store_subscription"
   appleOriginalTransactionId, appleProductId, appleEnvironment, ...
   ```
10. Backend updates **Clerk** publicMetadata:
    ```
    tier: "paid"
    subscriptionMethod: "app_store_subscription"
    ```
11. Backend responds to iOS:
    ```json
    { "isValid": true, "expiresAt": "2026-03-08T...", "tier": "paid", "message": "Subscription activated" }
    ```
12. iOS reloads subscription state from StoreKit `Transaction.currentEntitlements`
13. `subscriptionState` set to `.paid` — premium features unlocked

---

## Flow 2: Apple Server-to-Server Webhooks

```
App Store ──▶ Backend ──▶ MongoDB + Clerk
```

Apple sends async notifications to `POST /api/webhooks/apple` for lifecycle events:

| Notification | Action |
|---|---|
| **SUBSCRIBED** | Set `tier: "paid"`, `subscriptionMethod: "app_store_subscription"` |
| **DID_RENEW** | Update `appleExpiresDate`, keep paid |
| **DID_FAIL_TO_RENEW** | Keep paid during grace/billing retry |
| **EXPIRED** / **GRACE_PERIOD_EXPIRED** | Downgrade to `tier: "free"`, `subscriptionMethod: null`, trim stocks |
| **REFUND** / **REVOKE** | Immediate downgrade to `tier: "free"`, `subscriptionMethod: null`, trim stocks |

All webhook responses return `200 { received: true }` to prevent retry storms.

---

## Flow 3: Cross-Platform Sync — iOS Sees Web Subscription

```
iOS App ──▶ Backend ──▶ MongoDB ──▶ iOS App
```

1. User opens iOS app (previously subscribed via Stripe on web)
2. `PortfolioService.loadPortfolio()` calls `GET /api/portfolio`
3. Backend returns:
   ```json
   { "stocks": {...}, "tier": "paid", "subscriptionMethod": "stripe" }
   ```
4. iOS decodes response as `Portfolio` struct (`subscriptionMethod` is safely ignored)
5. `applyBackendTier("paid")` upgrades local `subscriptionState` to `.paid`
6. Premium features unlocked on iOS (unlimited stocks, AI sentiment, etc.)

---

## Flow 4: Cross-Platform Sync — Web Sees iOS Subscription

```
Web Frontend ──▶ Clerk ──▶ SubscriptionContext ──▶ AppHeader
```

1. User opens web app (previously subscribed via App Store on iOS)
2. `SubscriptionContext` reads Clerk `publicMetadata`:
   ```
   tier: "paid", subscriptionMethod: "app_store_subscription"
   ```
3. `AppHeader` renders the Premium badge
4. Since `subscriptionMethod === "app_store_subscription"`, the **Manage Subscription** button is hidden (Stripe portal doesn't apply to App Store subscribers)

---

## Key Data Contracts

### iOS → Backend (Receipt Validation Request)
```swift
struct ReceiptValidationRequest: Codable {
    let receiptData: String    // base64-encoded App Store receipt
    let productId: String      // e.g. "com.equitylabs.premium.monthly"
}
```

### Backend → iOS (Receipt Validation Response)
```swift
struct ReceiptValidationResponse: Codable {
    let isValid: Bool          // true if receipt is valid and subscription active
    let expiresAt: String?     // ISO 8601 expiration date
    let tier: SubscriptionTier // "free" | "paid"
    let message: String?       // Human-readable status message
}
```

### Backend → iOS (Portfolio GET Response)
```typescript
{
  stocks: Record<string, Stock>,   // decoded by iOS as [Stock] or {id: Stock}
  lastSyncedAt: Date,
  tier: "free" | "paid",
  subscriptionMethod: "stripe" | "app_store_subscription" | null
}
```

### Shared State (MongoDB + Clerk)
```typescript
{
  tier: "free" | "paid",
  subscriptionMethod: "stripe" | "app_store_subscription" | null,
  // Stripe fields (web)
  stripeCustomerId?, stripeSubscriptionId?, subscriptionStatus?,
  // Apple fields (iOS)
  appleOriginalTransactionId?, appleProductId?, appleEnvironment?,
  appleSubscriptionStatus?, appleExpiresDate?, appleAutoRenewStatus?
}
```

---

## Source Files

| Component | File |
|---|---|
| iOS purchase + receipt send | `equity-labs-ios/.../SubscriptionManager.swift` |
| iOS portfolio load + tier sync | `equity-labs-ios/.../PortfolioService.swift` |
| iOS data models | `equity-labs-ios/.../Models/Subscription.swift` |
| iOS API routes | `equity-labs-ios/.../Networking/APIEndpoint.swift` |
| Backend receipt validation | `equity-labs/app/api/subscriptions/validate-ios-receipt/route.ts` |
| Backend Apple webhook | `equity-labs/app/api/webhooks/apple/route.ts` |
| Backend Stripe webhook | `equity-labs/app/api/webhooks/stripe/route.ts` |
| Backend portfolio API | `equity-labs/app/api/portfolio/route.ts` |
| Web subscription context | `equity-labs/components/SubscriptionContext.tsx` |
| Web header (manage button) | `equity-labs/components/AppHeader.tsx` |
| Shared types | `equity-labs/types/subscription.ts` |
