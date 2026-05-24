import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart' as ap;
import 'screens/flows/auth_flow.dart';
import 'screens/flows/main_app_flow.dart';
import 'screens/flows/registration_flow.dart';
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

  runApp(const ProviderScope(child: MyApp()));
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
  // Cached so StreamBuilder doesn't re-subscribe on rebuilds.
  late final Stream<User?> _authStream;
  String? _cachedUid;
  Stream<UserModel?>? _profileStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  Stream<UserModel?> _getProfileStream(String uid) {
    if (uid != _cachedUid) {
      _cachedUid = uid;
      _profileStream = UserService().userStream(uid);
    }
    return _profileStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = authSnapshot.data;

        if (user == null) {
          _cachedUid = null;
          _profileStream = null;
          return const AuthFlow();
        }

        return StreamBuilder<UserModel?>(
          stream: _getProfileStream(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }
            if (profileSnapshot.hasError) {
              return const _SplashLoader();
            }
            return profileSnapshot.data != null
                ? MainAppFlow(user: profileSnapshot.data!)
                : const RegistrationFlow();
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