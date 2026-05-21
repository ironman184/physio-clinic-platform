# Registration — Feature Spec

## Overview

After a new user verifies their phone number via OTP, they are routed to the **RegisterScreen** to complete their profile. The profile is persisted to **Cloud Firestore** under `users/{uid}`. Role is hardcoded to `"patient"` for now.

---

## Entry Points

| Source | Condition | Navigation |
|--------|-----------|------------|
| `OtpVerificationScreen` | OTP valid + no Firestore profile | `pushAndRemoveUntil → RegisterScreen` |
| `AuthWrapper` (cold start) | Firebase user exists + no Firestore profile | Renders `RegisterScreen` directly |

---

## Form Fields

| # | Field | Widget | Required | Validation |
|---|-------|--------|----------|------------|
| 1 | First Name | `TextFormField` | Yes | Non-empty, min 2 chars |
| 2 | Last Name | `TextFormField` | Yes | Non-empty, min 2 chars |
| 3 | Email | `TextFormField` | No | Regex: `^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$` |
| 4 | Gender | `DropdownButtonFormField` | Yes | Must select one of: Male, Female, Other |
| 5 | Date of Birth | `showDatePicker` (tap-to-open) | Yes | Must be selected; range: 1920 – today |
| 6 | Clinic | `DropdownButtonFormField` | No | Optional; select from demo list |

---

## Demo Clinics (Hardcoded)

| Display Name | Clinic ID |
|-------------|-----------|
| PhysioCare Downtown | `clinic_001` |
| HealWell Physiotherapy | `clinic_002` |
| MoveRight Rehab Center | `clinic_003` |

Defined as `kDemoClinics` constant map in `register_screen.dart`.

---

## Firestore Document Structure

**Collection:** `users`  
**Document ID:** Firebase Auth UID

| Key | Source | Type |
|-----|--------|------|
| `clinicId` | Selected clinic → `kDemoClinics[name]` (or `""` if none) | `String` |
| `phoneNumber` | `FirebaseAuth.instance.currentUser.phoneNumber` | `String` |
| `firstName` | Form input | `String` |
| `lastName` | Form input | `String` |
| `email` | Form input (omitted from doc if empty) | `String?` |
| `gender` | Form dropdown, stored lowercase (`"male"`, `"female"`, `"other"`) | `String` |
| `dob` | Date picker | `Timestamp` |
| `role` | Hardcoded `"patient"` | `String` |
| `createdAt` | `DateTime.now()` at registration time | `Timestamp` |

---

## Registration Flow

```
RegisterScreen
    │
    │  User fills form, taps "Complete Registration"
    │
    ├── Form validation fails
    │     └── Show inline errors (TextFormField validators)
    │
    ├── Gender not selected
    │     └── SnackBar: "Please select your gender."
    │
    ├── DOB not selected
    │     └── SnackBar: "Please select your date of birth."
    │
    └── All valid
          │
          ▼
    AuthProvider.register(
      firstName, lastName, email, gender, dob, clinicId
    )
          │
          ├── No Firebase user → error: "Session expired"
          │
          ├── Firestore write fails → error: "Registration failed"
          │
          └── Success
                ├── _currentUser = UserModel(...)
                ├── status = authenticated
                └── Navigator.pushAndRemoveUntil → HomeScreen
```

---

## AuthProvider.register()

```dart
Future<void> register({
  required String firstName,
  required String lastName,
  required String? email,
  required String gender,
  required DateTime dob,
  required String clinicId,
}) async {
  // 1. Check Firebase user exists
  // 2. Set status = loading
  // 3. Build UserModel
  // 4. Write to Firestore via UserService.createUser()
  // 5. Set _currentUser, status = authenticated
}
```

---

## UI Details

- `automaticallyImplyLeading: false` — no back button (user must complete registration)
- `SingleChildScrollView` wraps form for smaller screens
- All inputs use consistent `OutlineInputBorder` with `borderRadius: 14`
- Loading state disables the submit button and shows a `CircularProgressIndicator`
- DOB field uses `GestureDetector` + `AbsorbPointer` to open date picker on tap
- Date displayed as `dd MMM yyyy` format via `intl` package

---

## Error Handling

| Scenario | Display |
|----------|---------|
| Form validation fails | Inline error text below field |
| Gender/DOB not selected | SnackBar with error message |
| Firebase user is null | SnackBar: "Session expired. Please login again." |
| Firestore write fails | SnackBar: "Registration failed. Please try again." |

After showing any provider error, `provider.clearError()` is called.
