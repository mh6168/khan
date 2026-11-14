import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/customer_home_screen.dart';

const _green = Color(0xFF0D7A61);
const _darkGreen = Color(0xFF0A5F4B);
const _gold = Color(0xFFD68A2C);
const _ivory = Color(0xFFFAF8F3);

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
          seedColor: _green,
          primary: _green,
          secondary: _gold,
          surface: _ivory,
        ),
        scaffoldBackgroundColor: _ivory,
        appBarTheme: const AppBarTheme(
          backgroundColor: _green,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: _green, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue shopping on Khan.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration('Email address', Icons.email_outlined),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: _decoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your password.'
                  : null,
            ),
            const SizedBox(height: 24),
            _submitButton('Log in', _login),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : _openSignup,
              child: const Text('New to Khan? Create an account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _loading ? null : onPressed,
      child: _loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }

  Future<void> _openSignup() async {
    final accountCreated = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const SignupScreen()));
    if (accountCreated == true && mounted) {
      _showError('Account created successfully. Please log in.');
    }
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Your account could not be created. Please try again.',
        );
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (error) {
        _showError(
          'Your Firebase Auth account was created, but Firestore denied '
          'the customer profile write (${error.code}). Publish firestore.rules '
          'to project khan-81cd6, then try logging in again.',
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      _showError(_firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Join Khan and discover something special.',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_name, 'Full name', Icons.person_outline),
            const SizedBox(height: 14),
            _field(
              _email,
              'Email address',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            _field(
              _phone,
              'Phone number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _passwordField(
              _password,
              'Password',
              _obscurePassword,
              () => setState(() => _obscurePassword = !_obscurePassword),
              (value) => value != null && value.length < 6
                  ? 'Use at least 6 characters.'
                  : _required(value, 'Enter a password.'),
            ),
            const SizedBox(height: 14),
            _passwordField(
              _confirmPassword,
              'Confirm password',
              _obscureConfirmation,
              () =>
                  setState(() => _obscureConfirmation = !_obscureConfirmation),
              (value) =>
                  value != _password.text ? 'Passwords do not match.' : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Log in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _decoration(label, icon),
      validator: validator ?? (value) => _required(value, 'Enter your $label.'),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool obscureText,
    VoidCallback toggle,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: _decoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      validator: validator,
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: _gold,
                    size: 58,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'KHAN',
                    style: TextStyle(
                      color: _darkGreen,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label, IconData icon) =>
    InputDecoration(labelText: label, prefixIcon: Icon(icon));

String? _required(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;

String? _validateEmail(String? value) {
  if (_required(value, 'Enter your email address.') != null) {
    return 'Enter your email address.';
  }
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
      ? null
      : 'Enter a valid email address.';
}

String _firebaseMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'The email or password is incorrect.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Choose a stronger password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
