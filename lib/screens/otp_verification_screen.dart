import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../widgets/custom_button.dart';
import '../widgets/auth_header.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../config/email_config.dart';
import 'sign_in_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isResending = false;
  String _generatedOtp = '';
  DateTime? _otpGeneratedTime;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startExpiryChecker();
  }

  // Check OTP expiry every second and update UI
  void _startExpiryChecker() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {}); // Refresh UI to show expiry status
        _startExpiryChecker();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // Generate and send OTP via email
  void _sendOtp() async {
    // Generate 6-digit OTP
    _generatedOtp = EmailService.generateOtp();
    _otpGeneratedTime = DateTime.now();
    
    // Send real email
    bool emailSent = await EmailService.sendVerificationEmail(
      recipientEmail: widget.email,
      otp: _generatedOtp,
      userName: widget.name,
    );
    
    if (emailSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${widget.email}. Valid for 1 minute.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP. Please check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }



  // Check if OTP is expired
  bool _isOtpExpired() {
    if (_otpGeneratedTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_otpGeneratedTime!);
    return difference.inMinutes >= EmailConfig.otpExpiryMinutes;
  }

  // Verify OTP and create account
  void _verifyOtp() async {
    String enteredOtp = _pinController.text;
    
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if OTP is expired
    if (_isOtpExpired()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please request a new one.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      _pinController.clear();
      return;
    }

    if (enteredOtp != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      // Clear the pin input
      _pinController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // OTP is correct, now create the account
    String? result = await _authService.signUp(
      email: widget.email,
      password: widget.password,
      name: widget.name,
      phone: widget.phone,
    );

    setState(() {
      _isLoading = false;
    });

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // StreamBuilder will automatically navigate to HomeScreen
      // No need for manual navigation as AuthWrapper handles this
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ?? 'Account creation failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Resend OTP
  void _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    // Clear previous pin input and OTP data
    _pinController.clear();
    _generatedOtp = '';
    _otpGeneratedTime = null;
    
    await Future.delayed(const Duration(seconds: 1));
    _sendOtp();

    setState(() {
      _isResending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const AuthHeader(
                  title: 'Verify Email',
                  subtitle: 'Enter the 6-digit code sent to your email',
                ),
                const SizedBox(height: 25),
                
                // Email display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Pinput OTP Input
                Pinput(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  length: 6,
                  defaultPinTheme: PinTheme(
                    width: 50,
                    height: 55,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 50,
                    height: 55,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 50,
                    height: 55,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                    ),
                  ),
                  errorPinTheme: PinTheme(
                    width: 50,
                    height: 55,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                  onCompleted: (pin) {
                    // Auto verify when all 6 digits are entered
                    if (pin.length == 6) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  keyboardType: TextInputType.number,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                ),
                
                const SizedBox(height: 30),
                
                // Verify Button
                CustomButton(
                  text: 'Verify & Create Account',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend',
                        style: TextStyle(
                          color: _isResending ? Colors.grey[600] : Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // OTP Expiry Warning
                if (_otpGeneratedTime != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isOtpExpired() 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isOtpExpired() 
                            ? Colors.red.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOtpExpired() ? Icons.warning : Icons.info,
                          color: _isOtpExpired() ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isOtpExpired() 
                                ? 'OTP has expired. Please request a new one.'
                                : 'OTP is valid for ${EmailConfig.otpExpiryMinutes} minute from the time it was sent.',
                            style: TextStyle(
                              color: _isOtpExpired() ? Colors.red : Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Info text
                Text(
                  'Please check your email and enter the verification code to complete your registration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}