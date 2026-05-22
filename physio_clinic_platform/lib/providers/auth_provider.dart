import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum AuthStatus { idle, loading, codeSent, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  AuthProvider({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _verificationId;
  UserModel? _currentUser;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _authService.currentUser;

  /// Loads the current user's profile from Firestore.
  Future<void> loadCurrentUser() async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) return;
    _currentUser = await _userService.getUser(fbUser.uid);
    notifyListeners();
  }

  /// Initiates phone number OTP flow.
  Future<void> sendOTP(String phoneNumber) async {
    _updateStatus(AuthStatus.loading);

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onAutoVerified: _handleAutoVerification,
      onFailed: (e) => _setError(_mapAuthError(e)),
      onCodeSent: (verificationId, _) {
        _verificationId = verificationId;
        _updateStatus(AuthStatus.codeSent);
      },
      onTimeout: (_) => _setError('OTP timed out. Please try again.'),
    );
  }

  /// Verifies OTP and signs the user in.
  /// AuthWrapper handles routing based on profile existence.
  Future<void> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      _setError('Session expired. Please request a new OTP.');
      return;
    }
    _updateStatus(AuthStatus.loading);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _authService.signInWithCredential(credential);
      _verificationId = null; // OTP flow complete.
      _updateStatus(AuthStatus.authenticated);

    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e));
    } catch (_) {
      _setError('Verification failed. Please try again.');
    }
  }

  /// Stores the user profile in Firestore
  Future<void> register({
    required String firstName,
    required String lastName,
    required String? email,
    required String gender,
    required DateTime dob,
    required String clinicId,
  }) async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) {
      _setError('Session expired. Please login again.');
      return;
    }
    _updateStatus(AuthStatus.loading);

    final user = UserModel(
      uid: fbUser.uid,
      clinicId: clinicId,
      phoneNumber: fbUser.phoneNumber ?? '',
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: (email == null || email.trim().isEmpty) ? null : email.trim(),
      gender: gender,
      dob: dob,
      role: 'patient',
      status: 'active',
      createdAt: DateTime.now(),
    );

    try {
      await _userService.createUser(user);
      _currentUser = user;
      _updateStatus(AuthStatus.authenticated);
    } catch (_) {
      _setError('Registration failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _verificationId = null;
    _updateStatus(AuthStatus.idle);
  }

  void clearError() {
    _errorMessage = null;
    _updateStatus(
      _verificationId != null ? AuthStatus.codeSent : AuthStatus.idle,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Called automatically on Android when Firebase SMS auto-read completes.
  Future<void> _handleAutoVerification(PhoneAuthCredential credential) async {
    try {
      await _authService.signInWithCredential(credential);
      _verificationId = null; // OTP flow complete.
      _updateStatus(AuthStatus.authenticated);
      // AuthWrapper reacts to authStateChanges() and handles routing.
    } catch (_) {
      _setError('Auto-verification failed. Please enter the OTP manually.');
    }
  }

  void _updateStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number entered is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP session has expired. Please request a new one.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
