import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

InputDecoration authInputDecoration(String label, IconData icon) =>
    InputDecoration(labelText: label, prefixIcon: Icon(icon));

String? requiredField(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;

String? validateEmail(String? value) {
  if (requiredField(value, 'Enter your email address.') != null) {
    return 'Enter your email address.';
  }
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
      ? null
      : 'Enter a valid email address.';
}

String firebaseAuthErrorMessage(FirebaseAuthException error) {
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
