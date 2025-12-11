import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'emailjs_service.dart';
import 'smtp_email_service.dart';

class EmailVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'email_verifications';

  /// Generate a random 6-digit verification code
  static String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send verification code to email
  static Future<bool> sendVerificationCode(String email, {String? userName}) async {
    try {
      // Generate 6-digit code
      final code = _generateVerificationCode();
      
      // Store verification code in Firestore with expiration (5 minutes)
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      
      await _firestore.collection(_collectionName).doc(email).set({
        'code': code,
        'email': email,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(expiresAt),
        'verified': false,
      });

      // Store code globally for debugging (console logs only)
      _lastGeneratedCode = code;
      _lastGeneratedEmail = email;
      
      // Check SMTP configuration first
      SMTPEmailService.printConfigurationStatus();
      
      // Try SMTP first, then EmailJS as fallback
      if (SMTPEmailService.isConfigured) {
        print('Attempting to send email via SMTP...');
        final emailSent = await SMTPEmailService.sendVerificationEmail(
          toEmail: email,
          verificationCode: code,
          userName: userName ?? 'User',
        );
        
        if (emailSent) {
          print('✅ Email sent successfully via SMTP');
          return true;
        } else {
          print('❌ SMTP failed, trying EmailJS fallback...');
        }
      } else {
        print('❌ SMTP not configured - skipping SMTP');
      }
      
      // Fallback to EmailJS if SMTP is not configured or failed
      if (EmailJSService.isConfigured) {
        print('Attempting to send email via EmailJS...');
        final emailSent = await EmailJSService.sendVerificationEmail(
          toEmail: email,
          verificationCode: code,
          userName: userName ?? 'User',
        );
        
        if (emailSent) {
          print('✅ Email sent successfully via EmailJS');
          return true;
        } else {
          print('❌ EmailJS also failed');
        }
      }
      
      // Both methods failed
      print('❌ All email methods failed');
      print('🔧 DEBUG: Verification code for $email is: $code');
      print('🔧 You can use this code to test the verification process');
      return false;
    } catch (e) {
      print('Error sending verification code: $e');
      return false;
    }
  }

  // Global variables to store the last generated code for testing
  static String? _lastGeneratedCode;
  static String? _lastGeneratedEmail;

  /// Get the last generated code for testing purposes
  static String? getLastGeneratedCode() => _lastGeneratedCode;
  static String? getLastGeneratedEmail() => _lastGeneratedEmail;

  /// Verify the entered code
  static Future<bool> verifyCode(String email, String enteredCode) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(email).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      
      // Check if code has expired
      if (DateTime.now().isAfter(expiresAt)) {
        // Delete expired code
        await _firestore.collection(_collectionName).doc(email).delete();
        return false;
      }

      // Check if code matches
      if (storedCode == enteredCode) {
        // Mark as verified
        await _firestore.collection(_collectionName).doc(email).update({
          'verified': true,
          'verified_at': FieldValue.serverTimestamp(),
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying code: $e');
      return false;
    }
  }

  /// Check if email is already verified
  static Future<bool> isEmailVerified(String email) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(email).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      return data['verified'] == true;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  /// Clean up expired verification codes
  static Future<void> cleanupExpiredCodes() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final query = await _firestore
          .collection(_collectionName)
          .where('expires_at', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired codes: $e');
    }
  }

  /// Delete verification record after successful signup
  static Future<void> deleteVerificationRecord(String email) async {
    try {
      await _firestore.collection(_collectionName).doc(email).delete();
    } catch (e) {
      print('Error deleting verification record: $e');
    }
  }

  /// Clear all verification records for an email (useful for fresh signup attempts)
  static Future<void> clearVerificationRecords(String email) async {
    try {
      await _firestore.collection(_collectionName).doc(email).delete();
      print('Cleared old verification records for $email');
    } catch (e) {
      print('Error clearing verification records: $e');
    }
  }
}
