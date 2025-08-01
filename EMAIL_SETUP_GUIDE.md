# 📧 Email Setup Guide for Rentify

## Quick Setup for Gmail

### Step 1: Create a Gmail Account (if needed)
1. Go to [Gmail](https://gmail.com)
2. Create a new account or use existing one
3. Recommended: Create a dedicated account like `rentifyapp2025@gmail.com`

### Step 2: Enable 2-Factor Authentication
1. Go to [Google Account Settings](https://myaccount.google.com)
2. Click **Security** in the left menu
3. Under **Signing in to Google**, click **2-Step Verification**
4. Follow the setup process

### Step 3: Generate App Password
1. In Google Account Settings, go to **Security**
2. Under **Signing in to Google**, click **App passwords**
3. Select **Mail** as the app
4. Select **Other** as the device and name it "Rentify App"
5. Copy the 16-character password (e.g., `abcd efgh ijkl mnop`)

### Step 4: Update Configuration
1. Open `lib/config/email_config.dart`
2. Replace the values:
```dart
static const String senderEmail = 'your-actual-email@gmail.com';
static const String senderPassword = 'your-16-char-app-password';
```

### Step 5: Test the Setup
1. Run your app
2. Try signing up with a real email address
3. Check the email inbox for the verification code

## Alternative Email Services

### Outlook/Hotmail
```dart
static const String smtpHost = 'smtp-mail.outlook.com';
static const int smtpPort = 587;
```

### Yahoo Mail
```dart
static const String smtpHost = 'smtp.mail.yahoo.com';
static const int smtpPort = 587;
```

## Production Recommendations

For production apps, consider using:
- **SendGrid** - Professional email service
- **AWS SES** - Amazon's email service
- **Mailgun** - Developer-friendly email API
- **Firebase Extensions** - Email trigger extensions

## Troubleshooting

### Common Issues:
1. **"Authentication failed"** - Check app password
2. **"Connection timeout"** - Check internet connection
3. **"Less secure app access"** - Use app password instead

### Security Notes:
- Never commit email credentials to version control
- Use environment variables in production
- Consider using OAuth2 for better security
- Monitor email sending limits (Gmail: 500/day)

## Environment Variables (Recommended)

Create a `.env` file:
```
SENDER_EMAIL=your-email@gmail.com
SENDER_PASSWORD=your-app-password
```

Add to `.gitignore`:
```
.env
```

Use in code:
```dart
static String get senderEmail => const String.fromEnvironment('SENDER_EMAIL');
static String get senderPassword => const String.fromEnvironment('SENDER_PASSWORD');
```