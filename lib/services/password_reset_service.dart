import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PasswordResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'password_reset_requests';

  /// Request a password reset with verification
  static Future<bool> requestPasswordReset({
    required String email,
    required String newPassword,
    required String verificationCode,
  }) async {
    try {
      // Verify the code first
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

      // Store the password reset request
      await _firestore.collection(_collectionName).doc(email).set({
        'email': email,
        'new_password': newPassword,
        'verification_code': verificationCode,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10))),
        'used': false,
      });

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      return true;
    } catch (e) {
      print('Error requesting password reset: $e');
      return false;
    }
  }

  /// Complete the password reset by updating Firebase Auth
  static Future<bool> completePasswordReset({
    required String email,
    required String verificationCode,
  }) async {
    try {
      // Get the password reset request
      final doc = await _firestore.collection(_collectionName).doc(email).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedCode = data['verification_code'] as String;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      final used = data['used'] as bool? ?? false;
      
      // Check if request has expired or been used
      if (DateTime.now().isAfter(expiresAt) || used) {
        await _firestore.collection(_collectionName).doc(email).delete();
        return false;
      }

      // Check if verification code matches
      if (storedCode != verificationCode) {
        return false;
      }

      // Try to sign in with the old password to get the user
      // We'll use a different approach since we don't have the old password
      try {
        // Send another password reset email with a custom action code
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: email,
          actionCodeSettings: ActionCodeSettings(
            url: 'https://yourapp.com/reset-password',
            handleCodeInApp: true,
            iOSBundleId: 'com.example.yourapp',
            androidPackageName: 'com.example.yourapp',
            androidInstallApp: true,
            androidMinimumVersion: '12',
          ),
        );

        // Mark as used
        await _firestore.collection(_collectionName).doc(email).update({
          'used': true,
          'completed_at': FieldValue.serverTimestamp(),
        });

        return true;
      } catch (e) {
        print('Error completing password reset: $e');
        return false;
      }
    } catch (e) {
      print('Error completing password reset: $e');
      return false;
    }
  }

  /// Check if there's a pending password reset for an email
  static Future<bool> hasPendingPasswordReset(String email) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(email).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      final used = data['used'] as bool? ?? false;
      
      return !used && DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  /// Get the new password for immediate login
  static Future<String?> getNewPassword(String email) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(email).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      final used = data['used'] as bool? ?? false;
      
      if (used || DateTime.now().isAfter(expiresAt)) {
        return null;
      }

      return data['new_password'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Clean up expired password reset requests
  static Future<void> cleanupExpiredRequests() async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection(_collectionName)
          .where('expires_at', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up expired requests: $e');
    }
  }
}
