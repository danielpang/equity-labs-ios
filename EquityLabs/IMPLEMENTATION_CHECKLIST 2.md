# EquityLabs iOS - Implementation Checklist

Track your progress through each implementation phase.

## Phase 1: Foundation ✅ COMPLETED

### Project Setup ✅
- [x] Create project directory structure
- [x] Setup folder organization (App, Core, Services, Features, Shared)
- [x] Create README and documentation

### Core Models ✅
- [x] `Stock.swift` - Stock, StockLot, HistoricalDataPoint, TimeRange
- [x] `Portfolio.swift` - Portfolio, PortfolioSummary, Currency
- [x] `News.swift` - NewsArticle, NewsSentiment, CachedNews
- [x] `Subscription.swift` - SubscriptionTier, SubscriptionState
- [x] `User.swift` - User, UserPreferences

### Networking Layer ✅
- [x] `APIError.swift` - Error types and handling
- [x] `APIEndpoint.swift` - Endpoint definitions
- [x] `APIClient.swift` - URLSession wrapper with async/await
- [x] Retry logic with exponential backoff
- [x] Request/response logging

### Persistence Layer ✅
- [x] `PersistenceController.swift` - Core Data stack
- [x] `EquityLabs.xcdatamodeld` - Data model with entities
- [x] Background context support
- [x] Preview data for SwiftUI previews

### Utilities & Extensions ✅
- [x] `Constants.swift` - App constants
- [x] `Logger.swift` - Logging infrastructure
- [x] `Color+Theme.swift` - Theme colors
- [x] `Double+Currency.swift` - Currency formatting
- [x] `View+Extensions.swift` - SwiftUI extensions

### Shared Components ✅
- [x] `LoadingView.swift` - Loading indicator
- [x] `ErrorView.swift` - Error display with retry
- [x] `EmptyStateView.swift` - Empty state UI

### Basic UI ✅
- [x] `EquityLabsApp.swift` - App entry point
- [x] `SignInView.swift` - Authentication placeholder
- [x] `DashboardView.swift` - Main portfolio view
- [x] `DashboardViewModel.swift` - Dashboard logic
- [x] `PortfolioSummaryView.swift` - Summary card
- [x] `StockCardView.swift` - Stock list item
- [x] `StockDetailView.swift` - Detail placeholder
- [x] `AddStockView.swift` - Add stock placeholder
- [x] `SettingsView.swift` - Settings placeholder

### Authentication Foundation ✅
- [x] `KeychainManager.swift` - Secure storage
- [x] `AuthManager.swift` - Auth state management
- [x] `SubscriptionManager.swift` - IAP state management
- [x] `PortfolioService.swift` - Portfolio service placeholder

---

## Phase 2: Authentication 🔄 NEXT

### Clerk Integration
- [ ] Research Clerk iOS SDK availability
- [ ] Add Clerk SDK via SPM (if available)
- [ ] Configure Clerk credentials
- [ ] Implement fallback OAuth flow if SDK unavailable

### AuthService Implementation
- [ ] Create `AuthService.swift`
- [ ] Implement Clerk sign-in flow
- [ ] Implement Clerk sign-up flow
- [ ] Handle OAuth redirect callbacks
- [ ] Token refresh mechanism

### AuthManager Enhancement
- [ ] Complete `checkAuthState()` implementation
- [ ] Fetch user data from backend on sign-in
- [ ] Implement token refresh logic
- [ ] Add token expiration handling
- [ ] User profile caching

### Authentication Views
- [ ] Complete SignInView with Clerk UI
- [ ] Add sign-up flow
- [ ] Add forgot password flow
- [ ] Loading states during auth
- [ ] Error handling and display

### AuthViewModel
- [ ] Create `AuthViewModel.swift`
- [ ] Handle sign-in state
- [ ] Handle errors
- [ ] Form validation

### Testing
- [ ] Test sign-in flow
- [ ] Test sign-out flow
- [ ] Test token refresh
- [ ] Test error scenarios
- [ ] Verify keychain storage

---

## Phase 3: Portfolio Core 📋 TODO

### Portfolio Services
- [ ] Complete `PortfolioService.swift` implementation
- [ ] Create `PortfolioRepository.swift`
- [ ] Create `PortfolioSyncManager.swift`
- [ ] Implement `StockService.swift`
- [ ] Implement `ExchangeRateService.swift`

### Core Data Integration
- [ ] Create fetch requests
- [ ] Implement save operations
- [ ] Implement delete operations
- [ ] Sync logic (local ↔ API)
- [ ] Conflict resolution

