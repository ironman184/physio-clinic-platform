import 'package:flutter/material.dart';

import '../auth/register_screen.dart';

/// Manages the registration/onboarding flow for authenticated users
/// without a Firestore profile. Owns its own Navigator so future
/// onboarding steps can be added as additional routes.
/// AuthWrapper automatically replaces this flow once a profile exists.
class RegistrationFlow extends StatelessWidget {
  const RegistrationFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }
}
