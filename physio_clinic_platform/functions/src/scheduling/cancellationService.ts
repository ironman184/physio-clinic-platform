import * as admin from "firebase-admin";
import {generateCandidateDates} from "../utils/dateUtils";
import {checkAvailability} from "./availabilityService";
import {createSessions, updateSessionStatus} from "./sessionService";

const db = admin.firestore();

/**
 * Cancel a single session and extend the plan by 1.
 */
export async function cancelSession(
  sessionId: string,
  reason: string,
  cancelledBy: string,
  clinicId: string
): Promise<{newSessionId: string}> {
  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (!sessionDoc.exists) throw new Error("Session not found");

  const session = sessionDoc.data()!;

  // Validate: session must be future + modifiable
  const today = new Date().toISOString().split("T")[0];
  if (session.date <= today) {
    throw new Error("Cannot cancel a past session");
  }
  if (!["scheduled", "rescheduled"].includes(session.status)) {
    throw new Error("Session is not in a cancellable state");
  }

  // Mark cancelled
  await updateSessionStatus(sessionId, "cancelled", {
    cancelledAt: admin.firestore.Timestamp.now(),
    cancelledBy,
    cancelReason: reason,
  });

  // Update plan counters
  const planRef = db.collection("treatmentPlans").doc(session.planId);
  await planRef.update({
    cancelledSessions: admin.firestore.FieldValue.increment(1),
  });

  // Extend plan by 1 session
  const newSessionIds = await extendPlan(session.planId, 1);

  return {newSessionId: newSessionIds[0]};
}

/**
 * Cancel a range of sessions and extend plan accordingly.
 * Uses getAll() for a single round-trip validation, then atomic batch cancel.
 */
export async function cancelRange(
  planId: string,
  sessionIds: string[],
  reason: string,
  cancelledBy: string,
  clinicId: string
): Promise<{newSessionIds: string[]}> {
  // Batch-fetch all session docs in one round-trip
  const refs = sessionIds.map((sid) => db.collection("sessions").doc(sid));
  const docs = await db.getAll(...refs);

  // Validate all sessions belong to this plan and are cancellable
  const today = new Date().toISOString().split("T")[0];
  for (const doc of docs) {
    if (!doc.exists) {
      throw new Error(`Session ${doc.id} not found`);
    }
    const data = doc.data()!;
    if (data.planId !== planId) {
      throw new Error(
        `Session ${doc.id} does not belong to plan ${planId}`
      );
    }
    if (data.date <= today) {
      throw new Error(
        `Session ${doc.id} is in the past and cannot be cancelled`
      );
    }
    if (!["scheduled", "rescheduled"].includes(data.status)) {
      throw new Error(
        `Session ${doc.id} is not in a cancellable state`
      );
    }
  }

  // Batch cancel (atomic)
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  for (const doc of docs) {
    batch.update(doc.ref, {
      status: "cancelled",
      cancelledAt: now,
      cancelledBy,
      cancelReason: reason,
      updatedAt: now,
    });
  }
  await batch.commit();

  // Update plan counters
  const planRef = db.collection("treatmentPlans").doc(planId);
  await planRef.update({
    cancelledSessions: admin.firestore.FieldValue.increment(sessionIds.length),
  });

  // Extend plan
  const newSessionIds = await extendPlan(planId, sessionIds.length);
  return {newSessionIds};
}

/**
 * Reusable: extend a plan by N sessions.
 * Used by: cancellation, range cancellation, no-show, manual extension.
 *
 * Flow:
 * 1. Find the highest sessionNo in the plan (any status)
 * 2. Find the last scheduled/rescheduled session date
 * 3. Generate next N recurrence dates using schedule rule
 * 4. Check therapist availability for each (with increased candidate pool)
 * 5. Create new session documents
 */
export async function extendPlan(
  planId: string,
  count: number
): Promise<string[]> {
  // Load plan
  const planDoc = await db.collection("treatmentPlans").doc(planId).get();
  if (!planDoc.exists) throw new Error("Plan not found");
  const plan = planDoc.data()!;

  // Find the highest sessionNo across ALL statuses (avoids duplicates)
  const maxSessionNoSnap = await db
    .collection("sessions")
    .where("planId", "==", planId)
    .orderBy("sessionNo", "desc")
    .limit(1)
    .get();

  const nextSessionNo = maxSessionNoSnap.empty
    ? 1
    : maxSessionNoSnap.docs[0].data().sessionNo + 1;

  // Find the last active session date to start generating after it
  const lastDateSnap = await db
    .collection("sessions")
    .where("planId", "==", planId)
    .where("status", "in", ["scheduled", "rescheduled", "completed"])
    .orderBy("date", "desc")
    .limit(1)
    .get();

  let startAfter: string;
  if (lastDateSnap.empty) {
    startAfter = plan.scheduleRule.day1;
  } else {
    const lastDate = new Date(
      lastDateSnap.docs[0].data().date + "T00:00:00Z"
    );
    lastDate.setUTCDate(lastDate.getUTCDate() + 1);
    startAfter = lastDate.toISOString().split("T")[0];
  }

  // Pre-fetch therapist availability for cache
  const availDoc = await db
    .collection("therapistAvailability")
    .doc(plan.therapistId)
    .get();
  const cachedSchedule = availDoc.exists
    ? availDoc.data()?.weeklySchedule ?? {}
    : undefined;

  // Generate candidates with progressive expansion
  let availableDates: string[] = [];
  let multiplier = 4;
  const MAX_MULTIPLIER = 20;

  while (availableDates.length < count && multiplier <= MAX_MULTIPLIER) {
    const candidates = generateCandidateDates(
      startAfter,
      plan.scheduleRule.days,
      count * multiplier
    );

    availableDates = [];
    for (const date of candidates) {
      if (availableDates.length >= count) break;
      const result = await checkAvailability(
        plan.clinicId,
        plan.therapistId,
        date,
        plan.scheduleRule.slotId,
        {cachedSchedule, forPatientId: plan.patientId}
      );
      if (result.available) {
        availableDates.push(date);
      }
    }
    multiplier += 4;
  }

  if (availableDates.length < count) {
    throw new Error(
      `Could only find ${availableDates.length} available slots out of ` +
        `${count} needed. Therapist schedule may be full for the next 365 days.`
    );
  }

  // Create sessions
  const sessionIds = await createSessions(
    planId,
    plan.clinicId,
    plan.patientId,
    plan.therapistId,
    plan.scheduleRule.slotId,
    availableDates,
    nextSessionNo
  );

  // Update plan total
  await db
    .collection("treatmentPlans")
    .doc(planId)
    .update({
      totalSessions: admin.firestore.FieldValue.increment(count),
    });

  return sessionIds;
}
