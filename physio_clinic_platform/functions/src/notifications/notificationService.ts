import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Send push notification to a patient about a session event.
 * Supports multiple device tokens (fcmTokens array).
 */
export async function sendSessionNotification(
  sessionId: string,
  patientId: string,
  status: string,
  date: string,
  slotId: string
): Promise<void> {
  // Get patient FCM tokens (supports multiple logged-in devices)
  const userDoc = await db.collection("users").doc(patientId).get();
  if (!userDoc.exists) return;

  const fcmTokens: string[] = userDoc.data()?.fcmTokens ?? [];
  if (fcmTokens.length === 0) return;

  // Get slot details for display
  const slotDoc = await db.collection("slots").doc(slotId).get();
  const slotTime = slotDoc.exists
    ? `${slotDoc.data()?.start} – ${slotDoc.data()?.end}`
    : slotId;

  const messages: Record<string, {title: string; body: string}> = {
    scheduled: {
      title: "Session Scheduled",
      body: `Your session on ${date} at ${slotTime} has been scheduled.`,
    },
    rescheduled: {
      title: "Session Rescheduled",
      body: `Your session has been rescheduled to ${date} at ${slotTime}.`,
    },
    cancelled: {
      title: "Session Cancelled",
      body: `Your session on ${date} at ${slotTime} has been cancelled.`,
    },
    completed: {
      title: "Session Completed",
      body: `Your session on ${date} has been marked as completed.`,
    },
    no_show: {
      title: "Missed Session",
      body: `You were marked absent for your session on ${date}. ` +
        "A replacement session will be scheduled.",
    },
  };

  const msg = messages[status];
  if (!msg) return;

  // Send to all registered devices using sendEachForMulticast
  const response = await admin.messaging().sendEachForMulticast({
    tokens: fcmTokens,
    notification: {
      title: msg.title,
      body: msg.body,
    },
    data: {
      sessionId,
      status,
      date,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  });

  // Collect stale tokens for cleanup
  const staleTokens: string[] = [];
  response.responses.forEach((resp, idx) => {
    if (
      !resp.success &&
      resp.error &&
      (resp.error.code === "messaging/invalid-registration-token" ||
        resp.error.code === "messaging/registration-token-not-registered")
    ) {
      staleTokens.push(fcmTokens[idx]);
    }
  });

  // Remove stale tokens from the user doc
  if (staleTokens.length > 0) {
    await db
      .collection("users")
      .doc(patientId)
      .update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(staleTokens),
      });
  }

  if (response.failureCount > 0) {
    console.warn(
      `FCM: ${response.successCount} sent, ` +
        `${response.failureCount} failed for ${patientId}`
    );
  }
}
