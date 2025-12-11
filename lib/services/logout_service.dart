import 'package:cloud_firestore/cloud_firestore.dart';

class LogoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionCollection = 'active_sessions';

  /// Logout user by deactivating their session
  static Future<void> logout(String userId) async {
    try {
      await _firestore.collection(_sessionCollection).doc(userId).update({
        'is_active': false,
        'ended_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Logout all sessions for a user
  static Future<void> logoutAllSessions(String userId) async {
    try {
      final sessions = await _firestore
          .collection(_sessionCollection)
          .where('userId', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      for (final doc in sessions.docs) {
        await doc.reference.update({
          'is_active': false,
          'ended_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error during logout all sessions: $e');
    }
  }

  /// Clean up expired sessions
  static Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now();
      final expiredSessions = await _firestore
          .collection(_sessionCollection)
          .where('expires_at', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in expiredSessions.docs) {
        await doc.reference.update({
          'is_active': false,
          'ended_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error cleaning up expired sessions: $e');
    }
  }
}
