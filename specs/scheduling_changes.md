# Scheduling System – All Changes

## New Files Created

### Models (Dart)
- `lib/models/slot_model.dart`
- `lib/models/therapist_availability_model.dart`
- `lib/models/schedule_rule.dart`
- `lib/models/treatment_plan_model.dart`
- `lib/models/session_model.dart`
- `lib/models/renewal_hold_model.dart`

### Services (Dart)
- `lib/services/scheduling_service.dart`
- `lib/services/session_query_service.dart`
- `lib/services/notification_service.dart`

### Providers (Dart)
- `lib/providers/scheduling_providers.dart`

### Screens (Dart)
- `lib/screens/admin/admin_home_screen.dart`
- `lib/screens/admin/create_plan_screen.dart`
- `lib/screens/admin/plan_detail_screen.dart`
- `lib/screens/admin/therapist_calendar_screen.dart`
- `lib/screens/therapist/therapist_home_screen.dart`
- `lib/screens/patient/patient_home_screen.dart`

### Cloud Functions (TypeScript)
- `functions/src/index.ts`
- `functions/src/scheduling/availabilityService.ts`
- `functions/src/scheduling/sessionService.ts`
- `functions/src/scheduling/cancellationService.ts`
- `functions/src/scheduling/rescheduleService.ts`
- `functions/src/scheduling/renewalService.ts`
- `functions/src/notifications/notificationService.ts`

### Firebase Config
- `firestore.rules`
- `firestore.indexes.json`

## Files Changed

- `pubspec.yaml` — Added cloud_functions, firebase_messaging, flutter_riverpod, uuid
- `lib/main.dart` — Wrapped in ProviderScope, Riverpod hide import
- `lib/models/user_model.dart` — Added `fcmTokens` field
- `lib/screens/flows/main_app_flow.dart` — Routes admin/therapist/patient to role-specific screens
- `functions/package.json` — Added firebase-admin, firebase-functions deps
