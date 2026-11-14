import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/customer_home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/khan_logo.dart';

const _dark = Color(0xFF111618);
const _gold = Color(0xFFE5C158);
const _ivory = Color(0xFFFFFCF2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp(firebaseReady: true));
  } catch (error) {
    runApp(MyApp(firebaseError: error.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseReady = false, this.firebaseError});

  final bool firebaseReady;
  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khan Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          primary: _dark,
          secondary: _gold,
          surface: _ivory,
        ),
        scaffoldBackgroundColor: _ivory,
        appBarTheme: const AppBarTheme(
          backgroundColor: _dark,
          foregroundColor: _gold,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _gold),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: _gold, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _dark,
            foregroundColor: _gold,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: firebaseReady
          ? const AuthGate()
          : FirebaseSetupScreen(error: firebaseError),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: _gold, size: 48),
                  const SizedBox(height: 12),
                  const KhanLogo(width: 180, height: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase setup required',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error == null
                        ? 'Firebase is not configured for this platform.'
                        : 'Firebase could not initialize:\n$error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Android: run on an Android emulator or device with '
                    'android/app/google-services.json.\n'
                    'Chrome or Edge: add a Firebase Web app and configure '
                    'firebase_options.dart.\n'
                    'Windows desktop is not supported by these Firebase plugins.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        return user == null
            ? const LoginScreen()
            : CustomerHomeScreen(
                customerId: user.uid,
                customerName: user.displayName,
                customerEmail: user.email,
              );
      },
    );
  }
}
