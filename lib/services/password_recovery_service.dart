import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'backend_api_service.dart';

class PasswordRecoveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Step 1: Verify email with 6-digit code
  static Future<bool> verifyEmailWithCode({
    required String email,
    required String verificationCode,
  }) async {
    try {
      // Verify the code using your existing email verification service
      final doc = await _firestore.collection('email_verifications').doc(email).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      
      // Check if code has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('email_verifications').doc(email).delete();
        return false;
      }

      // Check if code matches
      if (storedCode != verificationCode) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error verifying email code: $e');
      return false;
    }
  }

  /// Step 2: Retrieve original password from backend (invisible to user)
  static Future<String?> retrieveOriginalPassword(String email) async {
    try {
      // Call your backend API to get the original password
      final response = await BackendApiService.getOriginalPassword(email);
      
      if (response['success'] == true) {
        return response['originalPassword'] as String?;
      }
      
      // If backend doesn't have the password, return null
      // This will trigger the fallback to Firebase password reset
      print('Backend API error: ${response['error']}');
      return null;
    } catch (e) {
      print('Error retrieving original password: $e');
      return null;
    }
  }

  /// Step 3: Change password using the original password (same as change password flow)
  static Future<bool> changePasswordWithOriginal({
    required String email,
    required String originalPassword,
    required String newPassword,
  }) async {
    try {
      // Get the user from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Re-authenticate with the original password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: originalPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);

      // Update last updated timestamp in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  /// Complete password recovery flow
  static Future<Map<String, dynamic>> completePasswordRecovery({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      // Step 1: Verify email code
      final isEmailVerified = await verifyEmailWithCode(
        email: email,
        verificationCode: verificationCode,
      );

      if (!isEmailVerified) {
        return {
          'success': false,
          'error': 'Invalid or expired verification code',
        };
      }

      // Step 2: Try to retrieve original password from backend
      final originalPassword = await retrieveOriginalPassword(email);
      
      if (originalPassword != null) {
        // Step 3: Change password using original password (your preferred method)
        final passwordChanged = await changePasswordWithOriginal(
          email: email,
          originalPassword: originalPassword,
          newPassword: newPassword,
        );

        if (passwordChanged) {
          // Clean up verification record
          await _firestore.collection('email_verifications').doc(email).delete();
          
          return {
            'success': true,
            'message': 'Password recovered and changed successfully!',
          };
        }
      }

      // Fallback: Use Firebase's built-in password reset
      // This is the recommended approach when we can't retrieve the original password
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        
        // Clean up verification record
        await _firestore.collection('email_verifications').doc(email).delete();
        
        return {
          'success': true,
          'message': 'Password reset email sent! Please check your email and follow the link to set your new password.',
          'useFirebaseReset': true,
        };
      } catch (firebaseError) {
        return {
          'success': false,
          'error': 'Failed to send password reset email. Please try again.',
        };
      }
    } catch (e) {
      print('Error in complete password recovery: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

}
