import 'package:firebase_core/firebase_core.dart';

String friendlyError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have access to this action. Try signing in again.',
      'unavailable' || 'network-request-failed' =>
        'Check your internet connection and try again.',
      'email-already-in-use' =>
        'This email already has an account. Please log in.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      _ => error.message ?? 'Could not complete this action. Please try again.',
    };
  }
  if (error is StateError) return error.message;
  if (error is ArgumentError) {
    return error.message?.toString() ??
        'Please check the details and try again.';
  }
  return error.toString();
}
