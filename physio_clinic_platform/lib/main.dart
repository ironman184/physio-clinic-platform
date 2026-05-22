import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as ap;
import 'screens/auth/phone_login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Disable reCAPTCHA / Play Integrity checks in debug builds so that
  // Firebase test phone numbers work on emulators without Play Services.
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ap.AuthProvider(),
      child: MaterialApp(
        title: 'Physio Clinic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0077B6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Decides the initial route based on Firebase auth state + Firestore profile.
/// This handles cold-start and session-restore scenarios automatically.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Cached so FutureBuilder doesn't re-fire on every rebuild.
  String? _cachedUid;
  Future<bool>? _profileFuture;

  Future<bool> _getProfileFuture(String uid) {
    if (uid != _cachedUid) {
      _cachedUid = uid;
      _profileFuture = UserService().userExists(uid);
    }
    return _profileFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for Firebase to restore the auth state.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = authSnapshot.data;

        // Not logged in → show login screen.
        if (user == null) {
          // Clear cache so next login re-checks Firestore.
          _cachedUid = null;
          _profileFuture = null;
          return const PhoneLoginScreen();
        }

        // Logged in → check Firestore for existing profile (cached per uid).
        return FutureBuilder<bool>(
          future: _getProfileFuture(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }
            final hasProfile = profileSnapshot.data ?? false;
            return hasProfile ? const HomeScreen() : const RegisterScreen();
          },
        );
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}