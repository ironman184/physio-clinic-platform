import * as admin from "firebase-admin";
import {generateCandidateDates} from "../utils/dateUtils";
import {checkAvailability} from "./availabilityService";
import {createSessions, updateSessionStatus} from "./sessionService";

const db = admin.firestore();

/**
 * Reschedule a single future session to a new date/slot.
 */
export async function rescheduleSession(
  sessionId: string,
  newDate: string,
  newSlotId: string,
  clinicId: string
): Promise<{newSessionId: string}> {
  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (!sessionDoc.exists) throw new Error("Session not found");

  const session = sessionDoc.data()!;
  const today = new Date().toISOString().split("T")[0];

  if (session.date <= today) {
    throw new Error("Cannot reschedule a past session");
  }
  if (!["scheduled", "rescheduled"].includes(session.status)) {
    throw new Error("Session is not in a reschedulable state");
  }

  // Check new slot availability (skip renewal hold for same patient)
  const availability = await checkAvailability(
    clinicId,
    session.therapistId,
    newDate,
    newSlotId,
    {forPatientId: session.patientId}
  );
  if (!availability.available) {
    throw new Error(availability.reason ?? "New slot is not available");
  }

  // Mark old session as rescheduled
  await updateSessionStatus(sessionId, "rescheduled");

  // Create new session
  const newRef = db.collection("sessions").doc();
  const now = admin.firestore.Timestamp.now();

  await newRef.set({
    clinicId: session.clinicId,
    planId: session.planId,
    patientId: session.patientId,
    therapistId: session.therapistId,
    sessionNo: session.sessionNo,
    date: newDate,
    slotId: newSlotId,
    status: "scheduled",
    createdAt: now,
    updatedAt: now,
    rescheduledFrom: sessionId,
  });

  return {newSessionId: newRef.id};
}

/**
 * Full reschedule: preserve completed sessions, regenerate all future.
 * Uses max sessionNo across ALL statuses to avoid number collisions.
 */
export async function fullReschedule(
  planId: string,
  newDay1: string,
  newDays: string[],
  newSlotId: string,
  clinicId: string
): Promise<{newSessionIds: string[]}> {
  const planDoc = await db.collection("treatmentPlans").doc(planId).get();
  if (!planDoc.exists) throw new Error("Plan not found");
  const plan = planDoc.data()!;

  const today = new Date().toISOString().split("T")[0];

  // Get all future modifiable sessions
  const futureSessionsSnap = await db
    .collection("sessions")
    .where("planId", "==", planId)
    .where("date", ">", today)
    .where("status", "in", ["scheduled", "rescheduled"])
    .get();

  if (futureSessionsSnap.empty) {
    throw new Error("No future sessions to reschedule");
  }

  // Cancel all future sessions (mark as rescheduled) — chunk if >500
  const BATCH_LIMIT = 500;
  const now = admin.firestore.Timestamp.now();
  for (let i = 0; i < futureSessionsSnap.docs.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    const chunk = futureSessionsSnap.docs.slice(i, i + BATCH_LIMIT);
    for (const doc of chunk) {
      batch.update(doc.ref, {status: "rescheduled", updatedAt: now});
    }
    await batch.commit();
  }

  // Count how many new sessions to generate
  const countToRegenerate = futureSessionsSnap.size;

  // Find the highest sessionNo across ALL sessions in the plan
  const maxSessionNoSnap = await db
    .collection("sessions")
    .where("planId", "==", planId)
    .orderBy("sessionNo", "desc")
    .limit(1)
    .get();

  const startNo = maxSessionNoSnap.empty
    ? 1
    : maxSessionNoSnap.docs[0].data().sessionNo + 1;

  // Generate new dates with new rule
  const candidates = generateCandidateDates(
    newDay1,
    newDays,
    countToRegenerate * 4 // generate extra for availability filtering
  );

  // Pre-fetch therapist availability for cache
  const availDoc = await db
    .collection("therapistAvailability")
    .doc(plan.therapistId)
    .get();
  const cachedSchedule = availDoc.exists
    ? availDoc.data()?.weeklySchedule ?? {}
    : undefined;

  // Filter by availability
  const availableDates: string[] = [];
  for (const date of candidates) {
    if (availableDates.length >= countToRegenerate) break;
    const result = await checkAvailability(
      clinicId,
      plan.therapistId,
      date,
      newSlotId,
      {cachedSchedule, forPatientId: plan.patientId}
    );
    if (result.available) availableDates.push(date);
  }

  if (availableDates.length < countToRegenerate) {
    throw new Error(
      `Only ${availableDates.length} slots available, need ${countToRegenerate}`
    );
  }

  // Create new sessions
  const newSessionIds = await createSessions(
    planId,
    clinicId,
    plan.patientId,
    plan.therapistId,
    newSlotId,
    availableDates,
    startNo
  );

  // Update schedule rule on plan
  await db.collection("treatmentPlans").doc(planId).update({
    "scheduleRule.days": newDays,
    "scheduleRule.day1": newDay1,
    "scheduleRule.slotId": newSlotId,
  });

  return {newSessionIds};
}
