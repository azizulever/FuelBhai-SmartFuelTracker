# Firebase Setup for FuelBhai App

## Authentication & Data Isolation Fix

This document explains the changes made to fix authentication errors and ensure proper data isolation between user accounts.

## Changes Made

### 1. **Added userId to All Data Models**
- **ServiceRecord**: Now includes `userId` field
- **TripRecord**: Now includes `userId` field
- All records are now associated with specific users

### 2. **Created ServiceTripSyncService**
- New service (`lib/services/service_trip_sync.dart`) to sync Service and Trip records to Firebase
- Similar to FuelingService, provides offline-first capabilities
- Automatic sync when users log in/out

### 3. **Updated MileageController**
- All service/trip operations now include `userId`
- Integrated with ServiceTripSyncService
- Automatic data filtering by user

### 4. **Enhanced Auth Service**
- Clears local cache on login to prevent showing cached data from other users
- Syncs all data (fuel, service, trip) from Firebase on login
- Clears all data on logout

## Firebase Configuration Required

### Firestore Collections & Indexes

You need to create composite indexes in Firebase Console for optimal performance:

#### 1. **service_records** Collection

**Index 1:**
- Collection ID: `service_records`
- Fields indexed:
  - `userId` (Ascending)
  - `serviceDate` (Descending)
- Query scope: Collection

**How to create:**
1. Go to Firebase Console → Firestore Database
2. Click on "Indexes" tab
3. Click "Create Index"
4. Enter the fields as shown above

#### 2. **trip_records** Collection

**Index 1:**
- Collection ID: `trip_records`
- Fields indexed:
  - `userId` (Ascending)
  - `startTime` (Descending)
- Query scope: Collection

### Security Rules

Update your Firestore security rules to ensure users can only access their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fueling Records - user-specific access
    match /fueling_records/{recordId} {
      allow read, write: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Service Records - user-specific access
    match /service_records/{recordId} {
      allow read, write: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Trip Records - user-specific access
    match /trip_records/{recordId} {
      allow read, write: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

## How Data Flow Works Now

### New User Signup
1. User creates account → Firebase assigns unique `userId`
2. Fresh account with no data
3. When user adds data → automatically tagged with their `userId`
4. Data synced to Firebase with user identification

### User Adds Data
1. Data created with current user's `userId`
2. Saved to Firebase immediately (offline-first)
3. If offline, queued for sync when online

### User Logout
1. All local cache cleared (fuel, service, trip)
2. Firebase sign out
3. No data remains on device

### User Login
1. Firebase authentication
2. All local cache cleared first
3. Fetch user's data from Firebase filtered by `userId`
4. Only user's own data is shown

### Data Isolation
- All queries filter by `userId`
- Security rules enforce server-side protection
- No cross-user data access possible

## Testing Checklist

### Test 1: New User Signup
- [ ] Create new account
- [ ] Verify no existing data shown
- [ ] Add fuel/service/trip entries
- [ ] Verify data appears correctly
- [ ] Check Firebase Console - data has correct userId

### Test 2: Data Isolation
- [ ] Login with User A
- [ ] Add some entries
- [ ] Logout
- [ ] Login with User B
- [ ] Verify User A's data NOT visible
- [ ] Add User B's entries
- [ ] Logout
- [ ] Login with User A again
- [ ] Verify only User A's data visible

### Test 3: Logout/Login Persistence
- [ ] Login with user
- [ ] Add fuel/service/trip entries
- [ ] Logout
- [ ] Login again with same user
- [ ] Verify all data restored from Firebase

### Test 4: Multi-Device Sync
- [ ] Login on Device A
- [ ] Add entries
- [ ] Login on Device B with same account
- [ ] Verify data synced and visible

## Migration Notes

### For Existing Users
If you have existing users with data stored locally:
1. The first time they log in after this update, their local data will be cleared
2. They may need to re-add their data OR
3. You can create a migration script to assign userId to existing Firebase records

### Migration Script (Optional)
If you have existing data in Firebase without userId:
1. Export data from Firebase
2. Update each record with the correct userId
3. Import back to Firebase

## Troubleshooting

### Issue: Data not syncing
- Check internet connection
- Verify Firebase indexes are created
- Check console logs for sync errors

### Issue: Previous user data showing
- Ensure you're using the latest code
- Clear app data completely
- Reinstall app if needed

### Issue: Google Sign-In Error (ApiException: 10)
- Add SHA-1 and SHA-256 fingerprints to Firebase Console
- Download updated google-services.json
- Rebuild app

## Summary

✅ **Fixed Issues:**
- New users get fresh accounts (no cached data)
- User data properly isolated by userId
- Service and Trip records now sync to Firebase
- Logout properly clears all data
- Login fetches only user's own data from Firebase

✅ **Security:**
- Firebase security rules enforce user-specific access
- No cross-contamination between user accounts

✅ **User Experience:**
- Seamless multi-device sync
- Offline-first capability maintained
- Data persistence across sessions
