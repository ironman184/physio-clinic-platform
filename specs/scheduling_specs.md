# Scheduling System — Detailed Implementation Spec

**Date:** 23 May 2026
**Status:** Draft — pending review
**Scope:** Treatment plan creation, session scheduling, rescheduling, cancellation, renewal holds, notifications

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [State Management Decision](#2-state-management-decision)
3. [Cloud Functions — Language Decision](#3-cloud-functions--language-decision)
4. [Firestore Collections & Schemas](#4-firestore-collections--schemas)
5. [Dart Models](#5-dart-models)
6. [Cloud Functions — Full Implementation](#6-cloud-functions--full-implementation)
7. [Flutter Services (Client-side)](#7-flutter-services-client-side)
8. [Flutter State Management](#8-flutter-state-management)
9. [Flutter Screens & UI](#9-flutter-screens--ui)
10. [Scheduling Logic — All Cases](#10-scheduling-logic--all-cases)
11. [Notifications](#11-notifications)
12. [Firestore Security Rules](#12-firestore-security-rules)
13. [Firestore Indexes](#13-firestore-indexes)
14. [User Roles & Access](#14-user-roles--access)
15. [Migration Notes](#15-migration-notes)
16. [Open Questions](#16-open-questions)

---

## 1. Architecture Overview

```
Flutter App (UI + form handling)
    ↓
Provider (auth) + Riverpod (scheduling state)
    ↓
Cloud Functions (TypeScript) ← scheduling engine
    ↓
Firestore ← source of truth
```

**Core principles:**
- **Rules generate schedules** — schedule rules are templates; sessions are the operational truth
- **Only future sessions regenerate** — completed/no-show sessions are never modified
- **Reserve actual sessions + temporary renewal holds** — prevents double-booking
- **All scheduling logic lives in Cloud Functions** — Flutter never writes session docs directly
- **Every entity is clinic-scoped** — `clinicId` on every document

**What lives where:**

| Layer | Responsibility |
|-------|---------------|
| Flutter | UI, forms, displaying schedules/availability, calling Cloud Functions via HTTPS |
| Provider | Auth state only (existing) |
| Riverpod | Scheduling screen state (selected patient, filters, loading, therapist list) |
| Cloud Functions | Scheduling engine, availability checks, rescheduling, cancellation, renewal, notifications |
| Firestore | Source of truth for all data |

**Admin & therapist users** are created manually in Firestore by the team. The app's patient registration flow remains unchanged.

---

## 2. State Management Decision

### Comparison: Provider vs Riverpod for scheduling

| Aspect | Provider (current) | Riverpod |
|--------|-------------------|----------|
| Already in codebase | ✅ Yes | ❌ No |
| Auto-dispose | ❌ Manual | ✅ Built-in |
| Testability | Fair (needs BuildContext) | Excellent (no context needed) |
| Dependency injection | Basic | First-class (ref.watch/ref.read) |
| Compile-time safety | ❌ Runtime errors | ✅ Compile-time |
| Multiple providers of same type | Awkward | Natural |
| Learning curve for team | None | Moderate |

### Recommendation: **Riverpod for scheduling, keep Provider for auth**

**Rationale:**
- Auth is already working with Provider — no reason to break it
- Scheduling has complex interdependent states (selected patient → available therapists → available slots) which Riverpod handles elegantly with `ref.watch`
- Auto-dispose prevents memory leaks on scheduling screens
- Both can coexist: Provider at the root, Riverpod via `ProviderScope` wrapping scheduling screens

**Coexistence setup:**

```dart
// main.dart — wrap the entire app in ProviderScope
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  runApp(
    const ProviderScope(  // Riverpod scope
      child: MyApp(),      // MyApp still uses ChangeNotifierProvider for auth
    ),
  );
}
```

**pubspec.yaml additions:**
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  cloud_functions: ^5.3.3  # for calling Cloud Functions
```

---

## 3. Cloud Functions — Language Decision

### Comparison

| Aspect | TypeScript | Dart |
|--------|-----------|------|
| Firebase support | First-class, official | Community, via `functions_framework` |
| Documentation/examples | Extensive | Limited |
| Firestore Admin SDK | Mature, full-featured | `dart_firebase_admin` — less mature |
| Deployment | `firebase deploy --only functions` | Custom Docker / Cloud Run |
| Triggers (Firestore, Auth) | Native support | Limited trigger support |
| Team familiarity | Likely new | Same as Flutter |

### Recommendation: **TypeScript**

**Rationale:**
- Official Firebase support = fewer surprises
- Firestore Admin SDK in Node.js/TS is battle-tested
- Native support for Firestore triggers (needed for notifications)
- `firebase deploy` just works
- Scheduling logic is backend-only; sharing Dart models isn't a significant advantage

**Setup:**
```bash
cd physio-clinic-platform/physio_clinic_platform
firebase init functions
# Select TypeScript
# Select ESLint: Yes
# Install dependencies: Yes
```

This creates `functions/` directory with:
```
functions/
  src/
    index.ts
  package.json
  tsconfig.json
```

---

## 4. Firestore Collections & Schemas

### 4.1 `users` (existing — minor additions)

**Path:** `users/{firebaseUid}`

```json
{
  "clinicId": "clinic_002",
  "phoneNumber": "+919872626177",
  "firstName": "Test_1",
  "lastName": "Test_Last",
  "email": null,
  "gender": "other",
  "dob": "2001-01-02T00:00:00",
  "role": "patient",
  "status": "active",
  "createdAt": "2026-05-22T15:11:32",
  "fcmToken": "device_token_here"
}
```

**Changes from current schema:**
- Add `fcmToken` (string, nullable) — for push notifications
- Status values remain **lowercase**: `active`, `inactive`, `suspended`
- Roles remain **lowercase**: `patient`, `therapist`, `admin`, `super_admin`
- Admin/therapist docs are created manually in Firestore console

### 4.2 `slots`

**Path:** `slots/{slotId}`

Global slot definitions shared across all clinics.

```json
{
  "start": "10:00",
  "end": "11:00"
}
```

**Seeded manually.** Example slots:
```
slot_01: { "start": "08:00", "end": "09:00" }
slot_02: { "start": "09:00", "end": "10:00" }
slot_03: { "start": "10:00", "end": "11:00" }
slot_04: { "start": "11:00", "end": "12:00" }
slot_05: { "start": "13:00", "end": "14:00" }
slot_06: { "start": "14:00", "end": "15:00" }
slot_07: { "start": "15:00", "end": "16:00" }
slot_08: { "start": "16:00", "end": "17:00" }
```

### 4.3 `therapistAvailability`

**Path:** `therapistAvailability/{therapistId}`

Therapist's base working schedule. Document ID = therapist's Firebase UID.

```json
{
  "clinicId": "clinic_001",
  "weeklySchedule": {
    "mon": ["slot_01", "slot_02", "slot_03", "slot_04", "slot_05"],
    "tue": ["slot_01", "slot_02", "slot_03"],
    "wed": ["slot_01", "slot_02", "slot_03", "slot_04", "slot_05"],
    "thu": ["slot_01", "slot_02"],
    "fri": ["slot_01", "slot_02", "slot_03", "slot_04"],
    "sat": [],
    "sun": []
  }
}
```

**Created manually** alongside the therapist user doc.

### 4.4 `treatmentPlans`

**Path:** `treatmentPlans/{planId}`

```json
{
  "clinicId": "clinic_001",
  "patientId": "uid_patient_1",
  "therapistId": "uid_therapist_1",
  "totalSessions": 12,
  "completedSessions": 0,
  "cancelledSessions": 0,
  "noShowCount": 0,
  "remainingNoShows": 2,
  "status": "active",
  "scheduleRule": {
    "frequency": "thrice",
    "days": ["mon", "wed", "fri"],
    "day1": "2026-06-01",
    "slotId": "slot_03"
  },
  "createdAt": "2026-05-23T10:00:00",
  "createdBy": "uid_admin_1"
}
```

**Field details:**

| Field | Type | Description |
|-------|------|-------------|
| `clinicId` | string | Clinic this plan belongs to |
| `patientId` | string | Firebase UID of the patient |
| `therapistId` | string | Firebase UID of the assigned therapist |
| `totalSessions` | number | Total sessions in the plan (grows on extension) |
| `completedSessions` | number | Counter incremented on completion |
| `cancelledSessions` | number | Counter incremented on cancellation |
| `noShowCount` | number | Counter incremented on no-show |
| `remainingNoShows` | number | Allowed remaining no-shows before plan flags |
| `status` | string | `active`, `completed`, `cancelled` |
| `scheduleRule` | map | Template for generating sessions |
| `scheduleRule.frequency` | string | `once`, `twice`, `thrice`, `daily` |
| `scheduleRule.days` | array | Day abbreviations: `mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun` |
| `scheduleRule.day1` | string | ISO date string — first session date |
| `scheduleRule.slotId` | string | Preferred time slot |
| `createdAt` | timestamp | Creation timestamp |
| `createdBy` | string | UID of the admin who created it |

### 4.5 `sessions`

**Path:** `sessions/{sessionId}`

Operational truth — each document is one scheduled appointment.

```json
{
  "clinicId": "clinic_001",
  "planId": "plan_abc123",
  "patientId": "uid_patient_1",
  "therapistId": "uid_therapist_1",
  "sessionNo": 4,
  "date": "2026-06-10",
  "slotId": "slot_03",
  "status": "scheduled",
  "createdAt": "2026-05-23T10:00:00",
  "updatedAt": "2026-05-23T10:00:00",
  "rescheduledFrom": null,
  "cancelledAt": null,
  "cancelledBy": "patient",
  "cancelReason": null
}
```

**Session statuses:** `scheduled`, `completed`, `cancelled`, `rescheduled`, `no_show`

| Field | Type | Description |
|-------|------|-------------|
| `sessionNo` | number | Sequence number within the plan (1-based) |
| `date` | string | ISO date (YYYY-MM-DD) |
| `slotId` | string | References `slots/{slotId}` |
| `status` | string | Current status |
| `rescheduledFrom` | string? | Original sessionId if this was rescheduled |
| `cancelledAt` | timestamp? | When the session was cancelled |
| `cancelReason` | string? | Reason for cancellation |

### 4.6 `renewalHolds`

**Path:** `renewalHolds/{holdId}`

Temporary slot reservation after a plan completes, giving the patient priority to renew.

```json
{
  "clinicId": "clinic_001",
  "patientId": "uid_patient_1",
  "therapistId": "uid_therapist_1",
  "planId": "plan_abc123",
  "slotId": "slot_03",
  "days": ["mon", "wed", "fri"],
  "createdAt": "2026-07-01T00:00:00",
  "expiryDate": "2026-07-31",
  "status": "active"
}
```

**Expiry:** 30 days from plan completion. Status: `active`, `used`, `expired`.

---

## 5. Dart Models

### 5.1 `SlotModel`

```dart
// lib/models/slot_model.dart

class SlotModel {
  final String id;
  final String start;
  final String end;

  const SlotModel({
    required this.id,
    required this.start,
    required this.end,
  });

  factory SlotModel.fromMap(String id, Map<String, dynamic> map) {
    return SlotModel(
      id: id,
      start: map['start'] as String,
      end: map['end'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'start': start,
        'end': end,
      };

  String get display => '$start – $end';
}
```

### 5.2 `TherapistAvailabilityModel`

```dart
// lib/models/therapist_availability_model.dart

class TherapistAvailabilityModel {
  final String therapistId;
  final String clinicId;
  final Map<String, List<String>> weeklySchedule;

  const TherapistAvailabilityModel({
    required this.therapistId,
    required this.clinicId,
    required this.weeklySchedule,
  });

  factory TherapistAvailabilityModel.fromMap(
    String therapistId,
    Map<String, dynamic> map,
  ) {
    final schedule = <String, List<String>>{};
    final raw = map['weeklySchedule'] as Map<String, dynamic>? ?? {};
    for (final entry in raw.entries) {
      schedule[entry.key] = List<String>.from(entry.value as List);
    }
    return TherapistAvailabilityModel(
      therapistId: therapistId,
      clinicId: map['clinicId'] as String,
      weeklySchedule: schedule,
    );
  }

  /// Returns slot IDs for a given day abbreviation (mon, tue, etc.)
  List<String> slotsForDay(String day) => weeklySchedule[day] ?? [];

  /// Whether the therapist works on a given day
  bool worksOn(String day) => slotsForDay(day).isNotEmpty;

  /// Whether the therapist works a specific slot on a specific day
  bool worksSlotOnDay(String day, String slotId) =>
      slotsForDay(day).contains(slotId);
}
```

### 5.3 `ScheduleRule`

```dart
// lib/models/schedule_rule.dart

class ScheduleRule {
  final String frequency;
  final List<String> days;
  final String day1;
  final String slotId;

  const ScheduleRule({
    required this.frequency,
    required this.days,
    required this.day1,
    required this.slotId,
  });

  factory ScheduleRule.fromMap(Map<String, dynamic> map) {
    return ScheduleRule(
      frequency: map['frequency'] as String,
      days: List<String>.from(map['days'] as List),
      day1: map['day1'] as String,
      slotId: map['slotId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'frequency': frequency,
        'days': days,
        'day1': day1,
        'slotId': slotId,
      };
}
```

### 5.4 `TreatmentPlanModel`

```dart
// lib/models/treatment_plan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_rule.dart';

class TreatmentPlanModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String therapistId;
  final int totalSessions;
  final int completedSessions;
  final int cancelledSessions;
  final int noShowCount;
  final int remainingNoShows;
  final String status;
  final ScheduleRule scheduleRule;
  final DateTime createdAt;
  final String createdBy;

  const TreatmentPlanModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.therapistId,
    required this.totalSessions,
    required this.completedSessions,
    required this.cancelledSessions,
    required this.noShowCount,
    required this.remainingNoShows,
    required this.status,
    required this.scheduleRule,
    required this.createdAt,
    required this.createdBy,
  });

  factory TreatmentPlanModel.fromMap(String id, Map<String, dynamic> map) {
    return TreatmentPlanModel(
      id: id,
      clinicId: map['clinicId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int? ?? 0,
      cancelledSessions: map['cancelledSessions'] as int? ?? 0,
      noShowCount: map['noShowCount'] as int? ?? 0,
      remainingNoShows: map['remainingNoShows'] as int? ?? 2,
      status: map['status'] as String? ?? 'active',
      scheduleRule:
          ScheduleRule.fromMap(map['scheduleRule'] as Map<String, dynamic>),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'patientId': patientId,
        'therapistId': therapistId,
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'cancelledSessions': cancelledSessions,
        'noShowCount': noShowCount,
        'remainingNoShows': remainingNoShows,
        'status': status,
        'scheduleRule': scheduleRule.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
}
```

### 5.5 `SessionModel`

```dart
// lib/models/session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String clinicId;
  final String planId;
  final String patientId;
  final String therapistId;
  final int sessionNo;
  final String date; // YYYY-MM-DD
  final String slotId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rescheduledFrom;
  final DateTime? cancelledAt;
  final String? cancelReason;

  const SessionModel({
    required this.id,
    required this.clinicId,
    required this.planId,
    required this.patientId,
    required this.therapistId,
    required this.sessionNo,
    required this.date,
    required this.slotId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rescheduledFrom,
    this.cancelledAt,
    this.cancelReason,
  });

  factory SessionModel.fromMap(String id, Map<String, dynamic> map) {
    return SessionModel(
      id: id,
      clinicId: map['clinicId'] as String,
      planId: map['planId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      sessionNo: map['sessionNo'] as int,
      date: map['date'] as String,
      slotId: map['slotId'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      rescheduledFrom: map['rescheduledFrom'] as String?,
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelReason: map['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'planId': planId,
        'patientId': patientId,
        'therapistId': therapistId,
        'sessionNo': sessionNo,
        'date': date,
        'slotId': slotId,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (rescheduledFrom != null) 'rescheduledFrom': rescheduledFrom,
        if (cancelledAt != null)
          'cancelledAt': Timestamp.fromDate(cancelledAt!),
        if (cancelReason != null) 'cancelReason': cancelReason,
      };

  /// Helper: is this session today or in the future?
  /// Compares date-only (YYYY-MM-DD) since we don't have slot start time here.
  bool get isFuture {
    final sessionDate = DateTime.parse(date);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    return !sessionDate.isBefore(todayDateOnly);
  }

  /// Can be rescheduled/cancelled (future + active status).
  /// Note: sessions on TODAY are included — admin must use judgment
  /// on whether the slot time has passed.
  bool get isModifiable =>
      isFuture && (status == 'scheduled' || status == 'rescheduled');
}
```

### 5.6 `RenewalHoldModel`

```dart
// lib/models/renewal_hold_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RenewalHoldModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String therapistId;
  final String planId;
  final String slotId;
  final List<String> days;
  final DateTime createdAt;
  final String expiryDate; // YYYY-MM-DD
  final String status;

  const RenewalHoldModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.therapistId,
    required this.planId,
    required this.slotId,
    required this.days,
    required this.createdAt,
    required this.expiryDate,
    required this.status,
  });

  factory RenewalHoldModel.fromMap(String id, Map<String, dynamic> map) {
    return RenewalHoldModel(
      id: id,
      clinicId: map['clinicId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      planId: map['planId'] as String,
      slotId: map['slotId'] as String,
      days: List<String>.from(map['days'] as List),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] as String,
      status: map['status'] as String,
    );
  }

  bool get isExpired =>
      DateTime.parse(expiryDate).isBefore(DateTime.now());
}
```

### 5.7 Updated `UserModel` (add `fcmToken`)

Add to existing `UserModel`:

```dart
// Add field:
final String? fcmToken;

// Add to constructor:
this.fcmToken,

// Add to fromMap:
fcmToken: map['fcmToken'] as String?,

// Add to toMap:
if (fcmToken != null) 'fcmToken': fcmToken,
```

---

## 6. Cloud Functions — Full Implementation

### 6.1 Project Structure

```
functions/
  src/
    index.ts                  # Entry point — exports all functions
    scheduling/
      scheduleGenerator.ts    # Generate candidate dates from rules
      availabilityService.ts  # Check therapist availability
      sessionService.ts       # Create/update session records
      rescheduleService.ts    # Handle rescheduling
      cancellationService.ts  # Handle cancellations + extendPlan
      renewalService.ts       # Handle renewal hold lifecycle
    notifications/
      notificationService.ts  # FCM push notifications
    utils/
      dateUtils.ts            # Date helper functions
      validators.ts           # Input validation
    types/
      index.ts                # TypeScript interfaces
  package.json
  tsconfig.json
```

### 6.2 TypeScript Types

```typescript
// functions/src/types/index.ts

export interface ScheduleRule {
  frequency: 'once' | 'twice' | 'thrice' | 'daily';
  days: string[];      // ['mon', 'wed', 'fri']
  day1: string;        // '2026-06-01'
  slotId: string;      // 'slot_03'
}

export interface CreatePlanRequest {
  clinicId: string;
  patientId: string;
  therapistId: string;
  totalSessions: number;
  remainingNoShows: number;
  scheduleRule: ScheduleRule;
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
  cancelReason?: string;
}
```

### 6.3 Date Utilities

```typescript
// functions/src/utils/dateUtils.ts

const DAY_MAP: Record<string, number> = {
  mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6, sun: 0,
};

/**
 * Generate candidate dates from a schedule rule.
 * Starts from day1, picks dates matching the specified days,
 * until we have `count` dates.
 */
export function generateCandidateDates(
  day1: string,
  days: string[],
  count: number,
): string[] {
  const results: string[] = [];
  const targetDays = new Set(days.map((d) => DAY_MAP[d]));
  const current = new Date(day1 + "T00:00:00Z");

  // Safety: max 365 days lookahead
  const maxIterations = 365;
  let iterations = 0;

  while (results.length < count && iterations < maxIterations) {
    if (targetDays.has(current.getUTCDay())) {
      results.push(current.toISOString().split("T")[0]);
    }
    current.setUTCDate(current.getUTCDate() + 1);
    iterations++;
  }

  return results;
}

/**
 * Get day abbreviation from a date string.
 */
export function getDayAbbr(dateStr: string): string {
  const dayNum = new Date(dateStr + "T00:00:00Z").getUTCDay();
  const reverse: Record<number, string> = {
    0: "sun", 1: "mon", 2: "tue", 3: "wed",
    4: "thu", 5: "fri", 6: "sat",
  };
  return reverse[dayNum];
}
```

### 6.4 Availability Service

```typescript
// functions/src/scheduling/availabilityService.ts

import * as admin from "firebase-admin";
import { getDayAbbr } from "../utils/dateUtils";

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
 * 4. No active renewal hold blocks that slot (unless it belongs to the same patient)
 */
export async function checkAvailability(
  clinicId: string,
  therapistId: string,
  date: string,
  slotId: string,
  options: CheckOptions = {},
): Promise<AvailabilityResult> {
  // 1. Check therapist weekly schedule (use cached if provided)
  let weeklySchedule = options.cachedSchedule;

  if (!weeklySchedule) {
    const availDoc = await db
      .collection("therapistAvailability")
      .doc(therapistId)
      .get();

    if (!availDoc.exists) {
      return { available: false, reason: "Therapist availability not configured" };
    }
    weeklySchedule = availDoc.data()?.weeklySchedule ?? {};
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
    return { available: false, reason: "Slot already booked" };
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
      return { available: true };
    }
    const holdDays: string[] = hold.days ?? [];
    if (holdDays.includes(dayAbbr)) {
      const expiry = hold.expiryDate;
      if (date <= expiry) {
        return { available: false, reason: "Slot reserved by renewal hold" };
      }
    }
  }

  return { available: true };
}

/**
 * Pre-fetch therapist availability docs in a single batch.
 */
export async function prefetchAvailability(
  therapistIds: string[],
): Promise<Map<string, Record<string, string[]>>> {
  const refs = therapistIds.map((id) =>
    db.collection("therapistAvailability").doc(id),
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
  forPatientId?: string,
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
  //    to avoid per-date queries inside the loop.
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
  const holdsByTherapist = new Map<string, { days: string[]; expiryDate: string; patientId: string }>();
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
```

### 6.5 Session Service

```typescript
// functions/src/scheduling/sessionService.ts

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
  startingSessionNo: number = 1,
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
  extra: Record<string, any> = {},
): Promise<void> {
  await db.collection("sessions").doc(sessionId).update({
    status,
    updatedAt: admin.firestore.Timestamp.now(),
    ...extra,
  });
}
```

### 6.6 Cancellation Service + `extendPlan()`

```typescript
// functions/src/scheduling/cancellationService.ts

import * as admin from "firebase-admin";
import { generateCandidateDates } from "../utils/dateUtils";
import { checkAvailability } from "./availabilityService";
import { createSessions, updateSessionStatus } from "./sessionService";

const db = admin.firestore();

/**
 * Cancel a single session and extend the plan by 1.
 */
export async function cancelSession(
  sessionId: string,
  reason: string,
  clinicId: string,
): Promise<{ newSessionId: string }> {
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
    cancelReason: reason,
  });

  // Update plan counters
  const planRef = db.collection("treatmentPlans").doc(session.planId);
  await planRef.update({
    cancelledSessions: admin.firestore.FieldValue.increment(1),
  });

  // Extend plan by 1 session
  const newSessionIds = await extendPlan(session.planId, 1);

  return { newSessionId: newSessionIds[0] };
}

/**
 * Cancel a range of sessions and extend plan accordingly.
 * Uses getAll() for a single round-trip validation, then atomic batch cancel.
 */
export async function cancelRange(
  planId: string,
  sessionIds: string[],
  reason: string,
  clinicId: string,
): Promise<{ newSessionIds: string[] }> {
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
      throw new Error(`Session ${doc.id} does not belong to plan ${planId}`);
    }
    if (data.date <= today) {
      throw new Error(`Session ${doc.id} is in the past and cannot be cancelled`);
    }
    if (!["scheduled", "rescheduled"].includes(data.status)) {
      throw new Error(`Session ${doc.id} is not in a cancellable state`);
    }
  }

  // Batch cancel (atomic)
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  for (const doc of docs) {
    batch.update(doc.ref, {
      status: "cancelled",
      cancelledAt: now,
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
  return { newSessionIds };
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
  count: number,
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
    const lastDate = new Date(lastDateSnap.docs[0].data().date + "T00:00:00Z");
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
  // Start with count*4, expand if needed (up to 365 days lookahead)
  let availableDates: string[] = [];
  let multiplier = 4;
  const MAX_MULTIPLIER = 20;

  while (availableDates.length < count && multiplier <= MAX_MULTIPLIER) {
    const candidates = generateCandidateDates(
      startAfter,
      plan.scheduleRule.days,
      count * multiplier,
    );

    availableDates = [];
    for (const date of candidates) {
      if (availableDates.length >= count) break;
      const result = await checkAvailability(
        plan.clinicId,
        plan.therapistId,
        date,
        plan.scheduleRule.slotId,
        { cachedSchedule, forPatientId: plan.patientId },
      );
      if (result.available) {
        availableDates.push(date);
      }
    }
    multiplier += 4;
  }

  if (availableDates.length < count) {
    throw new Error(
      `Could only find ${availableDates.length} available slots out of ${count} needed. ` +
      `Therapist schedule may be full for the next 365 days.`,
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
    nextSessionNo,
  );

  // Update plan total
  await db.collection("treatmentPlans").doc(planId).update({
    totalSessions: admin.firestore.FieldValue.increment(count),
  });

  return sessionIds;
}
```

### 6.7 Reschedule Service

```typescript
// functions/src/scheduling/rescheduleService.ts

import * as admin from "firebase-admin";
import { generateCandidateDates } from "../utils/dateUtils";
import { checkAvailability } from "./availabilityService";
import { createSessions, updateSessionStatus } from "./sessionService";

const db = admin.firestore();

/**
 * Reschedule a single future session to a new date/slot.
 */
export async function rescheduleSession(
  sessionId: string,
  newDate: string,
  newSlotId: string,
  clinicId: string,
): Promise<{ newSessionId: string }> {
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
    { forPatientId: session.patientId },
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

  return { newSessionId: newRef.id };
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
  clinicId: string,
): Promise<{ newSessionIds: string[] }> {
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

  // Cancel all future sessions (mark as rescheduled)
  const batch = db.batch();
  const now = admin.firestore.Timestamp.now();
  for (const doc of futureSessionsSnap.docs) {
    batch.update(doc.ref, { status: "rescheduled", updatedAt: now });
  }
  await batch.commit();

  // Count how many new sessions to generate
  const countToRegenerate = futureSessionsSnap.size;

  // Find the highest sessionNo across ALL sessions in the plan
  // (avoids collisions with old rescheduled sessions)
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
    countToRegenerate * 4, // generate extra for availability filtering
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
      clinicId, plan.therapistId, date, newSlotId,
      { cachedSchedule, forPatientId: plan.patientId },
    );
    if (result.available) availableDates.push(date);
  }

  if (availableDates.length < countToRegenerate) {
    throw new Error(
      `Only ${availableDates.length} slots available, need ${countToRegenerate}`,
    );
  }

  // Create new sessions
  const newSessionIds = await createSessions(
    planId, clinicId, plan.patientId, plan.therapistId,
    newSlotId, availableDates, startNo,
  );

  // Update schedule rule on plan
  await db.collection("treatmentPlans").doc(planId).update({
    "scheduleRule.days": newDays,
    "scheduleRule.day1": newDay1,
    "scheduleRule.slotId": newSlotId,
  });

  return { newSessionIds };
}
```

### 6.8 Renewal Service

```typescript
// functions/src/scheduling/renewalService.ts

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
 * Use a renewal hold: mark as used and create new plan with same slots.
 */
export async function useRenewalHold(
  holdId: string,
  totalSessions: number,
): Promise<{ newPlanId: string }> {
  const holdDoc = await db.collection("renewalHolds").doc(holdId).get();
  if (!holdDoc.exists) throw new Error("Hold not found");
  const hold = holdDoc.data()!;

  if (hold.status !== "active") {
    throw new Error("Hold is no longer active");
  }
  if (hold.expiryDate < new Date().toISOString().split("T")[0]) {
    throw new Error("Hold has expired");
  }

  // Mark hold as used
  await holdDoc.ref.update({ status: "used" });

  // Create new plan (the createPlan function will handle session generation)
  return { newPlanId: "created_via_createPlan" };
  // In practice, call the createPlan Cloud Function with the hold's slot/days
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
      batch.update(doc.ref, { status: "expired" });
    }
    await batch.commit();
  }

  return expired.size;
}
```

### 6.9 Cloud Functions Entry Point

```typescript
// functions/src/index.ts

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { generateCandidateDates } from "./utils/dateUtils";
import { findAvailableTherapists, checkAvailability } from "./scheduling/availabilityService";
import { createSessions } from "./scheduling/sessionService";
import { cancelSession, cancelRange, extendPlan } from "./scheduling/cancellationService";
import { rescheduleSession, fullReschedule } from "./scheduling/rescheduleService";
import { createRenewalHold, expireOldHolds } from "./scheduling/renewalService";
import { sendSessionNotification } from "./notifications/notificationService";

admin.initializeApp();

const db = admin.firestore();

// ─── AUTH + AUTHORIZATION HELPER ────────────────────────────────────────────

/**
 * Validates the caller is authenticated and has the required role for the clinic.
 * Throws HttpsError if unauthorized.
 */
async function authorizeRequest(
  auth: { uid: string } | undefined,
  clinicId: string,
  requiredRole: "admin" | "therapist" | "any" = "admin",
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
    throw new HttpsError("permission-denied", "Not authorized for this clinic");
  }
  if (requiredRole !== "any" && callerData.role !== requiredRole) {
    throw new HttpsError("permission-denied", `Requires ${requiredRole} role`);
  }
  return auth.uid;
}

// ─── CREATE TREATMENT PLAN ──────────────────────────────────────────────────

export const createPlan = onCall(async (request) => {
  const data = request.data;
  const { clinicId, patientId, therapistId, totalSessions,
          remainingNoShows, scheduleRule, idempotencyKey } = data;

  // Authorize: must be admin for this clinic
  const uid = await authorizeRequest(request.auth, clinicId, "admin");

  // Validate inputs
  if (!clinicId || !patientId || !therapistId || !totalSessions || !scheduleRule) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }
  if (!scheduleRule.day1 || !scheduleRule.days?.length || !scheduleRule.slotId) {
    throw new HttpsError("invalid-argument", "Incomplete schedule rule");
  }

  // Idempotency check: prevent duplicate plans from retried requests
  if (idempotencyKey) {
    const existing = await db
      .collection("treatmentPlans")
      .where("idempotencyKey", "==", idempotencyKey)
      .limit(1)
      .get();
    if (!existing.empty) {
      const existingPlan = existing.docs[0];
      return { planId: existingPlan.id, duplicate: true };
    }
  }

  // Generate candidate dates
  const candidateDates = generateCandidateDates(
    scheduleRule.day1, scheduleRule.days, totalSessions,
  );

  if (candidateDates.length < totalSessions) {
    throw new HttpsError(
      "failed-precondition",
      `Could only generate ${candidateDates.length} dates within 365-day window`,
    );
  }

  // Pre-fetch therapist availability for performance
  const availDoc = await db
    .collection("therapistAvailability")
    .doc(therapistId)
    .get();
  if (!availDoc.exists) {
    throw new HttpsError("failed-precondition", "Therapist availability not configured");
  }
  const cachedSchedule = availDoc.data()?.weeklySchedule ?? {};

  // Verify therapist availability for all dates
  for (const date of candidateDates) {
    const result = await checkAvailability(
      clinicId, therapistId, date, scheduleRule.slotId,
      { cachedSchedule, forPatientId: patientId },
    );
    if (!result.available) {
      throw new HttpsError(
        "failed-precondition",
        `Therapist unavailable on ${date}: ${result.reason}`,
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
    ...(idempotencyKey && { idempotencyKey }),
  });

  // Create all session documents
  const sessionIds = await createSessions(
    planRef.id, clinicId, patientId, therapistId,
    scheduleRule.slotId, candidateDates,
  );

  // Send notification to patient about scheduled sessions
  await sendSessionNotification(
    sessionIds[0], patientId, "scheduled",
    candidateDates[0], scheduleRule.slotId,
  );

  return { planId: planRef.id, sessionIds, dates: candidateDates };
});

// ─── GET AVAILABLE THERAPISTS ───────────────────────────────────────────────

export const getAvailableTherapists = onCall(async (request) => {
  const { clinicId, scheduleRule, totalSessions } = request.data;

  // Authorize: any role in this clinic can query availability
  await authorizeRequest(request.auth, clinicId, "any");

  if (!scheduleRule?.day1 || !scheduleRule?.days?.length || !scheduleRule?.slotId) {
    throw new HttpsError("invalid-argument", "Incomplete schedule rule");
  }

  const candidateDates = generateCandidateDates(
    scheduleRule.day1, scheduleRule.days, totalSessions,
  );

  const therapistIds = await findAvailableTherapists(
    clinicId, candidateDates, scheduleRule.slotId, request.data.patientId,
  );

  // Batch-fetch therapist details
  const therapists = [];
  if (therapistIds.length > 0) {
    const refs = therapistIds.map((id) => db.collection("users").doc(id));
    const docs = await db.getAll(...refs);
    for (const doc of docs) {
      if (doc.exists) {
        const data = doc.data()!;
        therapists.push({
          id: doc.id,
          firstName: data.firstName,
          lastName: data.lastName,
        });
      }
    }
  }

  return { therapists, candidateDates };
});

// ─── RESCHEDULE SINGLE SESSION ──────────────────────────────────────────────

export const rescheduleSessionFn = onCall(async (request) => {
  const { sessionId, newDate, newSlotId, clinicId } = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  const result = await rescheduleSession(sessionId, newDate, newSlotId, clinicId);

  // Notify patient
  const sessionDoc = await db.collection("sessions").doc(result.newSessionId).get();
  if (sessionDoc.exists) {
    const s = sessionDoc.data()!;
    await sendSessionNotification(result.newSessionId, s.patientId, "rescheduled", newDate, newSlotId);
  }

  return result;
});

// ─── FULL RESCHEDULE ────────────────────────────────────────────────────────

export const fullRescheduleFn = onCall(async (request) => {
  const { planId, newDay1, newDays, newSlotId, clinicId } = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  return fullReschedule(planId, newDay1, newDays, newSlotId, clinicId);
});

// ─── CANCEL SINGLE SESSION ─────────────────────────────────────────────────

export const cancelSessionFn = onCall(async (request) => {
  const { sessionId, reason, clinicId } = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  const result = await cancelSession(sessionId, reason, clinicId);

  // Notify patient
  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (sessionDoc.exists) {
    const s = sessionDoc.data()!;
    await sendSessionNotification(sessionId, s.patientId, "cancelled", s.date, s.slotId);
  }

  return result;
});

// ─── CANCEL RANGE ───────────────────────────────────────────────────────────

export const cancelRangeFn = onCall(async (request) => {
  const { planId, sessionIds, reason, clinicId } = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");
  return cancelRange(planId, sessionIds, reason, clinicId);
});

// ─── MARK SESSION COMPLETED / NO-SHOW ──────────────────────────────────────

export const markSession = onCall(async (request) => {
  const { sessionId, status, clinicId } = request.data;
  await authorizeRequest(request.auth, clinicId, "admin");

  if (!["completed", "no_show"].includes(status)) {
    throw new HttpsError("invalid-argument", "Status must be completed or no_show");
  }

  const sessionDoc = await db.collection("sessions").doc(sessionId).get();
  if (!sessionDoc.exists) throw new HttpsError("not-found", "Session not found");

  const session = sessionDoc.data()!;

  // Use a TRANSACTION to atomically update session + plan counters + check completion
  await db.runTransaction(async (tx) => {
    const planRef = db.collection("treatmentPlans").doc(session.planId);
    const planSnap = await tx.get(planRef);
    if (!planSnap.exists) throw new HttpsError("not-found", "Plan not found");
    const plan = planSnap.data()!;

    // Update session status
    tx.update(db.collection("sessions").doc(sessionId), {
      status,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    if (status === "completed") {
      const newCompleted = (plan.completedSessions ?? 0) + 1;
      const totalDone = newCompleted + (plan.cancelledSessions ?? 0) + (plan.noShowCount ?? 0);

      const planUpdate: Record<string, any> = {
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
    const planDoc = await db.collection("treatmentPlans").doc(session.planId).get();
    if (planDoc.data()?.status === "completed") {
      await createRenewalHold(session.planId);
    }
  } else if (status === "no_show") {
    // Extend plan by 1 to replace the no-show
    await extendPlan(session.planId, 1);
  }

  // Notify patient
  await sendSessionNotification(sessionId, session.patientId, status, session.date, session.slotId);

  return { success: true };
});

// ─── EXPIRE RENEWAL HOLDS (scheduled daily) ────────────────────────────────

export const expireRenewalHolds = onSchedule("every day 02:00", async () => {
  const count = await expireOldHolds();
  console.log(`Expired ${count} renewal holds`);
});
```

> **Note:** Notifications are now sent directly from the Cloud Function that
> performs the action, rather than via a Firestore trigger. This is more efficient
> (fewer cold starts, no extra reads) and gives precise control over when
> notifications fire (e.g., batch creation sends one summary, not 12 individual
> notifications).

---

## 7. Flutter Services (Client-side)

### 7.1 Scheduling Service (calls Cloud Functions)

```dart
// lib/services/scheduling_service.dart

import 'package:cloud_functions/cloud_functions.dart';

class SchedulingService {
  static final SchedulingService _instance = SchedulingService._internal();
  factory SchedulingService() => _instance;
  SchedulingService._internal();

  final _functions = FirebaseFunctions.instance;

  /// Create a new treatment plan + sessions.
  /// [idempotencyKey] prevents duplicate plans on retry (e.g. UUID from client).
  Future<Map<String, dynamic>> createPlan({
    required String clinicId,
    required String patientId,
    required String therapistId,
    required int totalSessions,
    required int remainingNoShows,
    required Map<String, dynamic> scheduleRule,
    String? idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('createPlan').call({
      'clinicId': clinicId,
      'patientId': patientId,
      'therapistId': therapistId,
      'totalSessions': totalSessions,
      'remainingNoShows': remainingNoShows,
      'scheduleRule': scheduleRule,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Get therapists available for a given schedule.
  Future<Map<String, dynamic>> getAvailableTherapists({
    required String clinicId,
    required Map<String, dynamic> scheduleRule,
    required int totalSessions,
  }) async {
    final result =
        await _functions.httpsCallable('getAvailableTherapists').call({
      'clinicId': clinicId,
      'scheduleRule': scheduleRule,
      'totalSessions': totalSessions,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Reschedule a single session.
  Future<Map<String, dynamic>> rescheduleSession({
    required String sessionId,
    required String newDate,
    required String newSlotId,
    required String clinicId,
  }) async {
    final result =
        await _functions.httpsCallable('rescheduleSessionFn').call({
      'sessionId': sessionId,
      'newDate': newDate,
      'newSlotId': newSlotId,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Full reschedule of a plan.
  Future<Map<String, dynamic>> fullReschedule({
    required String planId,
    required String newDay1,
    required List<String> newDays,
    required String newSlotId,
    required String clinicId,
  }) async {
    final result =
        await _functions.httpsCallable('fullRescheduleFn').call({
      'planId': planId,
      'newDay1': newDay1,
      'newDays': newDays,
      'newSlotId': newSlotId,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Cancel a single session.
  Future<Map<String, dynamic>> cancelSession({
    required String sessionId,
    required String reason,
    required String clinicId,
  }) async {
    final result =
        await _functions.httpsCallable('cancelSessionFn').call({
      'sessionId': sessionId,
      'reason': reason,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Cancel multiple sessions.
  Future<Map<String, dynamic>> cancelRange({
    required String planId,
    required List<String> sessionIds,
    required String reason,
    required String clinicId,
  }) async {
    final result =
        await _functions.httpsCallable('cancelRangeFn').call({
      'planId': planId,
      'sessionIds': sessionIds,
      'reason': reason,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Mark session as completed or no_show.
  Future<void> markSession({
    required String sessionId,
    required String status,
    required String clinicId,
  }) async {
    await _functions.httpsCallable('markSession').call({
      'sessionId': sessionId,
      'status': status,
      'clinicId': clinicId,
    });
  }
}
```

### 7.2 Session Query Service (direct Firestore reads)

```dart
// lib/services/session_query_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';
import '../models/treatment_plan_model.dart';

class SessionQueryService {
  static final SessionQueryService _instance = SessionQueryService._internal();
  factory SessionQueryService() => _instance;
  SessionQueryService._internal();

  final _db = FirebaseFirestore.instance;

  /// Stream sessions for a patient in a clinic.
  Stream<List<SessionModel>> patientSessions(String clinicId, String patientId) {
    return _db
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream sessions for a therapist on a specific date.
  Stream<List<SessionModel>> therapistDaySessions(
    String clinicId,
    String therapistId,
    String date,
  ) {
    return _db
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('therapistId', isEqualTo: therapistId)
        .where('date', isEqualTo: date)
        .where('status', whereIn: ['scheduled', 'rescheduled'])
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream all sessions for a plan.
  Stream<List<SessionModel>> planSessions(String planId) {
    return _db
        .collection('sessions')
        .where('planId', isEqualTo: planId)
        .orderBy('sessionNo')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream active treatment plans for a patient.
  Stream<List<TreatmentPlanModel>> patientPlans(
    String clinicId,
    String patientId,
  ) {
    return _db
        .collection('treatmentPlans')
        .where('clinicId', isEqualTo: clinicId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TreatmentPlanModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Get all slots (global, rarely changes).
  Future<List<Map<String, dynamic>>> getAllSlots() async {
    final snap = await _db.collection('slots').get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }
}
```

---

## 8. Flutter State Management

### 8.1 Riverpod Providers

```dart
// lib/providers/scheduling_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/scheduling_service.dart';
import '../services/session_query_service.dart';

// ── Service singletons ──────────────────────────────────────────────────────

final schedulingServiceProvider = Provider((_) => SchedulingService());
final sessionQueryServiceProvider = Provider((_) => SessionQueryService());

// ── Selected state for plan creation form ────────────────────────────────────

final selectedPatientProvider = StateProvider<String?>((_) => null);
final selectedFrequencyProvider = StateProvider<String>((_) => 'thrice');
final selectedDaysProvider = StateProvider<List<String>>((_) => []);
final selectedDay1Provider = StateProvider<String?>((_) => null);
final selectedSlotProvider = StateProvider<String?>((_) => null);
final totalSessionsProvider = StateProvider<int>((_) => 12);

// ── Available therapists (async, depends on selections above) ────────────────

final availableTherapistsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final clinicId = 'clinic_001'; // TODO: from logged-in user's clinicId
  final day1 = ref.watch(selectedDay1Provider);
  final days = ref.watch(selectedDaysProvider);
  final slot = ref.watch(selectedSlotProvider);
  final total = ref.watch(totalSessionsProvider);

  if (day1 == null || days.isEmpty || slot == null) return [];

  final service = ref.read(schedulingServiceProvider);
  final result = await service.getAvailableTherapists(
    clinicId: clinicId,
    scheduleRule: {
      'frequency': ref.read(selectedFrequencyProvider),
      'days': days,
      'day1': day1,
      'slotId': slot,
    },
    totalSessions: total,
  );

  return List<Map<String, dynamic>>.from(result['therapists'] ?? []);
});

// ── Plan creation loading state ──────────────────────────────────────────────

final createPlanLoadingProvider = StateProvider<bool>((_) => false);
```

---

## 9. Flutter Screens & UI

### 9.1 Screen Map (role-based)

```
Role: admin
├── AdminHomeScreen (dashboard)
│   ├── Create Treatment Plan button
│   ├── View all patients list
│   └── Today's sessions summary
├── CreatePlanScreen (multi-step form)
│   ├── Step 1: Select patient
│   ├── Step 2: Configure schedule (frequency, days, slot, day1, count)
│   ├── Step 3: Select therapist (from available list)
│   └── Step 4: Confirm & create
├── PlanDetailScreen
│   ├── Session list with statuses
│   ├── Mark completed / no-show buttons
│   ├── Reschedule button (per session)
│   └── Cancel button (per session or range)
└── TherapistCalendarScreen
    └── View therapist schedules by date

Role: therapist
├── TherapistHomeScreen
│   ├── Today's sessions
│   └── Upcoming sessions
└── SessionDetailScreen
    └── View session details (read-only)

Role: patient
├── PatientHomeScreen (existing HomeScreen, enhanced)
│   ├── Next appointment card
│   ├── Treatment plan summary
│   └── Upcoming sessions list
└── SessionHistoryScreen
    └── Past sessions with statuses
```

### 9.2 Navigation — Role-based routing

```dart
// In AuthWrapper or MainAppFlow, route by role:

// lib/screens/flows/main_app_flow.dart (updated)

import '../models/user_model.dart';

class MainAppFlow extends StatelessWidget {
  final UserModel user;
  const MainAppFlow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) {
          switch (user.role) {
            case 'admin':
              return AdminHomeScreen(user: user);
            case 'therapist':
              return TherapistHomeScreen(user: user);
            case 'patient':
            default:
              return HomeScreen(user: user);
          }
        },
      ),
    );
  }
}
```

### 9.3 Create Plan Screen (conceptual)

```dart
// lib/screens/admin/create_plan_screen.dart

// This screen uses Riverpod ConsumerWidget for reactive state.
// Multi-step form:
//
// Step 1 — Select patient:
//   - Search patients in clinic via Firestore query
//   - Set selectedPatientProvider
//
// Step 2 — Configure schedule:
//   - DropdownButtonFormField for frequency (once/twice/thrice/daily)
//   - Multi-select chips for days (mon-sun)
//   - Date picker for day1 (first session date)
//   - Dropdown for slot (from slots collection)
//   - Number field for total sessions
//
// Step 3 — Select therapist:
//   - Watches availableTherapistsProvider (auto-fetches when step 2 changes)
//   - Shows list of available therapists
//   - Admin taps to select
//
// Step 4 — Confirm:
//   - Summary of all selections
//   - "Create Plan" button calls schedulingService.createPlan()
//   - Shows success/error
```

---

## 10. Scheduling Logic — All Cases

### Case 1: Initial Scheduling

```
Admin → CreatePlanScreen
  1. Select patient
  2. Set frequency, days, day1, slot, session count
  3. App calls getAvailableTherapists Cloud Function
  4. Cloud Function generates candidate dates → checks each date for each therapist
  5. Returns list of fully-available therapists
  6. Admin selects therapist
  7. App calls createPlan Cloud Function
  8. Cloud Function:
     a. Generates candidate dates
     b. Verifies availability (double-check)
     c. Creates treatmentPlan doc
     d. Creates N session docs in batch
  9. Returns planId + session dates
```

### Case 2: Single Session Reschedule

```
Admin → PlanDetailScreen → tap session → Reschedule
  1. Show date picker + slot picker for new date/slot
  2. App calls rescheduleSessionFn
  3. Cloud Function:
     a. Validates session is future + modifiable
     b. Checks new slot availability
     c. Marks old session as "rescheduled"
     d. Creates new session doc (same sessionNo, new date/slot)
     e. Triggers notification
```

### Case 3: Full Reschedule

```
Admin → PlanDetailScreen → "Reschedule All Future"
  1. Show new schedule form (day1, days, slot)
  2. App calls fullRescheduleFn
  3. Cloud Function:
     a. Finds all future modifiable sessions
     b. Marks them as "rescheduled"
     c. Generates new dates with new rule
     d. Checks availability for each
     e. Creates new session docs
     f. Updates scheduleRule on plan
```

### Case 4: Single Cancellation

```
Admin → PlanDetailScreen → tap session → Cancel
  1. Show reason input
  2. App calls cancelSessionFn
  3. Cloud Function:
     a. Marks session "cancelled"
     b. Increments plan.cancelledSessions
     c. Calls extendPlan(planId, 1) → adds 1 new session at end
     d. Triggers notification
```

### Case 5: Range Cancellation

```
Admin → PlanDetailScreen → multi-select sessions → Cancel
  1. Show reason input
  2. App calls cancelRangeFn
  3. Cloud Function:
     a. Validates all sessions belong to plan
     b. Batch-cancels all
     c. Calls extendPlan(planId, count) → adds N new sessions
```

### Case 6: No-Show

```
Admin → PlanDetailScreen → tap session → Mark No-Show
  1. App calls markSession(sessionId, 'no_show')
  2. Cloud Function:
     a. Sets status to "no_show"
     b. Increments plan.noShowCount, decrements plan.remainingNoShows
     c. Calls extendPlan(planId, 1) → adds 1 replacement session
```

### Case 7: Plan Completion + Renewal Hold

```
When last session is marked "completed":
  1. Cloud Function checks if totalDone >= totalSessions
  2. Sets plan.status = "completed"
  3. Creates renewalHold doc (30 day expiry)
  4. Hold blocks those slots for other patients
```

### Case 8: Renewal

```
Admin → create new plan for same patient
  1. If active renewal hold exists, same slots are guaranteed available
  2. On plan creation with renewal, mark hold as "used"
```

---

## 11. Notifications

### 11.1 FCM Setup

**pubspec.yaml addition:**
```yaml
dependencies:
  firebase_messaging: ^15.2.4
```

**Token storage** — save FCM token to user doc on app startup:

```dart
// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;

  /// Request permission and save token. Call once on login.
  Future<void> initialize() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }
}
```

### 11.2 Cloud Function — Send Notifications

```typescript
// functions/src/notifications/notificationService.ts

import * as admin from "firebase-admin";

const db = admin.firestore();

export async function sendSessionNotification(
  sessionId: string,
  patientId: string,
  status: string,
  date: string,
  slotId: string,
): Promise<void> {
  // Get patient FCM token
  const userDoc = await db.collection("users").doc(patientId).get();
  if (!userDoc.exists) return;

  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  // Get slot details for display
  const slotDoc = await db.collection("slots").doc(slotId).get();
  const slotTime = slotDoc.exists
    ? `${slotDoc.data()?.start} – ${slotDoc.data()?.end}`
    : slotId;

  const messages: Record<string, { title: string; body: string }> = {
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
      body: `You were marked absent for your session on ${date}. A replacement session will be scheduled.`,
    },
  };

  const msg = messages[status];
  if (!msg) return;

  try {
    await admin.messaging().send({
      token: fcmToken,
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
  } catch (err: any) {
    // Token may be stale — remove it
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      await db.collection("users").doc(patientId).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
    }
    console.error(`FCM error for ${patientId}:`, err.message);
  }
}
```

### 11.3 Notification Events

| Event | Recipient | Message |
|-------|-----------|---------|
| Session scheduled | Patient | "Your session on {date} at {time} has been scheduled." |
| Session rescheduled | Patient | "Your session has been rescheduled to {date} at {time}." |
| Session cancelled | Patient | "Your session on {date} at {time} has been cancelled." |
| Session completed | Patient | "Your session on {date} has been marked as completed." |
| No-show | Patient | "You were marked absent. A replacement session will be scheduled." |

---

## 12. Firestore Security Rules

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: is the user authenticated?
    function isAuth() {
      return request.auth != null;
    }

    // Helper: get user's role from their profile doc
    function userRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    // Helper: get user's clinicId
    function userClinic() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.clinicId;
    }

    // Helper: is the user an admin in the same clinic as the document?
    function isClinicAdmin(clinicId) {
      return isAuth() && userRole() == 'admin' && userClinic() == clinicId;
    }

    // Users: read own profile, admin reads clinic members
    match /users/{userId} {
      allow read: if isAuth() && (
        request.auth.uid == userId ||
        userRole() == 'admin'
      );
      allow update: if isAuth() && request.auth.uid == userId;
      // Create handled by app registration flow
      allow create: if isAuth() && request.auth.uid == userId;
    }

    // Slots: read-only for all authenticated users
    match /slots/{slotId} {
      allow read: if isAuth();
      allow write: if false; // admin via console only
    }

    // Therapist availability: read by clinic members, write by admin
    match /therapistAvailability/{therapistId} {
      allow read: if isAuth() && userClinic() == resource.data.clinicId;
      allow write: if false; // manual for now
    }

    // Treatment plans: clinic-scoped read, created by Cloud Functions
    match /treatmentPlans/{planId} {
      allow read: if isAuth() && userClinic() == resource.data.clinicId;
      allow write: if false; // Cloud Functions use Admin SDK (bypasses rules)
    }

    // Sessions: clinic-scoped read, managed by Cloud Functions
    match /sessions/{sessionId} {
      allow read: if isAuth() && userClinic() == resource.data.clinicId;
      allow write: if false; // Cloud Functions use Admin SDK
    }

    // Renewal holds: clinic-scoped read, managed by Cloud Functions
    match /renewalHolds/{holdId} {
      allow read: if isAuth() && userClinic() == resource.data.clinicId;
      allow write: if false; // Cloud Functions use Admin SDK
    }
  }
}
```

**Key principle:** All writes to scheduling collections go through Cloud Functions (Admin SDK), which bypass security rules. Rules only need to protect client-side reads.

**Performance note:** The `userRole()` and `userClinic()` helpers each cost 1 Firestore read per rule evaluation. For high-traffic production:
- **Recommended:** Use Firebase Custom Claims (set via Admin SDK) to store `role` and `clinicId` on the auth token. This eliminates the extra reads:
  ```javascript
  function userRole() {
    return request.auth.token.role;
  }
  function userClinic() {
    return request.auth.token.clinicId;
  }
  ```
- Custom Claims are set when admin/therapist is created:
  ```typescript
  await admin.auth().setCustomUserClaims(uid, { role: 'admin', clinicId: 'clinic_001' });
  ```
- Patient claims are set during registration in the `register` Cloud Function.

---

## 13. Firestore Indexes

Create these composite indexes in `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clinicId", "order": "ASCENDING" },
        { "fieldPath": "therapistId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" },
        { "fieldPath": "slotId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clinicId", "order": "ASCENDING" },
        { "fieldPath": "patientId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "planId", "order": "ASCENDING" },
        { "fieldPath": "sessionNo", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "planId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "renewalHolds",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clinicId", "order": "ASCENDING" },
        { "fieldPath": "therapistId", "order": "ASCENDING" },
        { "fieldPath": "slotId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "renewalHolds",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "expiryDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "treatmentPlans",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clinicId", "order": "ASCENDING" },
        { "fieldPath": "patientId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "clinicId", "order": "ASCENDING" },
        { "fieldPath": "role", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## 14. User Roles & Access

| Action | Patient | Therapist | Admin |
|--------|---------|-----------|-------|
| View own sessions | ✅ | ✅ | ✅ |
| View all clinic sessions | ❌ | ❌ | ✅ |
| Create treatment plan | ❌ | ❌ | ✅ |
| Reschedule session | ❌ | ❌ | ✅ |
| Cancel session | ❌ | ❌ | ✅ |
| Mark completed/no-show | ❌ | ❌ | ✅ |
| View therapist calendar | ❌ | Own only | ✅ All |
| Sign out | ✅ | ✅ | ✅ |

Admin and therapist users are **created manually** in Firestore console with the appropriate `role` and `clinicId`.

---

## 15. Migration Notes

### From current codebase:

1. **Add `flutter_riverpod` and `cloud_functions` and `firebase_messaging`** to `pubspec.yaml`
2. **Wrap app in `ProviderScope`** in `main.dart`
3. **Add `fcmToken` field** to `UserModel`
4. **Create all new model files** (sections 5.1–5.6)
5. **Create `scheduling_service.dart`** and **`session_query_service.dart`**
6. **Create `notification_service.dart`**
7. **Create Riverpod providers file**
8. **Update `MainAppFlow`** to accept `UserModel` and route by role
9. **Create admin screens** (CreatePlanScreen, PlanDetailScreen, etc.)
10. **Initialize Cloud Functions** project in `functions/`
11. **Deploy Firestore rules** and **indexes**
12. **Manually seed** `slots`, `therapistAvailability`, and admin/therapist user docs

### New files to create:

```
lib/
  models/
    slot_model.dart
    therapist_availability_model.dart
    schedule_rule.dart
    treatment_plan_model.dart
    session_model.dart
    renewal_hold_model.dart
  services/
    scheduling_service.dart
    session_query_service.dart
    notification_service.dart
  providers/
    scheduling_providers.dart
  screens/
    admin/
      admin_home_screen.dart
      create_plan_screen.dart
      plan_detail_screen.dart
      therapist_calendar_screen.dart
    therapist/
      therapist_home_screen.dart
functions/
  src/
    index.ts
    types/index.ts
    utils/dateUtils.ts
    utils/validators.ts
    scheduling/
      scheduleGenerator.ts
      availabilityService.ts
      sessionService.ts
      rescheduleService.ts
      cancellationService.ts
      renewalService.ts
    notifications/
      notificationService.ts
firestore.rules
firestore.indexes.json
```

---

## 16. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Should `extendPlan` fail silently or block if no available slots are found? Currently throws. | UX: admin needs to know slots ran out |
| 2 | Should patients see cancelled session history or only active/completed? | UI filtering logic |
| 3 | Max no-show limit — what happens when `remainingNoShows` hits 0? Auto-cancel plan? | Business rule decision |
| 4 | Should therapist be notified of new sessions assigned to them? | Additional notification events |
| 5 | Future: therapist leave/holidays — will need a `therapistLeave` collection | Deferred, out of scope now |
| 6 | Future: super_admin cross-clinic access? | Deferred, out of scope now |

---

## 17. Review Fixes Applied

The following issues were identified during the logic/performance review and are now fixed in this spec:

| # | Issue | Fix Applied |
|---|-------|-------------|
| 1 | **CRITICAL:** `markSession` plan completion check was non-atomic (read-after-increment race) | Wrapped in `db.runTransaction()` — atomically reads plan, updates counters, and checks completion |
| 2 | **CRITICAL:** No role/clinic authorization in Cloud Functions — any authenticated user could call any function | Added `authorizeRequest()` helper that verifies caller's role + clinicId on every function |
| 3 | **HIGH:** `extendPlan` sessionNo calculation wrong with rescheduled sessions | Now queries ALL sessions (any status) by `sessionNo desc` to find the true max |
| 4 | **HIGH:** `cancelRange` made N sequential reads then batch-wrote without atomicity | Now uses `db.getAll(...refs)` for single round-trip + validates all before batch write |
| 5 | **HIGH:** `findAvailableTherapists` was O(T×D) sequential queries | Rewrote with bulk pre-fetching: batch availability docs, batch session queries, batch hold queries, then in-memory evaluation |
| 6 | **HIGH:** `checkAvailability` re-fetched the same therapist doc on every loop call | Added `cachedSchedule` option parameter — callers pre-fetch once and pass in |
| 7 | **MEDIUM:** Dynamic imports in `fullReschedule` added cold-start latency | Replaced with static imports at top of file |
| 8 | **MEDIUM:** Notification trigger fired per-document update causing extra reads | Removed `onDocumentUpdated` trigger; notifications sent directly from the calling function (more efficient, fewer cold starts) |
| 9 | **MEDIUM:** `extendPlan` generated only `count*2` candidates (insufficient if schedule is dense) | Added progressive expansion loop: starts at `count*4`, expands to `count*20` before failing |
| 10 | **MEDIUM:** Renewal hold blocked the same patient from rebooking their own held slot | Added `forPatientId` option — skips hold check if the patient owns the hold |
| 11 | **MEDIUM:** `fullReschedule` sessionNo could duplicate old rescheduled session numbers | Now queries max `sessionNo` across ALL statuses (not just preserved sessions) |
| 12 | **MEDIUM:** No idempotency protection on `createPlan` (retries could create duplicates) | Added optional `idempotencyKey` field — checked before creation, stored in plan doc |
| 13 | **LOW:** `SessionModel.isFuture` subtracted 1 day, making comparison semantically unclear | Rewritten to compare date-only (today's sessions are "future" i.e. still modifiable) with clear documentation |
| 14 | **LOW:** Security rules use `get()` per evaluation (costly at scale) | Added Custom Claims recommendation section with migration code |
| 15 | **LOW:** `expireOldHolds` single batch could exceed 500 limit | Added chunking loop that splits into batches of 500 |
| 16 | **LOW:** `getAvailableTherapists` fetched therapist details one-by-one | Replaced with `db.getAll(...refs)` single round-trip |

---

*End of spec. All code in this document is ready for implementation upon approval.*
