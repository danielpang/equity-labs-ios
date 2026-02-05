# Clerk Authentication Setup Guide

This guide will help you configure Clerk authentication with Google and Apple OAuth providers.

## Prerequisites

- Xcode 15.0+
- Clerk account at https://clerk.com
- iOS 17.0+ deployment target

## Step 1: Get Your Clerk Publishable Key

1. Go to https://dashboard.clerk.com
2. Select your application
3. Navigate to **API Keys** in the left sidebar
4. Copy your **Publishable Key** (starts with `pk_test_` or `pk_live_`)

## Step 2: Configure Clerk Key in Xcode

### Option A: Environment Variable (Recommended for Development)

1. Open your Xcode project
2. Select the **EquityLabs** scheme (next to the run button)
3. Click **Edit Scheme...**
4. Select **Run** → **Arguments** tab
5. Under **Environment Variables**, click **+**
6. Add:
   - **Name**: `CLERK_PUBLISHABLE_KEY`
   - **Value**: Your publishable key from Step 1

### Option B: Info.plist (Alternative)

1. Open `Info.plist`
2. Add a new key:
   - **Key**: `CLERK_PUBLISHABLE_KEY`
   - **Type**: String
   - **Value**: Your publishable key

**⚠️ Warning**: Don't commit your publishable key to Git if using Info.plist!

## Step 3: Enable OAuth Providers in Clerk Dashboard

### Enable Google Sign-In

1. In Clerk Dashboard, go to **Configure** → **SSO Connections**
2. Click **Add connection**
3. Select **For all users**
4. Choose **Google** from the provider list
5. For **Development**: Use Clerk's shared credentials (enabled by default)
6. For **Production**: Toggle "Use custom credentials" and follow [Google OAuth Setup](https://clerk.com/docs/guides/configure/auth-strategies/social-connections/google)

### Enable Sign in with Apple

1. In Clerk Dashboard, go to **Configure** → **SSO Connections**
2. Click **Add connection**
3. Select **For all users**
4. Choose **Apple** from the provider list
5. Follow the [Apple OAuth Setup Guide](https://clerk.com/docs/guides/configure/auth-strategies/social-connections/apple)

## Step 4: Configure Associated Domains (Required for OAuth)

1. In Xcode, select your app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **Associated Domains**
4. Add your domain in this format:
   ```
   webcredentials:your-clerk-frontend-api-url
   ```

   Example:
   ```
   webcredentials:https://your-app.clerk.accounts.dev
   ```

## Step 5: Test Authentication

1. Build and run the app (⌘R)
2. You should see "Sign In with Clerk" button enabled
3. Tap the button to open the AuthView sheet
4. The AuthView will show:
   - **Email/Password** sign-in (always available)
   - **Google** button (if enabled in dashboard)
   - **Sign in with Apple** button (if enabled in dashboard)

## What AuthView Includes

Once configured, Clerk's AuthView automatically provides:

- ✅ Email/password authentication
- ✅ OAuth provider buttons (Google, Apple, etc.)
- ✅ Email verification flow
- ✅ Password reset flow
- ✅ Multi-factor authentication (if enabled)
- ✅ Beautiful, responsive UI
- ✅ Error handling and validation

## Troubleshooting

### "Clerk is not initialized" Error

**Problem**: Button is disabled with initialization message

**Solutions**:
1. Verify `CLERK_PUBLISHABLE_KEY` is set correctly in scheme environment variables
2. Check Console for error messages
3. Ensure key starts with `pk_test_` or `pk_live_`
4. Try cleaning build folder (⇧⌘K) and rebuilding

### AuthView Sheet is Empty

**Problem**: Sheet opens but shows nothing

**Solutions**:
1. Check Console logs for Clerk initialization errors
2. Verify your publishable key is valid
3. Ensure you have an active internet connection
4. Try using the demo mode button to test other functionality

### OAuth Buttons Don't Appear

**Problem**: Only email/password shows, no Google/Apple buttons

**Solutions**:
1. Confirm providers are enabled in Clerk Dashboard
2. Check that you've selected "For all users" when adding connections
3. Wait a few minutes for dashboard changes to propagate
4. Restart the app after enabling providers

### "Google OAuth 2.0 does not allow apps to use WebViews"

**Problem**: Google sign-in fails with WebView error

**Solution**: This is expected - Clerk iOS SDK uses native flows, not WebViews. If you see this error, it's from testing the wrong flow. Use Clerk's AuthView which handles this correctly.

## Testing OAuth in Simulator

- **Google OAuth**: Works in simulator
- **Sign in with Apple**: Requires a real device or Apple ID setup in simulator

## Demo Mode (For Testing Without Clerk)

If you need to test the app without setting up Clerk:

1. Tap **Continue as Demo** button
2. This creates a demo session without real authentication
3. Useful for testing UI and features during development

## Production Checklist

Before releasing to production:

- [ ] Use custom OAuth credentials (not Clerk's shared credentials)
- [ ] Switch to `pk_live_` publishable key
- [ ] Configure production redirect URIs
- [ ] Set up Associated Domains for your production domain
- [ ] Test OAuth flows on real devices
- [ ] Enable production mode in Google/Apple Developer consoles
- [ ] Add privacy policy and terms of service URLs

## Additional Resources

- [Clerk iOS SDK Documentation](https://clerk.com/docs/reference/ios/overview)
- [iOS Quickstart Guide](https://clerk.com/docs/ios/getting-started/quickstart)
- [Google OAuth Setup](https://clerk.com/docs/guides/configure/auth-strategies/social-connections/google)
- [Apple OAuth Setup](https://clerk.com/docs/guides/configure/auth-strategies/social-connections/apple)
- [Sign in with Apple - iOS Guide](https://clerk.com/docs/ios/guides/configure/auth-strategies/sign-in-with-apple)

## Support

- Clerk Documentation: https://clerk.com/docs
- Clerk Discord: https://clerk.com/discord
- GitHub Issues: https://github.com/clerk/clerk-ios/issues

---

**Last Updated**: Phase 2 Implementation - 2026-02-02
