import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Send password reset email
  void _sendResetEmail() {
    if (_emailController.text.trim().isEmpty) {
      _showMessage('Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _authService.sendPasswordResetOtp(
      email: _emailController.text.trim(),
    ).then((result) {
      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        _showMessage('OTP sent to your email! Check your inbox and spam folder.', isSuccess: true);
        // Navigate to OTP verification screen
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        });
      } else {
        _showMessage(result ?? 'Failed to send OTP');
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header
                const AuthHeader(
                  title: 'Forgot Password?',
                  subtitle: 'Enter your email address and we\'ll send you an OTP to reset your password.',
                ),
                
                const SizedBox(height: 40),
                
                // Email field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                
                const SizedBox(height: 30),
                
                // Send OTP button
                CustomButton(
                  text: 'Send OTP',
                  onPressed: _sendResetEmail,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Back to sign in
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 16,
                      ),
                    ),
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
    _emailController.dispose();
    super.dispose();
  }
}