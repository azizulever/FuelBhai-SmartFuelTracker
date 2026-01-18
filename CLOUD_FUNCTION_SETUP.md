# Email Verification Cloud Function Setup

This guide will help you set up the Firebase Cloud Function to send verification emails.

## Prerequisites

- Node.js (v18 or later) installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- A SendGrid account (free tier available)

## Step 1: SendGrid Setup

1. **Create SendGrid Account**
   - Go to https://sendgrid.com
   - Sign up for a free account (100 emails/day free)

2. **Verify Sender Email**
   - Go to Settings > Sender Authentication
   - Click "Verify a Single Sender"
   - Enter your email address and complete verification
   - This email will be used as the "from" address

3. **Create API Key**
   - Go to Settings > API Keys
   - Click "Create API Key"
   - Name it "FuelBhai Verification Emails"
   - Select "Full Access"
   - Copy the API key (you won't see it again!)

## Step 2: Firebase Cloud Functions Setup

1. **Initialize Firebase Functions** (if not already done)
   ```bash
   cd g:\Flutter\FuelBhai\FuelBhai-SmartFuelTracker
   firebase login
   firebase init functions
   ```
   - Choose JavaScript
   - Install dependencies with npm

2. **Install Dependencies**
   ```bash
   cd functions
   npm install
   ```

3. **Configure SendGrid API Key**
   ```bash
   firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY_HERE"
   ```
   Replace `YOUR_SENDGRID_API_KEY_HERE` with your actual SendGrid API key from Step 1.

4. **Update Sender Email**
   - Open `functions/index.js`
   - Find line: `from: 'YOUR_VERIFIED_SENDER_EMAIL@example.com'`
   - Replace with your verified sender email from Step 1

## Step 3: Deploy Cloud Function

1. **Deploy to Firebase**
   ```bash
   firebase deploy --only functions
   ```

2. **Get Your Function URL**
   After deployment, you'll see output like:
   ```
   Function URL (sendVerificationEmail): https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail
   ```
   Copy this URL!

## Step 4: Update Flutter App

1. **Open** `lib/services/auth_service.dart`

2. **Find** (around line 93):
   ```dart
   final functionUrl = 'YOUR_CLOUD_FUNCTION_URL_HERE';
   ```

3. **Replace** with your actual Cloud Function URL from Step 3:
   ```dart
   final functionUrl = 'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail';
   ```

4. **Also update** the same line in the `resendVerificationCode` method (around line 214)

## Step 5: Test

1. Run your Flutter app
2. Try signing up with a real email address
3. Check your email inbox for the verification code
4. Enter the code in the app

## Troubleshooting

### Email not received?
- Check spam/junk folder
- Verify SendGrid sender email is verified
- Check Firebase Functions logs: `firebase functions:log`

### Function deployment failed?
- Make sure you're logged in: `firebase login`
- Check Node.js version: `node --version` (should be 18+)
- Try: `firebase deploy --only functions --debug`

### "Failed to send email" error?
- Check SendGrid API key is set correctly
- Verify sender email in SendGrid
- Check function logs for detailed errors

## Cost & Limits

**SendGrid Free Tier:**
- 100 emails/day
- Perfect for development and small apps

**Firebase Cloud Functions:**
- Free tier: 2M invocations/month
- Usually free for small apps

**For Production:**
- Consider upgrading SendGrid for more emails
- Monitor Firebase usage in console

## Security Notes

✅ **Good:** API keys are stored securely in Firebase Config
✅ **Good:** Cloud Function validates input
✅ **Good:** No sensitive data in client code

## Alternative Email Services

Instead of SendGrid, you can also use:
- **Mailgun** (100 emails/day free)
- **AWS SES** (requires AWS account)
- **Gmail SMTP** (less secure, not recommended)

To switch services, modify `functions/index.js` and replace SendGrid code with your preferred service.

---

**Need Help?**
- SendGrid Docs: https://docs.sendgrid.com
- Firebase Functions: https://firebase.google.com/docs/functions
