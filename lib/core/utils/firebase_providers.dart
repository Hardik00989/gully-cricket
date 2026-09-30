import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const useEmulators = bool.fromEnvironment('USE_EMULATORS');
const emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
final firebaseReadyProvider = FutureProvider<bool>((ref) async {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if (!useEmulators &&
      [apiKey, appId, senderId, projectId].any((s) => s.isEmpty)) {
    return false;
  }
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: useEmulators ? 'demo-api-key' : apiKey,
      appId: useEmulators ? '1:123456789:android:0123456789abcdef' : appId,
      messagingSenderId: useEmulators ? '123456789' : senderId,
      projectId: useEmulators ? 'demo-gully-cricket' : projectId,
    ),
  );
  if (useEmulators) {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  }
  return true;
});
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
