import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../admin/admin_home_screen.dart';
import '../patient/patient_home_screen.dart';
import '../therapist/therapist_home_screen.dart';

/// Manages the main authenticated app flow. Owns its own Navigator
/// so screens like home, profile, settings can push/pop internally.
/// AuthWrapper automatically disposes this entire flow on sign-out.
class MainAppFlow extends StatelessWidget {
  final UserModel user;
  const MainAppFlow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) {
          switch (user.role) {
            case 'admin':
              return AdminHomeScreen(user: user);
            case 'therapist':
              return TherapistHomeScreen(user: user);
            case 'patient':
            default:
              return PatientHomeScreen(user: user);
          }
        },
      ),
    );
  }
}
