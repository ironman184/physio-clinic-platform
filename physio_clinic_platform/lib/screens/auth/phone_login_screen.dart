import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as ap;
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _completePhoneNumber = '';
  ap.AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    // Set up listener after the first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = context.read<ap.AuthProvider>();
      _authProvider!.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  /// Reacts to provider changes so navigation happens as soon as
  /// onCodeSent fires — even if the verifyPhoneNumber Future has
  /// already returned (race condition on Android).
  void _onAuthStateChanged() {
    if (!mounted || _authProvider == null) return;
    switch (_authProvider!.status) {
      case ap.AuthStatus.codeSent:
        _authProvider!.removeListener(_onAuthStateChanged);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationScreen(phoneNumber: _completePhoneNumber),
          ),
        );
      case ap.AuthStatus.error:
        _showError(_authProvider!.errorMessage ?? 'Failed to send OTP.');
        _authProvider!.clearError();
      default:
        break;
    }
  }

  void _sendOTP() {
    if (!_formKey.currentState!.validate()) return;
    // Fire and forget — navigation is handled reactively by _onAuthStateChanged.
    _authProvider?.sendOTP(_completePhoneNumber);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer<ap.AuthProvider>(
          builder: (context, provider, _) {
            final isLoading = provider.status == ap.AuthStatus.loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 72),
                  // ── Logo / Branding ──────────────────────────────────
                  Icon(
                    Icons.health_and_safety_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to continue.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // ── Phone field ──────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.4),
                      ),
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _completePhoneNumber = phone.completeNumber;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ── CTA ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : _sendOTP,                      
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
                              'Send OTP',
                              style: TextStyle(fontSize: 16),
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
