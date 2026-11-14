import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/auth_helpers.dart';
import '../widgets/auth_scaffold.dart';

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
      _showError(firebaseAuthErrorMessage(error));
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
              validator: validateEmail,
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
                  : requiredField(value, 'Enter a password.'),
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
      decoration: authInputDecoration(label, icon),
      validator:
          validator ?? (value) => requiredField(value, 'Enter your $label.'),
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
      decoration: authInputDecoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      validator: validator,
    );
  }
}