### Dashboard Implementation
- [ ] Complete `DashboardViewModel.loadPortfolio()`
- [ ] Implement `refreshPrices()`
- [ ] Implement `deleteStock()`
- [ ] Handle loading states
- [ ] Handle error states
- [ ] Pull-to-refresh

### Add Stock Flow
- [ ] Create `AddStockViewModel.swift`
- [ ] Stock search with debouncing
- [ ] Display search results
- [ ] Add lot form (shares, price, date, currency)
- [ ] Form validation
- [ ] Save to repository

### Currency Support
- [ ] Fetch exchange rates
- [ ] Currency toggle in UI
- [ ] Convert portfolio values
- [ ] Persist currency preference
- [ ] Sync preference with backend

### Testing
- [ ] Test portfolio load
- [ ] Test add stock
- [ ] Test delete stock
- [ ] Test currency conversion
- [ ] Test offline mode
- [ ] Test sync conflicts

---

## Phase 4: Stock Detail & Charts 📊 TODO

### Stock Detail
- [ ] Create `StockDetailViewModel.swift`
- [ ] Implement tabs (Overview, Lots, News)
- [ ] Load stock historical data
- [ ] Display current price and stats
- [ ] Navigation from dashboard

### Charts
- [ ] Create `StockChartView.swift` with Swift Charts
- [ ] Time range selector (1D, 1W, 1M, etc.)
- [ ] Line chart with area fill
- [ ] Lot price indicators (horizontal lines)
- [ ] Average cost basis line
- [ ] Touch interactions
- [ ] Loading states

### Lot Management
- [ ] Create `StockLotsListView.swift`
- [ ] Display all lots for stock
- [ ] Edit lot form
- [ ] Delete lot confirmation
- [ ] Add new lot to existing stock
- [ ] Calculate average cost

### News Feed
- [ ] Create `NewsService.swift`
- [ ] Fetch news for symbol
- [ ] Display articles
- [ ] Sentiment badges (positive/neutral/negative)
- [ ] Article summarization
- [ ] Cache with 6-hour TTL
- [ ] Paywall for free users

### Testing
- [ ] Test chart interactions
- [ ] Test lot CRUD operations
- [ ] Test news loading
- [ ] Test sentiment display
- [ ] Test caching

---

## Phase 5: Subscription & IAP 💳 TODO

### App Store Connect Setup
- [ ] Create app in App Store Connect
- [ ] Create subscription product
- [ ] Configure pricing ($5.99/month)
- [ ] Create subscription group
- [ ] Add localizations

### StoreKit 2 Integration
- [ ] Create `StoreKitManager.swift`
- [ ] Load products
- [ ] Handle purchases
- [ ] Handle transaction updates
- [ ] Restore purchases
- [ ] Receipt validation

### Subscription Manager
- [ ] Complete `purchase()` implementation
- [ ] Transaction listener
- [ ] Sync IAP status with backend
- [ ] Enforce asset limits
- [ ] Handle subscription expiration

### Backend Integration
- [ ] Create backend endpoint `/api/subscriptions/validate-receipt`
- [ ] Implement receipt validation
- [ ] Update user tier in database
- [ ] Optional: App Store Server Notifications webhook

### Subscription Views
- [ ] Create `SubscriptionView.swift`
- [ ] Display current tier
- [ ] Upgrade button with IAP flow
- [ ] Feature comparison
- [ ] Manage subscription link
- [ ] Paywall for premium features

### Testing
- [ ] Test purchase flow (sandbox)
- [ ] Test restore purchases
- [ ] Test subscription expiration
- [ ] Test feature unlocking
- [ ] Test backend sync

---

## Phase 6: Settings & Preferences ⚙️ TODO

### Settings Implementation
- [ ] Create `SettingsViewModel.swift`
- [ ] Load user preferences
- [ ] Currency toggle
- [ ] Notification settings
- [ ] Background refresh toggle
- [ ] Default chart time range

### Preferences API
- [ ] Implement GET `/api/preferences`
- [ ] Implement PATCH `/api/preferences`
- [ ] Sync on app launch
- [ ] Sync on preference change
- [ ] Offline queue

### Settings Views
- [ ] Complete `SettingsView.swift`
- [ ] Subscription status section
- [ ] Preferences section
- [ ] About section
- [ ] Sign out button
- [ ] App version display

