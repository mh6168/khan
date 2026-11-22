import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'screens/customer_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/master_dealer_dashboard_screen.dart';
import 'screens/paymob_return_screen.dart';
import 'screens/reservation/reservation_paymob_return_screen.dart';
import 'widgets/khan_logo.dart';

const _dark = Color(0xFF111618);
const _gold = Color(0xFFE5C158);
const _ivory = Color(0xFFFFFCF2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
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
        if (user == null) return const LoginScreen();

        final reservationOrderId = Uri
            .base
            .queryParameters['khan_reservation_order_id']
            ?.trim();
        if (reservationOrderId != null &&
            reservationOrderId.isNotEmpty &&
            RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(reservationOrderId)) {
          String? transactionId;
          for (final key in const [
            'id',
            'transaction_id',
            'txn_id',
            'payment_id',
          ]) {
            final value = Uri.base.queryParameters[key]?.trim();
            if (value != null && value.isNotEmpty) {
              transactionId = value;
              break;
            }
          }
          final cancelled =
              Uri.base.queryParameters['cancelled']?.toLowerCase() == 'true' ||
              Uri.base.queryParameters['status']?.toLowerCase() == 'cancelled';
          return ReservationPaymobReturnScreen(
            orderId: reservationOrderId,
            customerId: user.uid,
            transactionId: transactionId,
            wasCancelled: cancelled,
            customerName: user.displayName,
            customerEmail: user.email,
          );
        }

        final callback = PaymobReturnData.fromUri(Uri.base);
        if (callback != null) {
          return PaymobReturnScreen(
            callback: callback,
            customerId: user.uid,
            customerName: user.displayName,
            customerEmail: user.email,
          );
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Your account profile could not be loaded.'),
                ),
              );
            }
            final role = profileSnapshot.data?.data()?['role'];
            if (role == 'masterDealer') {
              return const MasterDealerDashboardScreen();
            }
            return CustomerHomeScreen(
              customerId: user.uid,
              customerName: user.displayName,
              customerEmail: user.email,
            );
          },
        );
      },
    );
  }
}
