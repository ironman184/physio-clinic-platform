import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Create a renewal hold when a plan completes.
 * Called automatically when the last session is marked completed.
 */
export async function createRenewalHold(planId: string): Promise<string> {
  const planDoc = await db.collection("treatmentPlans").doc(planId).get();
  if (!planDoc.exists) throw new Error("Plan not found");
  const plan = planDoc.data()!;

  // Calculate expiry: 30 days from now
  const expiry = new Date();
  expiry.setUTCDate(expiry.getUTCDate() + 30);
  const expiryStr = expiry.toISOString().split("T")[0];

  const holdRef = db.collection("renewalHolds").doc();
  await holdRef.set({
    clinicId: plan.clinicId,
    patientId: plan.patientId,
    therapistId: plan.therapistId,
    planId,
    slotId: plan.scheduleRule.slotId,
    days: plan.scheduleRule.days,
    createdAt: admin.firestore.Timestamp.now(),
    expiryDate: expiryStr,
    status: "active",
  });

  return holdRef.id;
}

/**
 * Scheduled function: expire old renewal holds.
 * Run daily via Cloud Scheduler.
 * Handles >500 expired holds by chunking batches.
 */
export async function expireOldHolds(): Promise<number> {
  const today = new Date().toISOString().split("T")[0];
  const expired = await db
    .collection("renewalHolds")
    .where("status", "==", "active")
    .where("expiryDate", "<", today)
    .get();

  // Chunk into batches of 500 (Firestore batch limit)
  const BATCH_LIMIT = 500;
  for (let i = 0; i < expired.docs.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    const chunk = expired.docs.slice(i, i + BATCH_LIMIT);
    for (const doc of chunk) {
      batch.update(doc.ref, {status: "expired"});
    }
    await batch.commit();
  }

  return expired.size;
}
