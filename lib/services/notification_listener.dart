import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'notification_service.dart';

class FirestoreNotificationListener {
  static final Map<String, String> _lastNotifiedStatus = {};
  static void startListening(String userId) {
    FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.modified) {
          final data = docChange.doc.data();
          if (data == null) return;

          final bookingId = data['id'] ?? "";
          final status = data['status'] ?? "";
          final car = data['vehicleName'] ?? "car";
          final preferredDateTime = (data['preferredDateTime'] as Timestamp?)?.toDate();

          // Skip if already notified for this status
          if (_lastNotifiedStatus[bookingId] == status) {
            debugPrint("🚫 Notification already sent for booking $bookingId with status $status");
            continue;
          }

          _lastNotifiedStatus[bookingId] = status; // Mark as notified

          switch (status) {
            case "pending":
              break;

            case "completed":
              await NotificationService.serviceCompleteNotification(
                  userId, bookingId, car);
              break;

            case "ready_for_collection":
              await NotificationService.updateNotification(
                  userId, bookingId, car, status);

              final invoiceSnap = await FirebaseFirestore.instance
                  .collection('invoices')
                  .where('bookingId', isEqualTo: bookingId)
                  .limit(1)
                  .get();

              if (invoiceSnap.docs.isNotEmpty) {
                final invoiceId = invoiceSnap.docs.first.id;
                await NotificationService.invoiceNotification(userId, invoiceId);
              }
              break;

            default:
              await NotificationService.updateNotification(
                  userId, bookingId, car, status);
          }

          // handle reminders
          if (preferredDateTime != null) {
            await NotificationService.scheduleReminderNotification(
              bookingId.hashCode,
              car,
              preferredDateTime,
            );
          }
        }
      }
    });

    // Listen for admin messages
    FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('user', isEqualTo: 'Admin')
        .snapshots()
        .listen((messageSnapshot) async {
      for (var msgChange in messageSnapshot.docChanges) {
        if (msgChange.type != DocumentChangeType.added) continue;

        final msgData = msgChange.doc.data();
        if (msgData == null || (msgData['notified'] ?? false)) continue;

        // Get parent feedback document
        final feedbackRef = msgChange.doc.reference.parent.parent;
        if (feedbackRef == null) continue;

        final feedbackDoc = await feedbackRef.get();

        // Only notify if feedback belongs to this user
        if (feedbackDoc['userId'] != userId) continue;

        final issueTitle = feedbackDoc['title'] ?? "Feedback";

        // Update feedback status if pending
        if (feedbackDoc['status'] == "Pending") {
          await feedbackRef.update({"status": "Responded"});
        }

        // Send notification
        await NotificationService.replyNotification(
            userId, feedbackRef.id, issueTitle);

        // Mark message as notified
        await msgChange.doc.reference.update({"notified": true});
      }
    });
  }
}
