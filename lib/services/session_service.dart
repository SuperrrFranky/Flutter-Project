import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionCollection = 'active_sessions';

  /// Create a custom session for a user
  static Future<bool> createSession({
    required String email,
    required String userId,
  }) async {
    try {
      // Store session in Firestore
      await _firestore.collection(_sessionCollection).doc(userId).set({
        'email': email,
        'userId': userId,
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'is_active': true,
      });

      // Also try to sign in to Firebase Auth with a dummy password
      // This is a workaround to make AuthGate work
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: 'dummy_password_for_session',
        );
      } catch (e) {
        // If this fails, we'll handle it in the AuthGate
        print('Session creation: Firebase Auth sign-in failed: $e');
      }

      return true;
    } catch (e) {
      print('Error creating session: $e');
      return false;
    }
  }

  /// Check if a session is valid
  static Future<bool> isSessionValid(String userId) async {
    try {
      final doc = await _firestore.collection(_sessionCollection).doc(userId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final expiresAt = (data['expires_at'] as Timestamp).toDate();
      final isActive = data['is_active'] as bool? ?? false;
      
      return isActive && DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  /// End a session
  static Future<void> endSession(String userId) async {
    try {
      await _firestore.collection(_sessionCollection).doc(userId).update({
        'is_active': false,
        'ended_at': FieldValue.serverTimestamp(),
      });
      
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  /// Get current user from session
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user data from Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return null;

      return userQuery.docs.first.data();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Clean up expired sessions
  static Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection(_sessionCollection)
          .where('expires_at', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'is_active': false});
      }
    } catch (e) {
      print('Error cleaning up sessions: $e');
    }
  }
}
