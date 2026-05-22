# Bug Fixes — Code Review (May 22, 2026)

---

## Bug 1 — `FutureBuilder` future recreated on every rebuild

**File:** `lib/main.dart`  
**Severity:** High

### Problem
`AuthWrapper` was a `StatelessWidget` that passed `UserService().userExists(user.uid)` directly as the `future` argument to `FutureBuilder`. This created a new `Future` on every `build()` call. Since `StreamBuilder` rebuilds on every `authStateChanges()` emission (including token refreshes), this triggered repeated Firestore reads.

### Fix
Converted `AuthWrapper` to a `StatefulWidget` with `_cachedUid` and `_profileFuture` stored in state. A helper `_getProfileFuture(uid)` only creates a new `Future` when the uid changes. The cache is cleared when the user signs out.

---

## Bug 2 — `_onProviderChanged` navigating on `idle` status

**File:** `lib/screens/auth/otp_verification_screen.dart`  
**Severity:** Medium

### Problem
The provider listener in `OtpVerificationScreen` reacted to both `authenticated` and `idle` statuses to navigate away. However, `idle` is also the status restored by `clearError()` (when `_verificationId` is null). This could trigger a spurious navigation to `AuthWrapper` after an error was dismissed.

### Fix
Removed the `idle` case entirely from `_onProviderChanged`. The listener now only reacts to `authenticated`, which is the only status that indicates auto-verification has completed.

---

## Bug 3 — `TextEditingController` leaked in `build()`

**File:** `lib/screens/auth/register_screen.dart`  
**Severity:** Medium

### Problem
The DOB field created a `TextEditingController` inline inside the `build()` method:
```dart
controller: TextEditingController(text: ...)
```
A new controller was instantiated on every rebuild and never disposed, causing a memory leak.

### Fix
Added a stable `_dobController` field to `_RegisterScreenState`, disposed in `dispose()`. `_pickDob()` now updates `_dobController.text` directly when a date is selected. The redundant `hintText` expression that also re-evaluated `_selectedDob` on every build was also cleaned up.

---

## Bug 4 — `_verify()` had no in-flight guard (double submission)

**File:** `lib/screens/auth/otp_verification_screen.dart`  
**Severity:** Medium

### Problem
`_verify()` was triggered from two places: `_onDigitChanged` (auto-trigger on 6th digit) and the "Verify" button tap. There was a window between `_verify()` being called and `verifyOTP()` setting `AuthStatus.loading` during which `isLoading` was still `false`. A user tapping the button during this window would fire a second `signInWithCredential` call to Firebase.

### Fix
Added a `_isVerifying` bool flag set synchronously at the top of `_verify()` before any `await`. Any concurrent call returns immediately. The flag is reset to `false` after `verifyOTP()` completes so retries work correctly after an error.

---

## Bug 5 — Sign-out bypassed `AuthWrapper`

**File:** `lib/screens/home_screen.dart`  
**Severity:** Low

### Problem
After sign-out, `HomeScreen` navigated directly to `PhoneLoginScreen` instead of `AuthWrapper`. This removed `AuthWrapper`'s `StreamBuilder` from the widget tree, meaning it could no longer respond to future auth state changes (e.g. session restore on next cold start from that navigation stack).

### Fix
Changed the sign-out navigation target from `PhoneLoginScreen` to `AuthWrapper`. `AuthWrapper` detects `user == null` and renders `PhoneLoginScreen` naturally, while remaining active in the tree for future auth events.

---

## Bug 6 — `clearError()` restored stale `codeSent` status

**File:** `lib/providers/auth_provider.dart`  
**Severity:** Low

### Problem
`clearError()` restored status based on whether `_verificationId` was non-null:
```dart
_updateStatus(_verificationId != null ? AuthStatus.codeSent : AuthStatus.idle);
```
`_verificationId` was never cleared after a successful sign-in, so on the `RegisterScreen` (where the user is already signed in), a failed registration followed by `clearError()` would set status back to `codeSent` — a stale, incorrect state.

### Fix
`_verificationId` is now set to `null` after a successful sign-in in both `verifyOTP()` and `_handleAutoVerification()`. Once signed in, the verification ID is no longer valid or needed. With `_verificationId` null, `clearError()` correctly falls back to `idle`.
