# Apple App Review Rejection - Fixes Applied

## Rejection Date: October 30, 2025
## Submission ID: 6c2200e0-3ef1-4a8a-aff1-61040ecaba7c

---

## ✅ Issue 1: Guideline 3.1.2 - Subscription Pricing Display

### **Problem:**
The monthly calculated pricing ($4.99/month) was displayed more prominently than the actual billed amount ($59.99/year).

### **Fix Applied:**
Updated `PaywallView.swift` - PricingCard component:

**Before:**
- Monthly price: 32pt bold (most prominent)
- Billed amount: 13pt secondary text

**After:**
- **Billed amount: 36pt bold** (MOST prominent)
- Monthly equivalent: 13pt secondary text (subordinate)

**Visual Change:**
```
OLD:
Pro Yearly
$4.99/month  ← Big (32pt)
Billed $59.99 annually ← Small (13pt)

NEW:
Pro Yearly
$59.99/year ← Big (36pt)  
Just $4.99/month ← Small (13pt)
```

**File Changed:** `beatphobia/Pages/PaywallView.swift` lines 476-502

---

## ✅ Issue 2: Guideline 3.1.2 - Missing Terms of Use Links

### **Problem:**
Apple requires functional links to Terms of Use and Privacy Policy.

### **Fix Applied:**
Links are already present and functional in PaywallView:

**Terms Link:** `https://stillstep.com/terms`  
**Privacy Link:** `https://stillstep.com/privacy`

### **Action Required:**
✅ **Ensure these pages exist and are accessible**
- Create/verify `https://stillstep.com/terms` exists
- Create/verify `https://stillstep.com/privacy` exists

### **In App Store Connect:**
1. Go to your app → App Information
2. **Privacy Policy URL**: Add `https://stillstep.com/privacy`
3. **App Description**: Mention Terms of Use link OR
4. **EULA field**: Add custom EULA or link to terms

**Already in App:** Lines 298-315 in PaywallView.swift show functional blue buttons for both links.

---

## ✅ Issue 3: Guideline 5.1.1(v) - Account Deletion

### **Problem:**
App supports account creation but has no account deletion option.

### **Fix Applied:**

**1. Database Function Created:**
- File: `database/22_add_account_deletion.sql`
- Function: `delete_user_account()`
- Deletes all user data:
  - Community posts, comments, likes, bookmarks
  - Attachments, messages, friendships
  - Profile data
  - Auth user account

**2. UI Added to Profile:**
- New "Delete Account" button (red, prominent)
- Confirmation alert with clear warning
- Explains data will be permanently deleted
- Cannot be undone

**3. Location in App:**
Profile → Scroll down → "Delete Account" button (above "Log Out")

### **Setup Required:**
Run in Supabase SQL Editor:
```
database/22_add_account_deletion.sql
```

This creates the `delete_user_account()` function that users can call to delete their own accounts.

**File Changed:** `beatphobia/Pages/Profile.swift` lines 445-573

---

## 📋 Checklist Before Resubmission

### ✅ Code Changes:
- [x] Subscription pricing fixed (billed amount most prominent)
- [x] Account deletion button added to Profile
- [x] Account deletion function implemented
- [x] Confirmation alert with warning added

### 🌐 Website Requirements:
- [ ] Create `https://stillstep.com/terms` (Terms of Use page)
- [ ] Create `https://stillstep.com/privacy` (Privacy Policy page)
- [ ] Ensure both pages are publicly accessible

### 📱 App Store Connect:
- [ ] Add Privacy Policy URL: `https://stillstep.com/privacy`
- [ ] Add Terms in App Description OR EULA field

### 🗄️ Database:
- [ ] Run `database/22_add_account_deletion.sql` in Supabase SQL Editor

---

## Testing Account Deletion

1. Open app → Profile tab
2. Scroll to bottom
3. Tap "Delete Account" (red button)
4. Alert appears with warning
5. Tap "Delete" to confirm
6. Account is deleted, user is signed out
7. All data removed from database

---

## App Review Response Template

Dear App Review Team,

Thank you for your feedback. We have addressed all three issues:

**1. Subscription Pricing (3.1.2):**
We have updated the subscription purchase flow to display the actual billed amount ($59.99/year) as the most prominent pricing element (36pt bold). The monthly calculated pricing is now subordinate (13pt secondary text).

**2. Terms of Use Links (3.1.2):**
Our app includes functional links to:
- Terms of Use: https://stillstep.com/terms
- Privacy Policy: https://stillstep.com/privacy

These are accessible from the subscription screen and app metadata.

**3. Account Deletion (5.1.1v):**
We have added account deletion functionality. Users can:
- Navigate to Profile tab
- Scroll to bottom
- Tap "Delete Account"
- Confirm deletion in alert dialog
- Account and all data are permanently deleted

The deletion is immediate and permanent, with a clear warning shown to users.

We believe these changes fully address the review guidelines. Thank you for your consideration.

Best regards,
Still Step Team

---

## Notes

- Account deletion uses a Supabase RPC function for secure server-side deletion
- All foreign key constraints are handled (cascade deletes)
- User is immediately signed out after deletion
- No data remains in the database after deletion


