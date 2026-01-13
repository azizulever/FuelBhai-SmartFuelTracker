# Firebase Security Rules for Data Privacy

This document outlines the critical Firebase security rules that must be configured to ensure user data privacy and prevent unauthorized access.

## Overview

The app implements a multi-layer security approach:
1. **Client-side**: User-specific local storage keys prevent data leakage on the device
2. **Firebase queries**: All queries filter by `userId` to fetch only user-specific data
3. **Server-side**: Firebase Security Rules enforce data isolation at the database level

## Required Firebase Security Rules

### Firestore Security Rules

Add these rules to your Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if the user owns the document
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Fueling Records - User can only read/write their own data
    match /fueling_records/{recordId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update: if isSignedIn() && resource.data.userId == request.auth.uid 
                    && request.resource.data.userId == request.auth.uid;
      allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Service Records - User can only read/write their own data
    match /service_records/{recordId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update: if isSignedIn() && resource.data.userId == request.auth.uid 
                    && request.resource.data.userId == request.auth.uid;
      allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Trip Records - User can only read/write their own data
    match /trip_records/{recordId} {
      allow read: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
      allow update: if isSignedIn() && resource.data.userId == request.auth.uid 
                    && request.resource.data.userId == request.auth.uid;
      allow delete: if isSignedIn() && resource.data.userId == request.auth.uid;
    }
    
    // Block all other access by default
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Security Rule Explanation

### Authentication Check
- `isSignedIn()`: Ensures only authenticated users can access data
- Anonymous/guest users store data locally only (not in Firebase)

### Data Isolation
Each rule enforces:
1. **Read**: User can only read documents where `userId` matches their Firebase Auth UID
2. **Create**: New documents must have `userId` set to the current user's UID
3. **Update**: User can only update their own documents, and cannot change the `userId` field
4. **Delete**: User can only delete their own documents

### Composite Indexes Required

For optimal query performance, create these composite indexes in Firebase Console → Firestore Database → Indexes:

#### Fueling Records Index
- Collection: `fueling_records`
- Fields: 
  - `userId` (Ascending)
  - `date` (Descending)
- Query scope: Collection

#### Service Records Index
- Collection: `service_records`
- Fields:
  - `userId` (Ascending)
  - `serviceDate` (Descending)
- Query scope: Collection

#### Trip Records Index
- Collection: `trip_records`
- Fields:
  - `userId` (Ascending)
  - `startTime` (Descending)
- Query scope: Collection

## How to Deploy Security Rules

### Option 1: Firebase Console (Recommended for testing)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Paste the security rules above
5. Click **Publish**

### Option 2: Firebase CLI (Recommended for production)
1. Ensure `firebase.json` has the rules file configured
2. Update `firestore.rules` file with the rules above
3. Deploy using: `firebase deploy --only firestore:rules`

## Testing Security Rules

Firebase Console provides a Rules Playground to test your rules:

1. Go to **Firestore Database** → **Rules** → **Rules Playground**
2. Test scenarios:
   - ✅ User A reading their own document
   - ❌ User A reading User B's document
   - ✅ User A creating a document with their userId
   - ❌ User A creating a document with another userId
   - ✅ User A updating their own document
   - ❌ User A updating another user's document

## Data Privacy Implementation Summary

### 1. Firebase (Logged-in Users)
- **Storage**: Cloud Firestore
- **Security**: Server-side Firebase Security Rules + client-side userId filtering
- **Access**: Only authenticated users can access their own data
- **Sync**: Real-time sync across devices for the same user

### 2. Local Storage (Guest Users)
- **Storage**: SharedPreferences with unique guest ID
- **Security**: Guest-specific keys (`guest_fueling_records`, etc.)
- **Access**: Data stored locally on device only
- **Migration**: When guest signs up, data is migrated to Firebase with their new userId

### 3. User-Specific Local Cache (Logged-in Users)
- **Storage**: SharedPreferences with user-specific keys (e.g., `offline_fueling_records_<userId>`)
- **Security**: Each user's data is stored in separate keys
- **Access**: Only accessible when that specific user is logged in
- **Cleanup**: Automatically cleared on logout

## Important Notes

⚠️ **Critical Security Practices:**

1. **Never trust client-side code**: Always enforce security rules on the server (Firebase)
2. **userId field is immutable**: Users should never be able to change the userId of existing documents
3. **Clear data on logout**: Ensure complete cleanup to prevent data leakage between users
4. **Test thoroughly**: Use Firebase Rules Playground to verify your rules work as expected
5. **Monitor usage**: Check Firebase Console for unauthorized access attempts

## Validation Checklist

Before deploying to production, verify:

- [ ] Firebase Security Rules are deployed
- [ ] Composite indexes are created for all collections
- [ ] Security rules tested in Rules Playground
- [ ] Guest mode stores data locally only (not in Firebase)
- [ ] Logged-in users can only access their own data
- [ ] Data is cleared on logout
- [ ] User-specific local storage keys are used
- [ ] No cross-user data contamination in tests
- [ ] Migration from guest to logged-in user works correctly

## Support

If you encounter security issues or need to modify rules:
1. Review Firebase documentation: https://firebase.google.com/docs/firestore/security/get-started
2. Test changes in the Rules Playground before deploying
3. Monitor Firebase Console for security rule violations
