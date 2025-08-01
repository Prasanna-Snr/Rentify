// Email Configuration
// Replace these values with your actual email service credentials

class EmailConfig {
  // For Gmail SMTP - Replace with your actual credentials
  static const String senderEmail = 'prasannasunuwar03@gmail.com'; // Replace with your email
  static const String senderPassword = 'uvthjwfavmufvxvk'; // Replace with your app password
  static const String senderName = 'Rentify App';
  
  // Alternative: Use environment variables for security
  // static String get senderEmail => const String.fromEnvironment('SENDER_EMAIL', defaultValue: 'rentifyapp2025@gmail.com');
  // static String get senderPassword => const String.fromEnvironment('SENDER_PASSWORD', defaultValue: '');
  
  // Email settings
  static const int otpExpiryMinutes = 1;
  static const int resendTimerSeconds = 60;
  
  // SMTP Settings
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const bool useSSL = false;
  static const bool useTLS = true;
}

// Instructions for production setup:
/*
To use real email sending in production:

1. Update EmailConfig with your email credentials
2. In email_service.dart, replace sendOtpEmailDemo with sendOtpEmail
3. Make sure to use environment variables for sensitive data
4. Consider using services like SendGrid, AWS SES, or Mailgun for better reliability

Example environment setup:
- Create a .env file (add to .gitignore)
- Use flutter_dotenv package to load environment variables
- Store email credentials securely
*/