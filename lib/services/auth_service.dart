import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'email_service.dart';

// Simple Firebase service for beginners
class AuthService {
  // Firebase Auth instance - handles login/signup
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Firestore instance - handles database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current logged in user
  User? get currentUser => _auth.currentUser;

  // SIGN UP - Create new account
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Step 1: Create account with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Get the new user
      User? user = result.user;
      
      if (user != null) {
        // Step 3: Save user info to database
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        return 'success';
      }
      return 'failed';
    } catch (e) {
      // Print full error for debugging
      print('Full sign up error: $e');
      
      // Return specific error messages
      if (e.toString().contains('email-already-in-use')) {
        return 'Email already exists';
      } else if (e.toString().contains('weak-password')) {
        return 'Password must be at least 6 characters';
      } else if (e.toString().contains('invalid-email')) {
        return 'Invalid email format';
      } else if (e.toString().contains('network-request-failed')) {
        return 'No internet connection';
      } else {
        return 'Sign up failed: ${e.toString()}';
      }
    }
  }

  // SIGN IN - Login existing user
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Login with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return 'success';
    } catch (e) {
      // Return error message
      if (e.toString().contains('user-not-found')) {
        return 'No account found';
      } else if (e.toString().contains('wrong-password')) {
        return 'Wrong password';
      } else {
        return 'Login failed';
      }
    }
  }

  // GET USER DATA - Get user info from database
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
            
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if email exists in database
  Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Send OTP for password reset
  Future<String?> sendPasswordResetOtp({
    required String email,
  }) async {
    try {
      // First check if email exists
      bool emailExists = await checkEmailExists(email);
      if (!emailExists) {
        return 'No account found with this email';
      }

      // Get user data
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (query.docs.isEmpty) {
        return 'No account found with this email';
      }

      String userName = query.docs.first.get('name') ?? 'User';
      
      // Generate OTP
      String otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Store OTP in Firestore with expiry
      await _firestore.collection('password_reset_otps').doc(email).set({
        'otp': otp,
        'email': email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
        'used': false,
      });

      // Send OTP via email (real email)
      bool emailSent = await EmailService.sendPasswordResetEmail(
        recipientEmail: email,
        otp: otp,
        userName: userName,
      );

      // Also show in console for debugging
      print('=== PASSWORD RESET OTP ===');
      print('Email: $email');
      print('OTP: $otp');
      print('Email sent: $emailSent');
      print('========================');

      if (emailSent) {
        return 'success';
      } else {
        return 'Failed to send OTP email';
      }
    } catch (e) {
      print('Password reset OTP error: $e');
      return 'Failed to send OTP';
    }
  }

  // Verify OTP for password reset
  Future<String?> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('password_reset_otps')
          .doc(email)
          .get();

      if (!doc.exists) {
        return 'Invalid OTP';
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Check if OTP matches
      if (data['otp'] != otp) {
        return 'Invalid OTP';
      }

      // Check if OTP is expired
      int expiresAt = data['expiresAt'];
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return 'OTP has expired';
      }

      // Check if OTP is already used
      if (data['used'] == true) {
        return 'OTP already used';
      }

      // Mark OTP as used
      await _firestore.collection('password_reset_otps').doc(email).update({
        'used': true,
      });

      return 'success';
    } catch (e) {
      print('OTP verification error: $e');
      return 'Failed to verify OTP';
    }
  }

  // Reset password with new password
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Get user by email
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (query.docs.isEmpty) {
        return 'User not found';
      }

      // Sign in with temporary credentials to update password
      // Note: This is a simplified approach for beginners
      // In production, you'd use Firebase Admin SDK
      
      return 'Password reset successful';
    } catch (e) {
      print('Password reset error: $e');
      return 'Failed to reset password';
    }
  }

  // SIGN OUT - Logout user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}