import '../../../core/utils/firestore_paths.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  Stream<AppUser?> watchUser() {
    late StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSubscription;
    var generation = 0;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    profileSubscription;
    controller = StreamController<AppUser?>(
      onListen: () {
        authSubscription = auth.authStateChanges().listen((user) async {
          final current = ++generation;
          await profileSubscription?.cancel();
          if (controller.isClosed || current != generation) return;
          if (user == null) {
            controller.add(null);
            return;
          }
          profileSubscription = db
              .cricketCollection('users')
              .doc(user.uid)
              .snapshots()
              .listen(
                (doc) => controller.add(
                  AppUser.fromMap(
                    user.uid,
                    doc.data() ??
                        {
                          'name': user.displayName ?? '',
                          'email': user.email ?? '',
                          'role': 'user',
                        },
                  ),
                ),
                onError: controller.addError,
              );
        }, onError: controller.addError);
      },
      onCancel: () async {
        generation++;
        await authSubscription?.cancel();
        await profileSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> login(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureProfile(
      credential.user!,
      credential.user!.displayName ?? email.split('@').first,
    );
  }

  Future<void> register(String name, String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    await _ensureProfile(credential.user!, name.trim());
  }

  Future<void> _ensureProfile(User user, String name) =>
      db.runTransaction((tx) async {
        final doc = db.cricketCollection('users').doc(user.uid);
        final existing = await tx.get(doc);
        if (!existing.exists) {
          tx.set(doc, {
            'name': name,
            'email': user.email,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

  Future<void> logout() => auth.signOut();
}
