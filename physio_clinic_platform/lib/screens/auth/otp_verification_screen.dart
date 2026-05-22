import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as ap;
import '../../main.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  bool _canResend = false;
  bool _hasNavigated = false;
  Timer? _timer;
  ap.AuthProvider? _authProvider;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<ap.AuthProvider>();
      // Listen for Android auto-verification completing in the background.
      _authProvider?.addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authProvider?.removeListener(_onProviderChanged);
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _startCountdown() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    if (mounted) _focusNodes[0].requestFocus();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateAfterVerification() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    // Let AuthWrapper decide whether to show HomeScreen or RegisterScreen.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthWrapper()),
      (_) => false,
    );
  }

  /// Called when Android auto-verification updates the provider state.
  void _onProviderChanged() {
    if (!mounted) return;
    final status = _authProvider?.status;
    if (status == ap.AuthStatus.authenticated) {
      _navigateAfterVerification();
    } else if (status == ap.AuthStatus.idle) {
      // idle after auth = new user (no profile yet)
      _navigateAfterVerification();
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < 6) {
      _showError('Please enter the complete 6-digit OTP.');
      return;
    }

    final provider = context.read<ap.AuthProvider>();
    await provider.verifyOTP(otp);

    if (!mounted) return;

    if (provider.status == ap.AuthStatus.error) {
      _clearBoxes();
      _showError(provider.errorMessage ?? 'Verification failed.');
      provider.clearError();
      return;
    }

    _navigateAfterVerification();
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    final provider = context.read<ap.AuthProvider>();
    await provider.sendOTP(widget.phoneNumber);

    if (!mounted) return;

    if (provider.status == ap.AuthStatus.codeSent) {
      _clearBoxes();
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (provider.status == ap.AuthStatus.error) {
      _showError(provider.errorMessage ?? 'Failed to resend OTP.');
      provider.clearError();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Consumer<ap.AuthProvider>(
          builder: (context, provider, _) {
            final isLoading = provider.status == ap.AuthStatus.loading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Verify OTP',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // ── OTP boxes ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onDigitChanged(v, i),
                        enabled: !isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // ── Verify button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : _verify,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Resend ─────────────────────────────────────────────
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _resendOTP,
                            child: const Text('Resend OTP'),
                          )
                        : Text(
                            'Resend OTP in $_secondsLeft s',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Private widget ─────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
