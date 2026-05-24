import * as admin from "firebase-admin";
import {getDayAbbr} from "../utils/dateUtils";

const db = admin.firestore();

interface AvailabilityResult {
  available: boolean;
  reason?: string;
}

interface CheckOptions {
  /** Pre-fetched weekly schedule to avoid redundant reads. */
  cachedSchedule?: Record<string, string[]>;
  /** Patient ID to skip renewal holds belonging to the same patient. */
  forPatientId?: string;
}

/**
 * Check if a therapist is available for a specific date + slot.
 * Checks:
 * 1. Therapist works on that day of the week
 * 2. Therapist works that slot on that day
 * 3. No existing session occupies that slot
 * 4. No active renewal hold blocks that slot (unless same patient)
 */
export async function checkAvailability(
  clinicId: string,
  therapistId: string,
  date: string,
  slotId: string,
  options: CheckOptions = {}
): Promise<AvailabilityResult> {
  // 1. Check therapist weekly schedule (use cached if provided)
  let weeklySchedule: Record<string, string[]> | undefined =
    options.cachedSchedule;

  if (!weeklySchedule) {
    const availDoc = await db
      .collection("therapistAvailability")
      .doc(therapistId)
      .get();

    if (!availDoc.exists) {
      return {
        available: false,
        reason: "Therapist availability not configured",
      };
    }
    weeklySchedule = (availDoc.data()?.weeklySchedule ?? {}) as Record<
      string,
      string[]
    >;
  }

  const dayAbbr = getDayAbbr(date);
  const daySlots: string[] = weeklySchedule[dayAbbr] ?? [];

  if (!daySlots.includes(slotId)) {
    return {
      available: false,
      reason: `Therapist does not work slot ${slotId} on ${dayAbbr}`,
    };
  }

  // 2. Check existing sessions for conflict
  const sessionConflict = await db
    .collection("sessions")
    .where("clinicId", "==", clinicId)
    .where("therapistId", "==", therapistId)
    .where("date", "==", date)
    .where("slotId", "==", slotId)
    .where("status", "in", ["scheduled", "rescheduled"])
    .limit(1)
    .get();

  if (!sessionConflict.empty) {
    return {available: false, reason: "Slot already booked"};
  }

  // 3. Check renewal holds (skip if hold belongs to same patient)
  const holdConflict = await db
    .collection("renewalHolds")
    .where("clinicId", "==", clinicId)
    .where("therapistId", "==", therapistId)
    .where("slotId", "==", slotId)
    .where("status", "==", "active")
    .limit(1)
    .get();

  if (!holdConflict.empty) {
    const hold = holdConflict.docs[0].data();
    // Skip hold if it belongs to the same patient being scheduled
    if (options.forPatientId && hold.patientId === options.forPatientId) {
      return {available: true};
    }
    const holdDays: string[] = hold.days ?? [];
    if (holdDays.includes(dayAbbr)) {
      const expiry = hold.expiryDate;
      if (date <= expiry) {
        return {available: false, reason: "Slot reserved by renewal hold"};
      }
    }
  }

  return {available: true};
}

/**
 * Pre-fetch therapist availability docs in a single batch.
 */
export async function prefetchAvailability(
  therapistIds: string[]
): Promise<Map<string, Record<string, string[]>>> {
  const refs = therapistIds.map((id) =>
    db.collection("therapistAvailability").doc(id)
  );
  const docs = await db.getAll(...refs);
  const result = new Map<string, Record<string, string[]>>();

  for (const doc of docs) {
    if (doc.exists) {
      result.set(doc.id, doc.data()?.weeklySchedule ?? {});
    }
  }
  return result;
}

/**
 * Find all available therapists for a given schedule rule.
 * Returns therapist IDs that can cover ALL candidate dates.
 *
 * Performance: pre-fetches availability docs and existing sessions in bulk
 * to minimize Firestore reads (O(T + D) queries instead of O(T × D)).
 */
export async function findAvailableTherapists(
  clinicId: string,
  candidateDates: string[],
  slotId: string,
  forPatientId?: string
): Promise<string[]> {
  // 1. Get all therapists in this clinic
  const therapists = await db
    .collection("users")
    .where("clinicId", "==", clinicId)
    .where("role", "==", "therapist")
    .where("status", "==", "active")
    .get();

  const therapistIds = therapists.docs.map((d) => d.id);
  if (therapistIds.length === 0) return [];

  // 2. Batch-fetch all availability docs (1 round-trip)
  const availMap = await prefetchAvailability(therapistIds);

  // 3. Batch-fetch all existing sessions for the date range + slot
  const minDate = candidateDates[0];
  const maxDate = candidateDates[candidateDates.length - 1];

  const existingSessionsSnap = await db
    .collection("sessions")
    .where("clinicId", "==", clinicId)
    .where("slotId", "==", slotId)
    .where("date", ">=", minDate)
    .where("date", "<=", maxDate)
    .where("status", "in", ["scheduled", "rescheduled"])
    .get();

  // Build a lookup: therapistId+date → booked
  const bookedSet = new Set<string>();
  for (const doc of existingSessionsSnap.docs) {
    const d = doc.data();
    bookedSet.add(`${d.therapistId}|${d.date}`);
  }

  // 4. Batch-fetch active renewal holds for this slot
  const holdsSnap = await db
    .collection("renewalHolds")
    .where("clinicId", "==", clinicId)
    .where("slotId", "==", slotId)
    .where("status", "==", "active")
    .get();

  // Build hold lookup: therapistId → { days, expiryDate, patientId }
  const holdsByTherapist = new Map<
    string,
    {days: string[]; expiryDate: string; patientId: string}
  >();
  for (const doc of holdsSnap.docs) {
    const h = doc.data();
    holdsByTherapist.set(h.therapistId, {
      days: h.days ?? [],
      expiryDate: h.expiryDate,
      patientId: h.patientId,
    });
  }

  // 5. Evaluate each therapist in-memory
  const available: string[] = [];

  for (const therapistId of therapistIds) {
    const schedule = availMap.get(therapistId);
    if (!schedule) continue; // no availability configured

    let allClear = true;

    for (const date of candidateDates) {
      const dayAbbr = getDayAbbr(date);

      // Check works this slot on this day
      const daySlots: string[] = schedule[dayAbbr] ?? [];
      if (!daySlots.includes(slotId)) {
        allClear = false;
        break;
      }

      // Check session conflict
      if (bookedSet.has(`${therapistId}|${date}`)) {
        allClear = false;
        break;
      }

      // Check renewal hold
      const hold = holdsByTherapist.get(therapistId);
      if (hold && hold.days.includes(dayAbbr) && date <= hold.expiryDate) {
        // Skip hold if it belongs to the same patient
        if (forPatientId && hold.patientId === forPatientId) {
          continue;
        }
        allClear = false;
        break;
      }
    }

    if (allClear) {
      available.push(therapistId);
    }
  }

  return available;
}
