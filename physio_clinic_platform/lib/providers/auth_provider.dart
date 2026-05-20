import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, codeSent, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _verificationId;
  UserModel? _currentUser;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _authService.currentUser;

  /// No-op until Firestore is re-enabled.
  Future<void> loadCurrentUser() async {}

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

  /// Verifies OTP. Always returns `false` (treat every user as new) until
  /// Firestore profile lookup is re-enabled.
  Future<bool> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      _setError('Session expired. Please request a new OTP.');
      return false;
    }
    _updateStatus(AuthStatus.loading);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _authService.signInWithCredential(credential);
      // Always send to RegisterScreen for now (no Firestore profile check).
      _updateStatus(AuthStatus.idle);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e));
      return false;
    } catch (_) {
      _setError('Verification failed. Please try again.');
      return false;
    }
  }

  /// Stores the user profile in-memory only (Firestore write disabled for now).
  Future<void> register({
    required String name,
    required String? email,
    required String role,
  }) async {
    final fbUser = _authService.currentUser;
    if (fbUser == null) {
      _setError('Session expired. Please login again.');
      return;
    }
    _updateStatus(AuthStatus.loading);

    final user = UserModel(
      uid: fbUser.uid,
      phoneNumber: fbUser.phoneNumber ?? '',
      name: name.trim(),
      email: (email == null || email.trim().isEmpty) ? null : email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    _updateStatus(AuthStatus.authenticated);
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
      // Always route to RegisterScreen (no Firestore profile check).
      _updateStatus(AuthStatus.idle);
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
