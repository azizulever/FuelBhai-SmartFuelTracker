# 📋 Setup Checklist

Complete these steps to enable real email verification:

## ☐ Step 1: SendGrid Account Setup (5 minutes)
- [ ] Go to https://sendgrid.com
- [ ] Create free account (no credit card needed)
- [ ] Verify your email address
- [ ] Go to Settings → Sender Authentication
- [ ] Click "Verify a Single Sender"
- [ ] Complete sender verification (use your personal/business email)
- [ ] Go to Settings → API Keys
- [ ] Create new API key (Full Access)
- [ ] **SAVE THE API KEY** (you won't see it again!)

## ☐ Step 2: Firebase Setup (3 minutes)
- [ ] Open terminal in project root
- [ ] Run: `firebase login`
- [ ] Run: `cd functions`
- [ ] Run: `npm install`
- [ ] Run: `firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"`
  - Replace YOUR_SENDGRID_API_KEY with the key from Step 1

## ☐ Step 3: Update Cloud Function (2 minutes)
- [ ] Open `functions/index.js`
- [ ] Find line 42: `from: 'YOUR_VERIFIED_SENDER_EMAIL@example.com'`
- [ ] Replace with your verified sender email from Step 1
- [ ] Save the file

## ☐ Step 4: Deploy Cloud Function (2 minutes)
- [ ] In terminal (from functions folder): `firebase deploy --only functions`
- [ ] Wait for deployment to complete
- [ ] **COPY THE FUNCTION URL** from the output
  - Example: `https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/sendVerificationEmail`

## ☐ Step 5: Update Flutter App (1 minute)
- [ ] Open `lib/services/auth_service.dart`
- [ ] Find line ~176: `final functionUrl = 'YOUR_CLOUD_FUNCTION_URL_HERE';`
- [ ] Replace with your Cloud Function URL from Step 4
- [ ] Find line ~293: `final functionUrl = 'YOUR_CLOUD_FUNCTION_URL_HERE';`
- [ ] Replace with the same Cloud Function URL
- [ ] Save the file

## ☐ Step 6: Test (5 minutes)
- [ ] Run your Flutter app
- [ ] Try signing up with **your real email address**
- [ ] Check your email inbox (may take 10-30 seconds)
- [ ] Check spam folder if not in inbox
- [ ] Copy the 6-digit code from email
- [ ] Paste it in the verification screen
- [ ] Complete sign-up successfully ✅

---

## ⚠️ Common Issues

**Email not arriving?**
- Check spam/junk folder
- Verify SendGrid sender is verified (check SendGrid dashboard)
- Check Firebase function logs: `firebase functions:log`

**Deployment failed?**
- Ensure Node.js 18+ is installed: `node --version`
- Try: `firebase deploy --only functions --debug`
- Check you're logged in: `firebase login`

**Function URL not working?**
- Make sure you copied the ENTIRE URL
- Include the `https://` at the beginning
- No trailing slash at the end

---

## 🎯 You're Done When...

✅ SendGrid account created and verified
✅ Cloud function deployed successfully  
✅ Function URL updated in auth_service.dart (2 places)
✅ Test email received in inbox
✅ User can sign up successfully

---

**Estimated Time:** 15-20 minutes  
**Cost:** $0 (free tiers)

Need detailed help? See `CLOUD_FUNCTION_SETUP.md`
