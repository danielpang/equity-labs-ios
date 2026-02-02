# EquityLabs iOS - Quick Start Guide

Get up and running in 15 minutes.

## Prerequisites

- Mac with Xcode 15.0+
- Apple Developer Account (free tier OK for simulator)
- 15 minutes of time

## Step 1: Open Xcode (1 min)

1. Launch **Xcode**
2. File → New → Project

## Step 2: Create Project (2 min)

1. **Choose template**: iOS → App
2. **Configure**:
   - Product Name: `EquityLabs`
   - Bundle ID: `com.equitylabs.ios`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **Core Data** ✓
   - Include Tests: ✓
3. **Save to**: `/Users/dpang/projects/equity-labs-ios`
4. Click "Create"

## Step 3: Delete Default Files (1 min)

In Xcode project navigator, **delete** (Move to Trash):
- ContentView.swift
- EquityLabsApp.swift
- Persistence.swift
- EquityLabs.xcdatamodeld

## Step 4: Add Source Files (2 min)

1. Open **Finder** → Navigate to `/Users/dpang/projects/equity-labs-ios`
2. **Drag** the `EquityLabs` folder into Xcode project navigator
3. In dialog:
   - ✅ Create groups
   - ✅ Add to target: EquityLabs
   - ⬜ Copy items (unchecked)
4. Click "Finish"

## Step 5: Configure Capabilities (2 min)

1. Select **project** in navigator (top item)
2. Select **"EquityLabs" target**
3. **Signing & Capabilities** tab:
   - Enable "Automatically manage signing"
   - Select your Team
   - Click "+ Capability"
   - Add "In-App Purchase"
   - Add "Background Modes"
     - ✓ Background fetch
     - ✓ Background processing

## Step 6: Edit Info.plist (2 min)

Select `Info.plist` → Right-click → Open As → Source Code

Add before `</dict>`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.equitylabs.refresh</string>
    <string>com.equitylabs.sync</string>
</array>
```

## Step 7: Add App Icon (2 min)

1. Select `Assets.xcassets`
2. Right-click → App Icons & Launch Images → New iOS App Icon
3. Drag your 1024x1024 icon (or use placeholder)

## Step 8: Add Colors (1 min)

In `Assets.xcassets`:
1. Right-click → Color Set → New Color Set
   - Name: `BrandPrimary`
   - Set to blue: #007AFF
2. Create another Color Set
   - Name: `BrandSecondary`
   - Set to purple: #5856D6

## Step 9: Update API URL (1 min)

**File**: `Core/Networking/APIEndpoint.swift`

Change line ~29:
```swift
var baseURL: String {
    return "https://your-actual-backend.com" // Update this!
}
```

**File**: `Shared/Utilities/Constants.swift`

Change line ~8:
```swift
static let baseURL = "https://your-actual-backend.com" // Update this!
```

## Step 10: Build & Run (1 min)

1. Select simulator: **iPhone 15 Pro**
2. Press **⌘R** (or click ▶️ Play button)
3. Wait for build...
4. App launches! 🎉

## What You Should See

1. **Sign In Screen**
   - Blue/purple gradient background
   - "EquityLabs" title
   - "Sign In with Clerk" button

2. **Tap "Sign In with Clerk"**
   - Dashboard appears (demo mode)
   - "No Stocks Yet" empty state
   - "Add Stock" button
   - Settings gear icon

3. **Tap Settings**
   - Current plan: Free
   - Sign out button

## Troubleshooting

### Build Errors

**"Cannot find type 'Stock'"**
- Clean build: ⌘⇧K
- Rebuild: ⌘B

**"Missing Core Data model"**
- Check that `.xcdatamodeld` folder is in project
- Verify Target Membership is checked

**"Entry point not found"**
- Ensure only one `@main` attribute
- Should be in `App/EquityLabsApp.swift`

### Runtime Crashes

**"Failed to load Core Data stack"**
- Core Data model not added to target
- Add `.xcdatamodeld` folder to project

**"Invalid URL"**
- Update baseURL in Step 9
- Check for typos

### App Not Launching

**Black screen**
- Check Console for errors
- Verify Info.plist is valid XML

**Stuck on loading**
- This is expected (demo mode has no data)
- Should show empty state

## Next Steps

### Option A: Continue Implementation

Follow `IMPLEMENTATION_CHECKLIST.md` for Phase 2:
- Implement Clerk authentication
- Connect to real backend
- Add portfolio features

### Option B: Explore the Code

- `App/EquityLabsApp.swift` - App entry point
- `Features/Dashboard/Views/DashboardView.swift` - Main screen
- `Core/Models/Stock.swift` - Data models
- `Core/Networking/APIClient.swift` - Network layer

### Option C: Test Features

Try these now:
- ✅ Sign in (demo mode)
- ✅ View empty dashboard
- ✅ Open settings
- ✅ Sign out
- ✅ Pull to refresh

## What Works vs What Doesn't

### ✅ Works Now
- App launches
- Navigation between screens
- Empty states
- UI components render
- Dark mode support

### ❌ Not Yet Implemented
- Real authentication
- Add/delete stocks
- API calls
- Charts
- News feed
- In-app purchases

See `PHASE1_COMPLETE.md` for full details.

## File Structure

```
EquityLabs/
├── App/                    # App entry point
├── Core/                   # Models, networking, persistence
│   ├── Models/            # Stock, Portfolio, News, etc.
│   ├── Networking/        # APIClient, endpoints
│   └── Persistence/       # Core Data stack
├── Services/              # Business logic
│   ├── Authentication/    # Auth, keychain
│   ├── Portfolio/         # Portfolio CRUD
│   └── Subscription/      # IAP management
├── Features/              # Feature screens
│   ├── Dashboard/         # Main portfolio view
│   ├── Authentication/    # Sign in
│   ├── Settings/          # Settings
│   └── ...
└── Shared/                # Reusable UI & utilities
    ├── Components/        # Loading, Error, Empty states
    ├── Extensions/        # Color, Double, View helpers
    └── Utilities/         # Constants, Logger
```

## Common Questions

**Q: Can I run on my iPhone?**
A: Yes! Connect your iPhone, select it as target, and run. May need to adjust signing settings.

**Q: Do I need a paid Apple Developer account?**
A: Not for simulator testing. Needed for device testing and App Store.

**Q: Where's the backend code?**
A: This is just the iOS app. Backend is separate (existing Next.js app).

**Q: Can I use this as a template?**
A: Yes! The architecture works for any CRUD app with subscriptions.

**Q: How do I add features?**
A: Follow `IMPLEMENTATION_CHECKLIST.md` for guided implementation.

## Resources

- `README.md` - Project overview
- `SETUP.md` - Detailed setup instructions
- `IMPLEMENTATION_CHECKLIST.md` - What to build next
- `PHASE1_COMPLETE.md` - What's been built

## Getting Help

1. Check `SETUP.md` troubleshooting section
2. Review code comments
3. Check Xcode console for errors
4. Rebuild from clean (⌘⇧K then ⌘B)

## Success!

If you can build and run the app, you're ready to start Phase 2!

**Time to complete**: ~15 minutes ✅

**Next**: Read `IMPLEMENTATION_CHECKLIST.md` → Start Phase 2

---

**Happy coding!** 🚀
