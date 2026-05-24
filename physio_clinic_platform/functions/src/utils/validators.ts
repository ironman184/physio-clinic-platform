import {HttpsError} from "firebase-functions/v2/https";
import {ScheduleRule} from "../types";

/**
 * Validate the schedule rule input from the client.
 */
export function validateScheduleRule(rule: ScheduleRule | undefined): void {
  if (!rule) {
    throw new HttpsError("invalid-argument", "Missing scheduleRule");
  }
  if (!rule.day1 || !rule.days?.length || !rule.slotId) {
    throw new HttpsError("invalid-argument", "Incomplete schedule rule");
  }

  const validDays = new Set(["mon", "tue", "wed", "thu", "fri", "sat", "sun"]);
  for (const d of rule.days) {
    if (!validDays.has(d)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid day: ${d}. Must be one of: mon, tue, wed, thu, fri, sat, sun`
      );
    }
  }

  const validFrequencies = new Set(["once", "twice", "thrice", "daily"]);
  if (!validFrequencies.has(rule.frequency)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid frequency: ${rule.frequency}`
    );
  }

  // Validate day1 is a valid date
  const parsed = new Date(rule.day1 + "T00:00:00Z");
  if (isNaN(parsed.getTime())) {
    throw new HttpsError("invalid-argument", `Invalid day1 date: ${rule.day1}`);
  }
}
