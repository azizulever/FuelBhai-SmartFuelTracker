# Quick Reference: Data Storage & Privacy

## How User Data is Stored and Fetched

### 🔐 Logged-In Users (Signed Up)

**Data Storage:**
- **Primary**: Firebase Firestore (Cloud)
- **Cache**: Local SharedPreferences with user-specific keys

**How it Works:**
1. User signs in with email/Google
2. App fetches data from Firebase (filtered by userId)
3. Data is cached locally with key: `offline_fueling_records_<userId>`
4. All operations sync to Firebase in real-time
5. Data accessible across all devices where user is logged in

**Data Flow:**
```
User Login → Firebase Auth (get userId)
    ↓
Fetch from Firebase (where userId = currentUser)
    ↓
Cache locally (offline_fueling_records_<userId>)
    ↓
User adds/updates data → Save to Firebase
    ↓
Update local cache
```

**Local Storage Keys:**
- `offline_fueling_records_<userId>` - Cached fuel records
- `pending_operations_<userId>` - Pending sync operations
- `service_records_<userId>` - Cached service records
- `trip_records_<userId>` - Cached trip records

---

### 👤 Guest Users (Not Signed In)

**Data Storage:**
- **Only**: Local SharedPreferences (No Firebase)
- **Identifier**: Unique guest ID (e.g., `guest_1234567890`)

**How it Works:**
1. User selects "Continue as Guest"
2. App generates unique guest ID
3. All data stored locally only
4. No cloud sync - data stays on device
5. If user signs up later, data migrates to Firebase

**Data Flow:**
```
Continue as Guest → Generate guest ID
    ↓
Store locally (guest_fueling_records)
    ↓
User adds/updates data → Save to local storage only
    ↓
(If user signs up) → Migrate all data to Firebase
```

**Local Storage Keys:**
- `guest_fueling_records` - Guest fuel records
- `guest_service_records` - Guest service records
- `guest_trip_records` - Guest trip records
- `guest_user_id` - Guest identifier

---

## Data Privacy Implementation

### ✅ User Isolation

**Problem Prevented:** User A seeing User B's data

**How We Prevent It:**

1. **Firebase Level:**
   - Each record has a `userId` field
   - Security rules enforce: `userId == auth.uid`
   - Queries filter: `where('userId', isEqualTo: currentUserId)`

2. **Local Storage Level:**
   - User-specific keys: `offline_fueling_records_<userId>`
   - Each user's data in separate storage keys
   - Cleared completely on logout

3. **Application Level:**
   - Double-validation when loading data
   - Filter by userId even from local cache
   - Clear in-memory data on logout

### 🧹 Logout Cleanup

When user logs out:
```dart
1. Get current userId
2. Clear all user-specific keys:
   - offline_fueling_records_<userId>
   - pending_operations_<userId>
   - service_records_<userId>
   - trip_records_<userId>
3. Clear legacy global keys (backward compatibility)
4. Clear in-memory data (fuelingRecords.clear())
5. Sign out from Firebase Auth
6. Sign out from Google (if applicable)
```

### 🔄 App Startup Flow

**For Logged-In Users:**
```
App Start
  ↓
Check Firebase Auth state
  ↓
User logged in? → YES
  ↓
Get userId from FirebaseAuth
  ↓
Fetch data from Firebase (filter by userId)
  ↓
Cache to user-specific local storage
  ↓
Display user's data
```

**For Guest Users:**
```
App Start
  ↓
Check guest mode flag
  ↓
Guest mode? → YES
  ↓
Load from guest_* keys
  ↓
Display guest data (local only)
```

---

## Firebase Security Rules

**Location:** Firebase Console → Firestore Database → Rules

```javascript
// Users can only access their own data
match /fueling_records/{recordId} {
  allow read: if resource.data.userId == request.auth.uid;
  allow create: if request.resource.data.userId == request.auth.uid;
  allow update: if resource.data.userId == request.auth.uid;
  allow delete: if resource.data.userId == request.auth.uid;
}
```

**What This Means:**
- User can only READ documents where userId matches their account
- User can only CREATE documents with their own userId
- User can only UPDATE/DELETE their own documents
- Server rejects any attempt to access another user's data

---

## Common Scenarios

### Scenario 1: New User Signs Up
```
1. User creates account → Firebase Auth assigns userId
2. userId saved in app state
3. Empty data (no records yet)
4. User adds fuel record → Saved to Firebase with their userId
5. Record also cached locally with key: offline_fueling_records_<userId>
```

### Scenario 2: Guest Converts to User
```
1. Guest uses app, data stored in guest_fueling_records
2. User signs up → Firebase Auth assigns userId
3. App reads guest_fueling_records
4. Migrates each record to Firebase with new userId
5. Clears guest_* keys
6. User now has cloud-synced data
```

### Scenario 3: User Switches Devices
```
Device 1:
  - User adds fuel record → Saved to Firebase
  
Device 2:
  - User logs in → Firebase Auth provides userId
  - App queries Firebase (where userId == auth.uid)
  - Fetches the same fuel record
  - User sees their data across devices
```

### Scenario 4: Multiple Users on Same Device
```
User A:
  - Login → userId: "userA123"
  - Data stored: offline_fueling_records_userA123
  - Logout → All userA123 keys cleared
  
User B (same device):
  - Login → userId: "userB456"
  - Data stored: offline_fueling_records_userB456
  - Cannot see User A's data (different keys)
  - Firebase rules also prevent access
```

---

## Key Points to Remember

### ✅ For Developers

1. **Never use global storage keys** for user-specific data
2. **Always include userId** in Firebase queries
3. **Validate userId** when loading cached data
4. **Clear everything** on logout
5. **Test with multiple users** to verify isolation

### ✅ For Users

1. **Signed-up users**: Data syncs across devices
2. **Guest users**: Data stays on device only
3. **Data is private**: Other users cannot see your records
4. **Logout is secure**: Your data is removed from device
5. **Sign up to backup**: Convert guest to account for cloud storage

---

## Troubleshooting

### "I logged out and logged back in, my data is gone!"
- Check if you logged in with the same account
- Different email = different userId = different data
- Guest data doesn't persist across accounts

### "Another user can see my data!"
- This should be impossible if Firebase rules are deployed
- Verify Firebase Security Rules are active
- Check that queries include userId filter

### "My data doesn't sync across devices"
- Ensure you're logged in with the same account
- Check internet connection
- Verify Firebase configuration

---

## Summary

| User Type | Storage Location | Syncs Across Devices | Privacy Level |
|-----------|-----------------|---------------------|---------------|
| Logged In | Firebase + Local Cache | ✅ Yes | 🔒 High (Server-enforced) |
| Guest | Local Only | ❌ No | 🔒 High (Device-only) |

**Bottom Line:** 
- Logged-in users get cloud backup and sync
- Guest users get local-only storage
- All users get complete privacy protection
- One user's data is never accessible by another user
