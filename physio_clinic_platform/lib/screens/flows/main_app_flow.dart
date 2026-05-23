import 'package:flutter/material.dart';

import '../home_screen.dart';

/// Manages the main authenticated app flow. Owns its own Navigator
/// so screens like home, profile, settings can push/pop internally.
/// AuthWrapper automatically disposes this entire flow on sign-out.
class MainAppFlow extends StatelessWidget {
  const MainAppFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }
}
