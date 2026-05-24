import * as admin from "firebase-admin";

const db = admin.firestore();
const BATCH_LIMIT = 500;

/**
 * Create session documents in batches for a treatment plan.
 * Handles Firestore's 500-write batch limit by chunking.
 */
export async function createSessions(
  planId: string,
  clinicId: string,
  patientId: string,
  therapistId: string,
  slotId: string,
  dates: string[],
  startingSessionNo: number = 1
): Promise<string[]> {
  const sessionIds: string[] = [];
  const now = admin.firestore.Timestamp.now();

  // Chunk into batches of 500
  for (let chunk = 0; chunk < dates.length; chunk += BATCH_LIMIT) {
    const batch = db.batch();
    const slice = dates.slice(chunk, chunk + BATCH_LIMIT);

    for (let i = 0; i < slice.length; i++) {
      const ref = db.collection("sessions").doc();
      sessionIds.push(ref.id);

      batch.set(ref, {
        clinicId,
        planId,
        patientId,
        therapistId,
        sessionNo: startingSessionNo + chunk + i,
        date: slice[i],
        slotId,
        status: "scheduled",
        createdAt: now,
        updatedAt: now,
      });
    }

    await batch.commit();
  }

  return sessionIds;
}

/**
 * Mark a session with a given status.
 */
export async function updateSessionStatus(
  sessionId: string,
  status: string,
  extra: Record<string, unknown> = {}
): Promise<void> {
  await db
    .collection("sessions")
    .doc(sessionId)
    .update({
      status,
      updatedAt: admin.firestore.Timestamp.now(),
      ...extra,
    });
}
