# 🔧 Quick Configuration Guide

## After deploying your Cloud Function, update these 2 locations:

### Location 1: `lib/services/auth_service.dart` (Line ~93)

```dart
// In sendEmailVerificationCode method:
final functionUrl = 'YOUR_CLOUD_FUNCTION_URL_HERE';
```

**Replace with:**
```dart
final functionUrl = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail';
```

---

### Location 2: `lib/services/auth_service.dart` (Line ~214)

```dart
// In resendVerificationCode method:
final functionUrl = 'YOUR_CLOUD_FUNCTION_URL_HERE';
```

**Replace with:**
```dart
final functionUrl = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail';
```

---

## How to get your Cloud Function URL:

1. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

2. Copy the URL from the output:
   ```
   ✔  functions[sendVerificationEmail(us-central1)] Successful create operation.
   Function URL (sendVerificationEmail): https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail
   ```

3. Update both locations in `auth_service.dart` with this URL

---

## Don't forget to:

✅ Update sender email in `functions/index.js`
✅ Set SendGrid API key: `firebase functions:config:set sendgrid.key="YOUR_KEY"`
✅ Test with a real email address

---

**Full setup guide:** See `CLOUD_FUNCTION_SETUP.md`
