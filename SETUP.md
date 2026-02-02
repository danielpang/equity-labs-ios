# EquityLabs iOS - Setup Guide

This guide walks you through setting up the Xcode project from the generated source files.

## Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- Apple Developer Account (for device testing and App Store)
- Active EquityLabs backend API

## Step-by-Step Setup

### 1. Create New Xcode Project

1. **Open Xcode**

2. **Create new project**:
   - File → New → Project
   - Choose "iOS" platform
   - Select "App" template
   - Click "Next"

3. **Configure project**:
   - **Product Name**: `EquityLabs`
   - **Team**: Select your development team
   - **Organization Identifier**: `com.equitylabs` (or your domain)
   - **Bundle Identifier**: `com.equitylabs.ios`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: Core Data (checked)
   - **Include Tests**: Yes (checked)
   - Click "Next"

4. **Save project**:
   - Navigate to `/Users/dpang/projects/equity-labs-ios`
   - Click "Create"

### 2. Delete Generated Files

Xcode creates some default files we don't need:

1. In Xcode project navigator, delete these files (Move to Trash):
   - `ContentView.swift`
   - `EquityLabsApp.swift` (we have our own)
   - `Persistence.swift` (we have PersistenceController)
   - `EquityLabs.xcdatamodeld` (we have our own)

### 3. Add Source Files to Project

1. **Open Finder** and navigate to `/Users/dpang/projects/equity-labs-ios`

2. **Drag the `EquityLabs` folder** from Finder into Xcode project navigator:
   - Drop it on the project root
   - In dialog, ensure:
     - ✅ "Copy items if needed" (unchecked - files are already in place)
     - ✅ "Create groups" (selected)
     - ✅ "Add to targets: EquityLabs" (checked)
   - Click "Finish"

3. **Verify structure**: Your project should now show:
   ```
   EquityLabs/
   ├── App/
   ├── Core/
   ├── Services/
   ├── Features/
   ├── Shared/
   └── Resources/
   ```

### 4. Configure Build Settings

1. **Select project** in navigator (top item)
2. **Select "EquityLabs" target**
3. **General tab**:
   - **Deployment Target**: iOS 17.0
   - **Supported Destinations**: iPhone
   - **Status Bar Style**: Default

4. **Signing & Capabilities tab**:
   - Enable "Automatically manage signing"
   - Select your Team
   - Add capabilities:
     - Click "+ Capability"
     - Add "In-App Purchase"
     - Add "Background Modes"
       - Check "Background fetch"
       - Check "Background processing"

### 5. Configure Info.plist

1. **Select `Info.plist`** in project navigator
2. **Add keys** (right-click → Add Row):

   ```xml
   Key: BGTaskSchedulerPermittedIdentifiers
   Type: Array
   Items:
     - com.equitylabs.refresh (String)
     - com.equitylabs.sync (String)

   Key: NSUserTrackingUsageDescription
   Type: String
   Value: We use analytics to improve your experience
   ```

3. Or edit as **Source Code** and add:
   ```xml
   <key>BGTaskSchedulerPermittedIdentifiers</key>
   <array>
       <string>com.equitylabs.refresh</string>
       <string>com.equitylabs.sync</string>
   </array>
   <key>NSUserTrackingUsageDescription</key>
   <string>We use analytics to improve your experience</string>
   ```

### 6. Configure Assets

1. **Select `Assets.xcassets`** in project navigator

2. **Add App Icon**:
   - Right-click → App Icons & Launch Images → New iOS App Icon
   - Drag your 1024x1024 icon image

3. **Add Color Assets**:
   - Right-click → Color Set → New Color Set
   - Name: `BrandPrimary`
   - Set color values (e.g., Blue: #007AFF)

   - Create another Color Set
   - Name: `BrandSecondary`
   - Set color values (e.g., Purple: #5856D6)

### 7. Update API Configuration

1. **Open `Core/Networking/APIEndpoint.swift`**
2. **Update `baseURL`**:
   ```swift
   var baseURL: String {
       return "https://your-actual-backend.com" // Change this
   }
   ```

3. **Open `Shared/Utilities/Constants.swift`**
4. **Update API.baseURL**:
   ```swift
   enum API {
       static let baseURL = "https://your-actual-backend.com" // Change this
   }
   ```

### 8. Verify Core Data Model

1. **Select `EquityLabs.xcdatamodeld`** in project navigator
2. You should see the data model editor with entities:
   - StockEntity
   - StockLotEntity
   - HistoricalDataEntity
   - CachedNewsEntity

3. If not visible, ensure the file is added to target:
   - Select the file
   - Show File Inspector (⌥⌘1)
   - Check "EquityLabs" under Target Membership

### 9. Build and Run

1. **Select simulator**: iPhone 15 Pro (or any iOS 17+ device)

2. **Build** (⌘B):
   - Should complete without errors
   - Warnings are OK for now

3. **Run** (⌘R):
   - App should launch
   - You'll see the sign-in screen
   - Tap "Sign In with Clerk" to see dashboard (demo mode)

### 10. Troubleshooting

#### Build Errors

**"Cannot find type 'Stock' in scope"**
- Ensure all files in `Core/Models/` are added to target
- Clean build folder (⌘⇧K) and rebuild

**"Missing Core Data model"**
- Check that `EquityLabs.xcdatamodeld/EquityLabs.xcdatamodel/contents` exists
- Verify Target Membership is checked

**"Entry point not found"**
- Ensure `App/EquityLabsApp.swift` has `@main` attribute
- Check that it's the only file with `@main`

#### Runtime Errors

**"Failed to load Core Data stack"**
- The app will crash with this message if Core Data model is missing
- Solution: Add `.xcdatamodeld` folder to project

**"Invalid URL" API errors**
- Update the `baseURL` in `APIEndpoint.swift`
- Ensure backend is running and accessible

#### Preview Errors

**"Cannot preview in this file"**
- Some files may not preview initially
- Run the app first (⌘R) to generate Core Data classes
- Then try preview again

### 11. Optional: Add Dependencies

If you want to use Clerk SDK (for Phase 2):

1. **File → Add Package Dependencies**
2. Enter package URL (when Clerk iOS SDK is available)
3. Select version and add to target

For now, we'll use a custom OAuth implementation.

### 12. Next Steps

You now have a working foundation! The app currently:
- ✅ Launches successfully
- ✅ Shows sign-in screen
- ✅ Can navigate to dashboard (demo mode)
- ✅ Has all models and networking setup
- ✅ Has Core Data configured

Ready for **Phase 2: Authentication** implementation.

See `README.md` for the full implementation plan.

---

## Quick Reference

### Project Structure
```
equity-labs-ios/
├── EquityLabs.xcodeproj          # Xcode project
├── EquityLabs/                   # Source code
├── EquityLabsTests/              # Unit tests
├── EquityLabsUITests/            # UI tests
├── README.md                     # Project overview
└── SETUP.md                      # This file
```

### Key Files
- `App/EquityLabsApp.swift` - App entry point
- `Core/Networking/APIClient.swift` - Network layer
- `Core/Persistence/PersistenceController.swift` - Core Data
- `Services/Authentication/AuthManager.swift` - Auth state
- `Features/Dashboard/Views/DashboardView.swift` - Main screen

### Build Commands
- Build: ⌘B
- Run: ⌘R
- Test: ⌘U
- Clean: ⌘⇧K
- Archive: Product → Archive

### Common Issues
1. Missing imports → Add files to target
2. Preview crashes → Run app first (⌘R)
3. Core Data errors → Check model file
4. API errors → Update baseURL

---

**Need help?** Check troubleshooting section or contact support.
