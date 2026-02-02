# EquityLabs iOS

Native iOS app for EquityLabs portfolio tracking platform built with SwiftUI.

## Overview

EquityLabs iOS is a native iOS application that provides real-time stock portfolio tracking, interactive charts, AI-powered news sentiment analysis, and subscription management through In-App Purchases.

## Features

- **Portfolio Management**: Track multiple stocks with detailed lot-level management
- **Real-time Prices**: Live stock prices with historical data
- **Interactive Charts**: Swift Charts with multiple time ranges (1D, 1W, 1M, 3M, 6M, 1Y, 5Y, 10Y)
- **News Sentiment**: AI-powered sentiment analysis for news articles (Premium)
- **Currency Support**: USD and CAD with automatic conversion
- **Offline Support**: Core Data persistence with cloud sync
- **Background Updates**: Automatic price refreshes via BGTaskScheduler
- **Native IAP**: StoreKit 2 subscription management

## Requirements

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+
- **Deployment Target**: iOS 17.0

## Project Structure

```
EquityLabs/
├── App/                    # App entry point
├── Core/                   # Core models, networking, persistence
├── Services/              # Business logic services
├── Features/              # Feature modules (MVVM)
├── Shared/                # Shared components, extensions, utilities
└── Resources/             # Assets, localization
```

## Setup Instructions

### 1. Create Xcode Project

Since the project structure has been created manually, you need to create the Xcode project:

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Configure:
   - Product Name: `EquityLabs`
   - Bundle Identifier: `com.equitylabs.ios`
   - Interface: SwiftUI
   - Language: Swift
   - Include Tests: Yes
5. Save to `/Users/dpang/projects/equity-labs-ios`

### 2. Add Source Files

Drag the following directories from Finder into your Xcode project:

1. `EquityLabs/` folder (select "Create groups")
2. Ensure all `.swift` files are added to the target

### 3. Configure Core Data

1. The `.xcdatamodeld` file should be automatically recognized
2. If not, add it manually: File → Add Files to "EquityLabs"
3. Select "EquityLabs.xcdatamodeld" from `Core/Persistence/`

### 4. Update Info.plist

Add the following keys to your `Info.plist`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.equitylabs.refresh</string>
    <string>com.equitylabs.sync</string>
</array>
<key>NSUserTrackingUsageDescription</key>
<string>We use analytics to improve your experience</string>
```

### 5. Configure Capabilities

In Xcode project settings, enable:
- Background Modes → Background fetch
- Background Modes → Background processing
- In-App Purchase

### 6. Add Dependencies (Optional)

If using Clerk SDK, add via Swift Package Manager:
1. File → Add Packages
2. Enter package URL (when available)

### 7. Update API Base URL

Edit `Core/Networking/APIEndpoint.swift`:
```swift
var baseURL: String {
    return "https://your-actual-backend-url.com"
}
```

Also update `Shared/Utilities/Constants.swift`:
```swift
enum API {
    static let baseURL = "https://your-actual-backend-url.com"
}
```

### 8. Configure App Store Connect

1. Create app in App Store Connect
2. Create In-App Purchase product:
   - Product ID: `com.equitylabs.subscription.monthly`
   - Type: Auto-renewable subscription
   - Price: $5.99 USD

### 9. Add Assets

Create the following in `Assets.xcassets`:
- AppIcon (1024x1024)
- BrandPrimary (Color Set)
- BrandSecondary (Color Set)

## Architecture

### MVVM + Repository Pattern

- **Models**: Domain models in `Core/Models/`
- **ViewModels**: `@MainActor` classes with `@Published` properties
- **Views**: SwiftUI declarative UI
- **Services**: Protocol-based business logic
- **Repository**: Data layer abstraction (network + persistence)

### Data Flow

```
View → ViewModel → Service → Repository → [Network/Core Data]
                                            ↓
View ← ViewModel ← @Published ← Repository ← Data
```

## Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)
- [x] Project structure
- [x] Core models (Stock, Portfolio, News, Subscription, User)
- [x] Networking layer (APIClient, APIEndpoint, APIError)
- [x] Core Data setup (PersistenceController, data model)
- [x] Shared utilities and extensions
- [x] Common UI components

### 🚧 Next Steps

#### Phase 2: Authentication
- [ ] Implement KeychainManager
- [ ] Create AuthService with Clerk integration
- [ ] Build AuthManager (EnvironmentObject)
- [ ] Create SignInView
- [ ] Configure app entry point

#### Phase 3: Portfolio Core
- [ ] Implement PortfolioService
- [ ] Create PortfolioRepository
- [ ] Build DashboardViewModel & View
- [ ] Implement AddStockView
- [ ] Currency conversion

#### Phase 4: Stock Detail & Charts
- [ ] StockDetailView with tabs
- [ ] Swift Charts implementation
- [ ] Lot management
- [ ] News feed integration

#### Phase 5: Subscription & IAP
- [ ] StoreKit 2 integration
- [ ] SubscriptionManager
- [ ] Purchase flow
- [ ] Backend receipt validation

#### Phase 6: Settings
- [ ] SettingsView
- [ ] Preferences sync
- [ ] User profile

#### Phase 7: Background Tasks
- [ ] BGTaskScheduler setup
- [ ] Price update task
- [ ] Sync task
- [ ] Offline queue

#### Phase 8: Polish & Testing
- [ ] UI/UX refinement
- [ ] Unit tests
- [ ] UI tests
- [ ] Performance optimization

#### Phase 9: Launch
- [ ] App Store assets
- [ ] TestFlight beta
- [ ] App Store submission

## API Integration

The app integrates with the existing Next.js backend:

### Endpoints
- `GET /api/stocks/[symbol]` - Stock data with historical prices
- `GET /api/stocks/search?q=query` - Search stocks
- `GET /api/exchange-rate` - USD/CAD rate
- `GET /api/portfolio` - Load portfolio
- `POST /api/portfolio` - Save portfolio
- `GET /api/news/[symbol]` - News with sentiment
- `POST /api/news/summarize` - Summarize article
- `GET /api/preferences` - Load preferences
- `PATCH /api/preferences` - Update preferences
- `POST /api/subscriptions/validate-receipt` - Validate Apple receipt (TO BE IMPLEMENTED)

### Authentication
All requests include Bearer token in Authorization header:
```
Authorization: Bearer <clerk-session-token>
```

## Testing

### Unit Tests
```bash
# Run from Xcode
Cmd + U
```

### UI Tests
```bash
# Run from Xcode
Cmd + U (with UI test target selected)
```

## Building

### Debug Build
```bash
# From Xcode
Cmd + R
```

### Release Build
```bash
# Archive for App Store
Product → Archive
```

## Troubleshooting

### Core Data Issues
- Delete app from simulator
- Clean build folder (Cmd + Shift + K)
- Reset simulator

### Network Issues
- Check base URL in `APIEndpoint.swift`
- Verify backend is running
- Check auth token in Keychain

### Build Errors
- Update Xcode to latest version
- Clean derived data: `~/Library/Developer/Xcode/DerivedData/`
- Restart Xcode

## Contributing

This is a single-developer project. For major changes, create a feature branch.

## License

Proprietary - All rights reserved

## Support

For issues, contact support@equitylabs.com

---

**Current Status**: Foundation complete, ready for Phase 2 (Authentication)
**Estimated Completion**: 3-4 weeks with full-time focus
**Last Updated**: 2026-02-01
