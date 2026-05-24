import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {setGlobalOptions} from "firebase-functions";

import {generateCandidateDates} from "./utils/dateUtils";
import {validateScheduleRule} from "./utils/validators";
import {
  findAvailableTherapists,
  checkAvailability,
} from "./scheduling/availabilityService";
import {createSessions} from "./scheduling/sessionService";
import {
  cancelSession,
  cancelRange,
  extendPlan,
} from "./scheduling/cancellationService";
import {rescheduleSession, fullReschedule} from "./scheduling/rescheduleService";
import {createRenewalHold, expireOldHolds} from "./scheduling/renewalService";
import {sendSessionNotification} from "./notifications/notificationService";

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const db = admin.firestore();

// ─── AUTH + AUTHORIZATION HELPER ────────────────────────────────────────────

/**
 * Validates the caller is authenticated and has the required role for the
 * clinic. Throws HttpsError if unauthorized.
 */
async function authorizeRequest(
  auth: {uid: string} | undefined,
  clinicId: string,
  requiredRole: "admin" | "therapist" | "any" = "admin"
): Promise<string> {
  if (!auth?.uid) {
    throw new HttpsError("unauthenticated", "Must be logged in");
  }
  const callerDoc = await db.collection("users").doc(auth.uid).get();
  if (!callerDoc.exists) {
    throw new HttpsError("permission-denied", "User profile not found");
  }
  const callerData = callerDoc.data()!;

  if (callerData.clinicId !== clinicId) {
    throw new HttpsError(
      "permission-denied",
      "Not authorized for this clinic"
    );
  }
  if (requiredRole !== "any" && callerData.role !== requiredRole) {
    throw new HttpsError(
      "permission-denied",
      `Requires ${requiredRole} role`
    );
  }
  return auth.uid;
}

// ─── CREATE TREATMENT PLAN ──────────────────────────────────────────────────

export const createPlan = onCall(async (request) => {
  const data = request.data;
  const {
    clinicId,
    patientId,
    therapistId,
    totalSessions,
    remainingNoShows,
    scheduleRule,
    idempotencyKey,
  } = data;

  // Authorize: must be admin for this clinic
  const uid = await authorizeRequest(request.auth, clinicId, "admin");

  // Validate inputs
  if (!clinicId || !patientId || !therapistId || !totalSessions) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }
  validateScheduleRule(scheduleRule);

  // Idempotency check: prevent duplicate plans from retried requests
  if (idempotencyKey) {
    const existing = await db
      .collection("treatmentPlans")
      .where("idempotencyKey", "==", idempotencyKey)
      .limit(1)
      .get();
    if (!existing.empty) {
      const existingPlan = existing.docs[0];
      return {planId: existingPlan.id, duplicate: true};
    }
  }

  // Generate candidate dates
  const candidateDates = generateCandidateDates(
    scheduleRule.day1,
    scheduleRule.days,
    totalSessions
  );

  if (candidateDates.length < totalSessions) {
    throw new HttpsError(
      "failed-precondition",
      `Could only generate ${candidateDates.length} dates within 365-day window`
    );
  }

  // Pre-fetch therapist availability for performance
  const availDoc = await db
    .collection("therapistAvailability")
    .doc(therapistId)
    .get();
  if (!availDoc.exists) {
    throw new HttpsError(
      "failed-precondition",
      "Therapist availability not configured"
    );
  }
  const cachedSchedule = availDoc.data()?.weeklySchedule ?? {};

  // Verify therapist availability for all dates
  for (const date of candidateDates) {
    const result = await checkAvailability(
      clinicId,
      therapistId,
      date,
      scheduleRule.slotId,
      {cachedSchedule, forPatientId: patientId}
    );
    if (!result.available) {
      throw new HttpsError(
        "failed-precondition",
        `Therapist unavailable on ${date}: ${result.reason}`
      );
    }
  }

  // Create plan document
  const planRef = db.collection("treatmentPlans").doc();
  const now = admin.firestore.Timestamp.now();

  await planRef.set({
    clinicId,
    patientId,
    therapistId,
    totalSessions,
    completedSessions: 0,
    cancelledSessions: 0,
    noShowCount: 0,
    remainingNoShows: remainingNoShows ?? 2,
    status: "active",
    scheduleRule,
    createdAt: now,
    createdBy: uid,
    ...(idempotencyKey && {idempotencyKey}),
  });

  // Create all session documents
  const sessionIds = await createSessions(
    planRef.id,
    clinicId,
    patientId,
    therapistId,
    scheduleRule.slotId,
    candidateDates
  );

  // Send notification to patient about scheduled sessions
  await sendSessionNotification(
    sessionIds[0],
    patientId,
    "scheduled",
    candidateDates[0],
    scheduleRule.slotId
  );

  return {planId: planRef.id, sessionIds, dates: candidateDates};
});

// ─── GET AVAILABLE THERAPISTS ───────────────────────────────────────────────

