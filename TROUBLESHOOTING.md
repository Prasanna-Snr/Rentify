# 🔧 Email Troubleshooting Guide

## What I Fixed
✅ Changed from demo mode to real email sending
✅ Added better error messages and logging
✅ Updated the OTP verification screen

## Next Steps to Get Emails Working

### 1. Check Your Gmail App Password
Your current config uses: `prasannasunuwar03@gmail.com`

**Important:** You need a Gmail App Password, not your regular password!

1. Go to [Google Account Settings](https://myaccount.google.com)
2. Click **Security** → **2-Step Verification** (enable if not already)
3. Click **App passwords**
4. Generate a new app password for "Mail"
5. Copy the 16-character password (like: `abcd efgh ijkl mnop`)
6. Update `lib/config/email_config.dart` with this password

### 2. Test the Fix
1. Run your app: `flutter run`
2. Try signing up with a real email
3. Check the console for detailed logs:
   - 📧 Attempting to send email...
   - 🚀 Sending email...
   - ✅ Email sent successfully OR ❌ Error details

### 3. Common Issues & Solutions

**"Authentication failed"**
- Make sure you're using App Password, not regular password
- Enable 2-Factor Authentication first

**"Connection timeout"**
- Check internet connection
- Try using mobile hotspot to test

**"Less secure app access"**
- Don't use this! Use App Password instead

**Still not working?**
- Try creating a new Gmail account specifically for the app
- Make sure the email in config matches exactly

### 4. Quick Test
Run this and check console output:
```bash
flutter run
# Try signing up with your own email
# Watch console for email sending logs
```

## What Changed in Code

1. **lib/screens/otp_verification_screen.dart**
   - Changed `sendOtpEmailDemo` → `sendOtpEmail`
   - Added error handling for failed emails

2. **lib/services/email_service.dart**
   - Added detailed logging for debugging
   - Better error messages

The app will now actually send emails instead of just showing them in console!