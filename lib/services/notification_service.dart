import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  static final _firestore = FirebaseFirestore.instance;
  static final Map<String, DateTime> _lastScheduledReminder = {};

  static Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        navigatorKey.currentState?.pushNamed("/notificationPage");
      },
    );

    // Request notification permission
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint("✅ Notification permission granted on Android");
      } else {
        debugPrint("❌ Notification permission denied on Android");
      }
    } else if (Platform.isIOS) {
      final iosPlugin =
      _localNotif.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint("📱 iOS notification permissions: $granted");
      }
    }

    tz.initializeTimeZones();
  }

  static Future<void> showNotification(
      String title,
      String body, {
        String? userId,
        String? type,
        String? referenceId,
      }) async {
    // Deduplicate: Only send if not sent in the last X seconds
    final key = referenceId ?? title; // Use booking ID or reference
    final now = DateTime.now();

    if (_lastScheduledReminder.containsKey(key)) {
      final lastTime = _lastScheduledReminder[key]!;
      if (now.difference(lastTime).inSeconds < 10) {
        debugPrint("🚫 Notification already sent recently for $key");
        return; // Skip duplicate
      }
    }

    _lastScheduledReminder[key] = now; // Mark as sent

    try {
      const androidDetails = AndroidNotificationDetails(
        'demo_channel',
        'Demo Notifications',
        channelDescription: 'Used for demo purpose notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const generalDetails = NotificationDetails(android: androidDetails);

      await _localNotif.show(0, title, body, generalDetails);
    } catch (e) {
      debugPrint("Local notification failed: $e");
    }

    if (userId != null) {
      await _firestore.collection("notification").add({
        "userId": userId,
        "title": title,
        "message": body,
        "type": type ?? "reminder",
        "referenceId": referenceId ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });
    }
  }


  static Future<void> scheduleReminderNotification(
      int bookingId,
      String car,
      DateTime preferredDateTime,
      ) async {
    final now = DateTime.now();
    final key = bookingId.toString();

    // Prevent duplicate scheduling
    final lastScheduled = _lastScheduledReminder[key];
    if (lastScheduled != null && lastScheduled == preferredDateTime) {
      debugPrint("Skipping, already scheduled for same time: $preferredDateTime");
      return;
    }

    // Cancel any existing reminder for this booking
    await _localNotif.cancel(bookingId);

    // Always schedule 1 hour before the service
    DateTime reminderTime = preferredDateTime.subtract(const Duration(hours: 1));

    // If 1-hour-before is already past, fire immediately
    if (reminderTime.isBefore(now)) {
      reminderTime = now.add(const Duration(seconds: 1));
    }

    // Notification body
    final body = "Reminder: Your $car service is at "
        "${preferredDateTime.hour.toString().padLeft(2, '0')}:"
        "${preferredDateTime.minute.toString().padLeft(2, '0')}.";

    final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Service Reminders',
      channelDescription: 'Notifies users about upcoming car services',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotif.zonedSchedule(
      bookingId,
      "Service Reminder",
      body,
      scheduledTime,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Remember last scheduled
    _lastScheduledReminder[key] = preferredDateTime;

    debugPrint("🔔 Scheduled reminder for booking $bookingId at $scheduledTime");
  }

  /// Cancel reminder for a booking
  static Future<void> cancelReminderNotification(int bookingId) async {
    await _localNotif.cancel(bookingId);
  }

  /// Reschedule reminder (cancel + schedule again)
  static Future<void> rescheduleReminderNotification(
      int bookingId,
      String car,
      DateTime newPreferredDateTime,
      ) async {
    await cancelReminderNotification(bookingId);
    await scheduleReminderNotification(bookingId, car, newPreferredDateTime);
  }


  static Future<void> bookingNotification(String userId,String bookingId, String vehicleName) async {
    await showNotification("Booking Confirmed", "Your booking for $vehicleName is confirmed!", userId: userId,
      type: "booking",referenceId: bookingId,);

  }

  static Future<void> invoiceNotification(String userId,String invoiceId) async {
    await showNotification("Invoice Ready", "Invoice #$invoiceId is now available.",userId: userId,
      type: "invoice",referenceId: invoiceId,);
  }

  static Future<void> serviceCompleteNotification(String userId,String bookingId, String car) async {
    await showNotification("Service Complete", "$car servicing is complete.Tap here to share feedback.", userId: userId,
      type: "service", referenceId: bookingId,);
  }

  static Future<void> partsNotification(String userId, String bookingId, String car) async {
    await showNotification("Waiting for Parts", "Parts for your $car are on order.", userId: userId,
      type: "parts", referenceId: bookingId,);
  }

  static Future<void> updateNotification(String userId, String bookingId,String car, String status) async {
    await showNotification("Status Update", "Your $car is now $status.", userId: userId,
        type: "update",referenceId: bookingId,);
  }

  static Future<void> replyNotification(String userId, String feedbackId, String issue) async {
    await showNotification("Admin Reply", "Regarding $issue, we have responded to your feedback.", userId: userId,
        type: "reply", referenceId: feedbackId,);
  }

}
