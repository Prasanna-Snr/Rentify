import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  
  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  // Pinput theme - unfocused with purple border
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: const TextStyle(
      fontSize: 20,
      color: Colors.deepPurple,
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.deepPurple, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Focused theme - filled with purple color
  late final PinTheme focusedPinTheme = defaultPinTheme.copyDecorationWith(
    color: Colors.deepPurple.withOpacity(0.1),
    border: Border.all(color: Colors.deepPurple, width: 2),
    borderRadius: BorderRadius.circular(12),
  );

  // Submitted theme - filled with light purple
  late final PinTheme submittedPinTheme = defaultPinTheme.copyWith(
    decoration: defaultPinTheme.decoration?.copyWith(
      color: Colors.deepPurple.withOpacity(0.05),
      border: Border.all(color: Colors.deepPurple, width: 2),
    ),
  );

  // Verify OTP
  void _verifyOtp() {
    if (_otpController.text.trim().isEmpty) {
      _showMessage('Please enter the OTP');
      return;
    }

    if (_otpController.text.trim().length != 6) {
      _showMessage('OTP must be 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _authService.verifyPasswordResetOtp(
      email: widget.email,
      otp: _otpController.text.trim(),
    ).then((result) {
      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        // Navigate to reset password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email),
          ),
        );
      } else {
        _showMessage(result ?? 'Invalid OTP');
      }
    });
  }

  // Resend OTP
  void _resendOtp() {
    setState(() {
      _isLoading = true;
    });

    _authService.sendPasswordResetOtp(email: widget.email).then((result) {
      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        _showMessage('New OTP sent to your email!', isSuccess: true);
      } else {
        _showMessage(result ?? 'Failed to resend OTP');
      }
    });
  }

  // Show message
  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.security,
                      size: 50,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Title and subtitle - centered
                const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Enter the 6-digit code sent to your email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                // Email display - centered
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, color: Colors.blue),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // OTP Pinput field
                Center(
                  child: Pinput(
                    controller: _otpController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    validator: (s) {
                      if (s == null || s.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (s.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: (pin) {
                      // Auto verify when all 6 digits are entered
                      if (pin.length == 6) {
                        _verifyOtp();
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Verify button
                CustomButton(
                  text: 'Verify OTP',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 30),
                
                // Resend OTP - centered
                Center(
                  child: Column(
                    children: [
                      const Text(
                        "Didn't receive the code?",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isLoading ? null : _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Extra space for keyboard
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}