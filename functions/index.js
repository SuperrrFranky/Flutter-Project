// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Firestore trigger:
 * When a new notification doc is created,
 *  - Find the user's FCM token
 *  - Send push notification
 *  - Update notification doc with delivery result
 */
exports.sendNotificationOnCreate = functions.firestore
  .document("notification/{docId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const notifRef = snap.ref;
    const docId = context.params.docId;

    const title = data.title || "Notification";
    const message = data.message || "";
    const userId = data.userId || null;

    if (!userId) {
      await notifRef.update({ delivered: false, error: "no-userId" });
      return null;
    }

    // Get user token
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.exists ? userDoc.get("fcmToken") : null;

    if (!fcmToken) {
      await notifRef.update({ delivered: false, error: "no-fcmToken" });
      return null;
    }

    // Build notification
    const payload = {
      notification: { title, body: message },
      data: { notificationId: docId },
      token: fcmToken,
    };

    try {
      const response = await admin.messaging().send(payload);

      await notifRef.update({
        delivered: true,
        fcmMessageId: response,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Notification ${docId} sent to ${userId}`);
    } catch (err) {
      console.error("Error sending notification:", err);

      // Remove invalid token so future sends don’t fail
      if (
        err.code === "messaging/invalid-argument" ||
        err.code === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      await notifRef.update({
        delivered: false,
        error: err.message || String(err),
      });
    }

    return null;
  });
