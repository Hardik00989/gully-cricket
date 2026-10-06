import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);
final appUserStreamProvider = StreamProvider<AppUser?>((ref) async* {
  if (!await ref.watch(firebaseReadyProvider.future)) {
    yield null;
    return;
  }
  yield* ref.watch(authRepositoryProvider).watchUser();
});

class CurrentUser extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() {
    final user = ref.watch(appUserStreamProvider);
    return user.when(
      data: (value) => value,
      error: (error, stack) => Error.throwWithStackTrace(error, stack),
      loading: () => ref.watch(appUserStreamProvider.future),
    );
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUser, AppUser?>(
  CurrentUser.new,
);
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider).asData?.value != null,
);
final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider).asData?.value?.isAdmin ?? false,
);

const temporaryFullUserAccess = true;
final managementAccessProvider = Provider<bool>(
  (ref) =>
      ref.watch(isAdminProvider) ||
      temporaryFullUserAccess && ref.watch(isSignedInProvider),
);

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}
  Future<bool> submit({
    required String email,
    required String password,
    String? name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      if (name == null) {
        await repo.login(email, password);
      } else {
        await repo.register(name, email, password);
      }
    });
    return !state.hasError;
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).logout(),
    );
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