export const getAvailableTherapists = onCall(async (request) => {
  const {clinicId, scheduleRule, totalSessions} = request.data;

  // Authorize: any role in this clinic can query availability
  await authorizeRequest(request.auth, clinicId, "any");

  validateScheduleRule(scheduleRule);

  const candidateDates = generateCandidateDates(
    scheduleRule.day1,
    scheduleRule.days,
    totalSessions
  );

  const therapistIds = await findAvailableTherapists(
    clinicId,
    candidateDates,
    scheduleRule.slotId,
    request.data.patientId
  );

  // Batch-fetch therapist details
  const therapists = [];
  if (therapistIds.length > 0) {
    const refs = therapistIds.map((id) => db.collection("users").doc(id));
    const docs = await db.getAll(...refs);
    for (const doc of docs) {
      if (doc.exists) {
        const d = doc.data()!;
        therapists.push({
          id: doc.id,
          firstName: d.firstName,
          lastName: d.lastName,
        });
      }
    }
  }

  return {therapists, candidateDates};
});

// ─── RESCHEDULE SINGLE SESSION ──────────────────────────────────────────────

export const rescheduleSessionFn = onCall(async (request) => {
  const {sessionId, newDate, newSlotId, clinicId} = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  const result = await rescheduleSession(
    sessionId,
    newDate,
    newSlotId,
    clinicId
  );

  // Notify patient
  const sessionDoc = await db
    .collection("sessions")
    .doc(result.newSessionId)
    .get();
  if (sessionDoc.exists) {
    const s = sessionDoc.data()!;
    await sendSessionNotification(
      result.newSessionId,
      s.patientId,
      "rescheduled",
      newDate,
      newSlotId
    );
  }

  return result;
});

// ─── FULL RESCHEDULE ────────────────────────────────────────────────────────

export const fullRescheduleFn = onCall(async (request) => {
  const {planId, newDay1, newDays, newSlotId, clinicId} = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  return fullReschedule(planId, newDay1, newDays, newSlotId, clinicId);
});

// ─── CANCEL SINGLE SESSION ─────────────────────────────────────────────────

export const cancelSessionFn = onCall(async (request) => {
  const {sessionId, reason, clinicId} = request.data;
  const uid = await authorizeRequest(request.auth, clinicId, "admin");
  const result = await cancelSession(sessionId, reason, uid, clinicId);

  // Notify patient
  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (sessionDoc.exists) {
    const s = sessionDoc.data()!;
    await sendSessionNotification(
      sessionId,
      s.patientId,
      "cancelled",
      s.date,
      s.slotId
    );
  }

  return result;
});

// ─── CANCEL RANGE ───────────────────────────────────────────────────────────

export const cancelRangeFn = onCall(async (request) => {
  const {planId, sessionIds, reason, clinicId} = request.data;
  const uid = await authorizeRequest(request.auth, clinicId, "admin");
  return cancelRange(planId, sessionIds, reason, uid, clinicId);
});

// ─── MARK SESSION COMPLETED / NO-SHOW ──────────────────────────────────────

export const markSession = onCall(async (request) => {
  const {sessionId, status, clinicId} = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");

  if (!["completed", "no_show"].includes(status)) {
    throw new HttpsError(
      "invalid-argument",
      "Status must be completed or no_show"
    );
  }

  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (!sessionDoc.exists) {
    throw new HttpsError("not-found", "Session not found");
  }

  const session = sessionDoc.data()!;

  // Use a TRANSACTION to atomically update session + plan counters
  await db.runTransaction(async (tx) => {
    const planRef = db.collection("treatmentPlans").doc(session.planId);
    const planSnap = await tx.get(planRef);
    if (!planSnap.exists) {
      throw new HttpsError("not-found", "Plan not found");
    }
    const plan = planSnap.data()!;

    // Update session status
    tx.update(db.collection("sessions").doc(sessionId), {
      status,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    if (status === "completed") {
      const newCompleted = (plan.completedSessions ?? 0) + 1;
      const totalDone =
        newCompleted +
        (plan.cancelledSessions ?? 0) +
        (plan.noShowCount ?? 0);

      const planUpdate: Record<string, unknown> = {
        completedSessions: newCompleted,
      };

      // Check if plan is now complete
      if (totalDone >= plan.totalSessions) {
        planUpdate.status = "completed";
      }

      tx.update(planRef, planUpdate);
    } else if (status === "no_show") {
      tx.update(planRef, {
        noShowCount: admin.firestore.FieldValue.increment(1),
        remainingNoShows: admin.firestore.FieldValue.increment(-1),
      });
    }
  });

  // Post-transaction actions (cannot be inside transaction)
  if (status === "completed") {
    // Re-read to check if plan just completed
    const planDoc = await db
      .collection("treatmentPlans")
      .doc(session.planId)
      .get();
    if (planDoc.data()?.status === "completed") {
      await createRenewalHold(session.planId);
    }
  } else if (status === "no_show") {
    // Extend plan by 1 to replace the no-show
    await extendPlan(session.planId, 1);
  }

  // Notify patient
  await sendSessionNotification(
    sessionId,
    session.patientId,
    status,
    session.date,
    session.slotId
  );

  return {success: true};
});

// ─── EXPIRE RENEWAL HOLDS (scheduled daily) ────────────────────────────────

export const expireRenewalHolds = onSchedule("every day 02:00", async () => {
  const count = await expireOldHolds();
  console.log(`Expired ${count} renewal holds`);
});
