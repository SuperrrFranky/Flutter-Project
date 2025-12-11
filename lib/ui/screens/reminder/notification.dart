import 'package:assignment/ui/screens/payment/billing.dart';
import 'package:assignment/ui/screens/progress/progress.dart';
import 'package:assignment/ui/screens/services/car_services_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../models/booking_model.dart';
import '../feedback/feedback.dart';

final user = FirebaseAuth.instance.currentUser!;

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notification")
            .orderBy("createdAt", descending: true)
            .where("userId", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final type = doc["type"] ?? "reminder";
              final title = doc["title"] ?? "";
              final message = doc["message"] ?? "";
              final time = _formatTimestamp(doc["createdAt"]);

              return InkWell(
                onTap: () async {

                  if (doc["isRead"] != true) {
                    await doc.reference.update({"isRead": true});
                  }

                  switch (type) {
                    case "booking":
                      final bookingId = doc["bookingId"];
                      if (bookingId != null) {
                        final bookingDoc = await FirebaseFirestore.instance
                            .collection("bookings")
                            .doc(bookingId)
                            .get();

                        if (bookingDoc.exists) {
                          final booking = BookingModel.fromMap(
                            bookingDoc.data()!,
                            bookingDoc.id,
                          );

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CarServicesDetailsScreen(booking: booking),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking not found")),
                          );
                        }
                      }
                      break;
                    case "invoice":
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Billing()),
                      );
                      break;
                    case "service":
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FeedbackPage(initialTabIndex: 0)),
                      );
                      break;
                    case "reminder":
                      final bookingId = doc["bookingId"];
                      if (bookingId != null) {
                        final bookingDoc = await FirebaseFirestore.instance
                            .collection("bookings")
                            .doc(bookingId)
                            .get();

                        if (bookingDoc.exists) {
                          final booking = BookingModel.fromMap(
                            bookingDoc.data()!,
                            bookingDoc.id,
                          );

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CarServicesDetailsScreen(booking: booking),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Booking not found")),
                          );
                        }
                      }
                      break;
                    case "update":
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ServiceProgressScreen()),
                      );
                      break;
                    case "reply":
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FeedbackPage(initialTabIndex: 1)),
                      );
                    default:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No page linked for this notification")),
                      );
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotificationIcon(type),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: doc["isRead"] == true
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/icons/time_icon.png',
                                        width: 14,
                                        height: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (doc["isRead"] != true)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: doc["isRead"] == true
                                      ? Colors.grey[800]
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/empty_notification_icon.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            "No notifications yet",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            "You have no notification right now.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Text(
            "Come back later.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final dateTime = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60 && now.day == dateTime.day) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24 && now.day == dateTime.day) {
      return "${difference.inHours} hour${difference.inHours > 1 ? "s" : ""} ago";
    } else if (now.difference(dateTime).inHours < 48 &&
        now.day - dateTime.day == 1) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  static Widget _buildNotificationIcon(String type) {
    Color bgColor;
    String assetPath;

    switch (type) {
      case "booking":
        bgColor = const Color(0xFF58A6FB);
        assetPath = 'assets/icons/book_confirmed_icon.png';
        break;
      case "invoice":
        bgColor = const Color(0xFF957BF9);
        assetPath = 'assets/icons/invoice_ready_icon.png';
        break;
      case "service":
        bgColor = const Color(0xFF3FAD46);
        assetPath = 'assets/icons/service_complete_icon.png';
        break;
      case "reminder":
        bgColor = const Color(0xFF58A6FB);
        assetPath = 'assets/icons/reminder_icon.png';
        break;
      case "update":
        bgColor = const Color(0xFFFFE100);
        assetPath = 'assets/icons/status_update_icon.png';
        break;
      case "reply":
        bgColor = const Color(0xFF58A6FB);
        assetPath = 'assets/icons/reply_message_icon.png';
      default:
        bgColor = Colors.grey.shade300;
        assetPath = 'assets/icons/reminder_icon.png';
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}
