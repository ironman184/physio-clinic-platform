import 'package:flutter/material.dart';

import '../auth/phone_login_screen.dart';

/// Owns a nested Navigator for the authentication flow (login → OTP).
/// When auth completes, AuthWrapper automatically swaps this entire flow out.
class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const PhoneLoginScreen(),
      ),
    );
  }
}