### Testing
- [ ] Test preference changes
- [ ] Test sync with backend
- [ ] Test offline mode
- [ ] Test sign out

---

## Phase 7: Background Tasks & Offline 🔄 TODO

### Background Tasks
- [ ] Create `BackgroundTaskManager.swift`
- [ ] Register BGTaskScheduler identifiers
- [ ] Implement refresh task (15-min intervals)
- [ ] Implement sync task (daily)
- [ ] Handle task expiration
- [ ] Schedule tasks

### Offline Support
- [ ] Network reachability monitoring
- [ ] Offline indicator in UI
- [ ] Queue mutations for sync
- [ ] Sync when reconnected
- [ ] Show cached data offline
- [ ] Conflict resolution

### Data Sync
- [ ] Full portfolio sync
- [ ] Price updates
- [ ] News updates
- [ ] Preference sync
- [ ] Last sync timestamp

### Testing
- [ ] Test background refresh
- [ ] Test offline mode
- [ ] Test reconnection
- [ ] Test conflict resolution
- [ ] Test battery impact

---

## Phase 8: Polish & Testing 🎨 TODO

### UI/UX Polish
- [ ] Dark theme colors
- [ ] Smooth animations
- [ ] Haptic feedback
- [ ] Loading skeletons
- [ ] Error states with retry
- [ ] Empty states with illustrations
- [ ] Accessibility labels
- [ ] Dynamic Type support
- [ ] VoiceOver support

### Unit Testing
- [ ] ViewModel tests
- [ ] Service layer tests
- [ ] Repository tests
- [ ] Currency conversion tests
- [ ] Date formatting tests
- [ ] Target 70%+ coverage

### UI Testing
- [ ] Sign-in flow test
- [ ] Add stock test
- [ ] Delete stock test
- [ ] Purchase flow test
- [ ] Settings test
- [ ] Offline scenario test

### Performance
- [ ] Launch time optimization
- [ ] Memory profiling (Instruments)
- [ ] Network usage monitoring
- [ ] Battery impact testing
- [ ] Reduce app size

### Bug Fixes
- [ ] Fix all crashes
- [ ] Handle edge cases
- [ ] Input validation
- [ ] Error recovery
- [ ] Race conditions

---

## Phase 9: Launch Prep 🚀 TODO

### App Store Assets
- [ ] Design app icon (1024x1024)
- [ ] iPhone screenshots (6.7", 6.5", 5.5")
- [ ] iPad screenshots (if supporting)
- [ ] App preview video (optional)
- [ ] App Store description
- [ ] Keywords for ASO
- [ ] Promotional text

### Metadata
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Marketing URL
- [ ] App category
- [ ] Age rating
- [ ] Copyright info
- [ ] Version release notes

### TestFlight
- [ ] Archive app
- [ ] Upload to TestFlight
- [ ] Internal testing
- [ ] Fix critical bugs
- [ ] External beta (optional)
- [ ] Gather feedback

### App Store Submission
- [ ] Complete App Store Connect form
- [ ] Add test account credentials
- [ ] Submit for review
- [ ] Respond to review feedback
- [ ] App approval
- [ ] Release to App Store

---

## Post-Launch TODO

### Monitoring
- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Track IAP conversion
- [ ] Track engagement metrics
- [ ] Monitor API errors

### Improvements
- [ ] Fix reported bugs
- [ ] Performance improvements
- [ ] Feature requests
- [ ] Version 1.1 planning

---

## Progress Summary

- ✅ **Phase 1: Foundation** - COMPLETED
- 🔄 **Phase 2: Authentication** - NEXT (0/6 sections)
- 📋 **Phase 3: Portfolio Core** - TODO (0/6 sections)
- 📊 **Phase 4: Stock Detail & Charts** - TODO (0/4 sections)
- 💳 **Phase 5: Subscription & IAP** - TODO (0/5 sections)
- ⚙️ **Phase 6: Settings** - TODO (0/3 sections)
- 🔄 **Phase 7: Background Tasks** - TODO (0/3 sections)
- 🎨 **Phase 8: Polish & Testing** - TODO (0/5 sections)
- 🚀 **Phase 9: Launch Prep** - TODO (0/4 sections)

**Overall Completion**: ~11% (Phase 1 of 9)

**Estimated Time Remaining**: 3-4 weeks full-time

---

## Notes

- Check off items as you complete them
- Add notes about blockers or decisions
- Update progress summary regularly
- Use this as your daily reference

**Last Updated**: 2026-02-01
