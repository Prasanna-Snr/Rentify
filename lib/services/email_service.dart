import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/email_config.dart';

class EmailService {
  // Email configuration from config file
  static const String _senderEmail = EmailConfig.senderEmail;
  static const String _senderPassword = EmailConfig.senderPassword;
  static const String _senderName = EmailConfig.senderName;

  // Generate 6-digit OTP
  static String generateOtp() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }



  // Send OTP for email verification (signup)
  static Future<bool> sendVerificationEmail({
    required String recipientEmail,
    required String otp,
    required String userName,
  }) async {
    try {
      print('Sending verification email...');
      
      // Configure SMTP server (Gmail)
      final smtpServer = gmail(_senderEmail, _senderPassword);
      
      // Create email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Verify Your Email - Rentify'
        ..html = _buildVerificationEmailTemplate(otp, userName);

      // Send email
      final sendReport = await send(message, smtpServer);
      print('Verification email sent successfully');
      return true;
    } catch (e) {
      print('Error sending verification email: $e');
      return false;
    }
  }

  // Send OTP for password reset
  static Future<bool> sendPasswordResetEmail({
    required String recipientEmail,
    required String otp,
    required String userName,
  }) async {
    try {
      print('Sending password reset email...');
      
      // Configure SMTP server (Gmail)
      final smtpServer = gmail(_senderEmail, _senderPassword);
      
      // Create email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Reset Your Password - Rentify'
        ..html = _buildPasswordResetEmailTemplate(otp, userName);

      // Send email
      final sendReport = await send(message, smtpServer);
      print('Password reset email sent successfully');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Demo function for email verification
  static Future<bool> sendVerificationEmailDemo({
    required String recipientEmail,
    required String otp,
    required String userName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    print('=== EMAIL VERIFICATION ===');
    print('To: $recipientEmail');
    print('Subject: Verify Your Email - Rentify');
    print('Message: Hi $userName, use code $otp to verify your email');
    print('==========================');
    
    return true;
  }

  // Demo function for password reset
  static Future<bool> sendPasswordResetEmailDemo({
    required String recipientEmail,
    required String otp,
    required String userName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    print('=== PASSWORD RESET ===');
    print('To: $recipientEmail');
    print('Subject: Reset Your Password - Rentify');
    print('Message: Hi $userName, use code $otp to reset your password');
    print('======================');
    
    return true;
  }

  // Simple email template for email verification
  static String _buildVerificationEmailTemplate(String otp, String userName) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
      <h2 style="color: #333;">Verify Your Email</h2>
      
      <p>Hi $userName,</p>
      
      <p>Welcome to Rentify! Please use this code to verify your email:</p>
      
      <div style="background: #f0f0f0; padding: 20px; text-align: center; margin: 20px 0;">
        <h1 style="color: #673ab7; font-size: 32px; margin: 0;">$otp</h1>
      </div>
      
      <p>This code expires in ${EmailConfig.otpExpiryMinutes} minutes.</p>
      
      <p>Thanks,<br>Rentify Team</p>
    </div>
    ''';
  }

  // Simple email template for password reset
  static String _buildPasswordResetEmailTemplate(String otp, String userName) {
    return '''
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
      <h2 style="color: #333;">Reset Your Password</h2>
      
      <p>Hi $userName,</p>
      
      <p>You requested to reset your password. Use this code:</p>
      
      <div style="background: #f0f0f0; padding: 20px; text-align: center; margin: 20px 0;">
        <h1 style="color: #d32f2f; font-size: 32px; margin: 0;">$otp</h1>
      </div>
      
      <p>This code expires in 10 minutes.</p>
      
      <p>If you didn't request this, please ignore this email.</p>
      
      <p>Thanks,<br>Rentify Team</p>
    </div>
    ''';
  }
}