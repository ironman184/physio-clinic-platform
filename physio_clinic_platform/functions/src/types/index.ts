export interface ScheduleRule {
  frequency: "once" | "twice" | "thrice" | "daily";
  days: string[]; // ['mon', 'wed', 'fri']
  day1: string; // '2026-06-01'
  slotId: string; // 'slot_03'
}

export interface CreatePlanRequest {
  clinicId: string;
  patientId: string;
  therapistId: string;
  totalSessions: number;
  remainingNoShows: number;
  scheduleRule: ScheduleRule;
  idempotencyKey?: string;
}

export interface RescheduleRequest {
  sessionId: string;
  newDate: string;
  newSlotId: string;
  clinicId: string;
}

export interface CancelRequest {
  sessionId: string;
  reason: string;
  clinicId: string;
}

export interface CancelRangeRequest {
  planId: string;
  sessionIds: string[];
  reason: string;
  clinicId: string;
}

export interface SessionDoc {
  clinicId: string;
  planId: string;
  patientId: string;
  therapistId: string;
  sessionNo: number;
  date: string;
  slotId: string;
  status: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  rescheduledFrom?: string;
  cancelledAt?: FirebaseFirestore.Timestamp;
  cancelledBy?: string;
  cancelReason?: string;
}
