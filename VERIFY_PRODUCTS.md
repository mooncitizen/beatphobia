# StoreKit Products Verification Checklist

## Current Configuration

**Bundle ID:** `org.stillstep.stillstepapp`

**Product IDs in Code:**
- Monthly: `pro_account_v1_monthly`
- Yearly: `pro_account_v2_yearly`

---

## App Store Connect Verification

Please verify **EXACTLY** in App Store Connect:

### 1. Bundle ID Match
- [ ] Go to App Store Connect → My Apps → Your App
- [ ] Verify Bundle ID is exactly: `org.stillstep.stillstepapp`

### 2. In-App Purchases Configuration
Go to: App Store Connect → Your App → Monetization → Subscriptions

#### Monthly Subscription:
- [ ] Product ID is **exactly**: `pro_account_v1_monthly` (case-sensitive!)
- [ ] Status: "Ready to Submit" ✅
- [ ] Reference Name: (can be anything, e.g., "Pro Monthly")
- [ ] In a Subscription Group: ✅
- [ ] Subscription Duration: 1 Month
- [ ] Price: Set ✅

#### Yearly Subscription:
- [ ] Product ID is **exactly**: `pro_account_v2_yearly` (case-sensitive!)
- [ ] Status: "Ready to Submit" ✅
- [ ] Reference Name: (can be anything, e.g., "Pro Yearly")
- [ ] In the SAME Subscription Group as monthly ✅
- [ ] Subscription Duration: 1 Year
- [ ] Price: Set ✅

### 3. Agreements & Banking
- [ ] Paid Applications Agreement: **Active** ✅
- [ ] Banking Information: **Complete** ✅
- [ ] Tax Information: **Complete** ✅

### 4. App Status
- [ ] App has been submitted to review at least once (or is in review/approved)
  - OR you're using TestFlight
  - OR you're using StoreKit Configuration file for local testing

---

## Common Issues That Cause 0 Products:

### ❌ Product ID Typos
Even a single character difference will cause products not to load:
- `pro_account_v1_monthly` ✅
- `pro_account_v1_montly` ❌ (missing 'h')
- `Pro_Account_V1_Monthly` ❌ (wrong case)

### ❌ Wrong Bundle ID
If products are created for a different bundle ID, they won't show.

### ❌ Products Not in a Subscription Group
All auto-renewable subscriptions must be in a group.

### ❌ Products in "Developer Action Needed" Status
Products must be in "Ready to Submit" or approved status.

### ❌ Testing on Real Device Without Sandbox Account
When testing on device, you need a sandbox test account.

### ❌ Using Production Apple ID for Testing
Must use sandbox test account for testing subscriptions.

---

## Testing Methods (Choose ONE):

### Option A: Local Testing with StoreKit Config (Recommended for Development)
✅ No internet required
✅ Instant, no waiting
✅ Can test various scenarios
❌ Must be added to Xcode project and configured in scheme

**Steps:**
1. Add `stillstep.storekit` to Xcode project (right-click → Add Files)
2. Edit Scheme → Run → Options → Select `stillstep.storekit`
3. Run app and test

### Option B: Sandbox Testing (Required Before Release)
✅ Tests real App Store Connect products
✅ Required for final testing
❌ Requires signed agreements
❌ Requires sandbox Apple ID

**Steps:**
1. Create sandbox test user in App Store Connect
2. Sign out of App Store on device
3. Run app, attempt purchase
4. Sign in with sandbox account when prompted

### Option C: TestFlight (Pre-Release Testing)
✅ Most realistic testing
✅ Tests full production flow
❌ Requires app submission
❌ Slower iteration

---

## Debug Steps to Try NOW:

### 1. Double-Check Product IDs
Copy the EXACT product IDs from App Store Connect and compare character by character with your code.

### 2. Wait 2-24 Hours
Sometimes newly created products take time to propagate through Apple's servers. If you just created them, wait and try again.

### 3. Test with StoreKit Config File First
This eliminates App Store Connect as a variable and lets you test immediately.

### 4. Verify Xcode Capability
- Select project → Target → Signing & Capabilities
- Verify "In-App Purchase" capability is added

### 5. Clean Everything
```bash
# In Terminal:
cd /Users/paul/ios-projects/beatphobia
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
Then in Xcode: Product → Clean Build Folder (⌘ + Shift + K)
Then rebuild and run

---

## Need More Help?

If still not working, please share:
1. Screenshot of your products in App Store Connect (showing Product IDs)
2. Full console output from app launch
3. Confirmation of which testing method you're using

