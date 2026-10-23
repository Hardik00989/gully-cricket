import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tournaments/providers/tournament_providers.dart';
import '../../teams/providers/team_providers.dart';
import '../../teams/providers/team_access.dart';
import '../../players/providers/player_providers.dart';
import '../../matches/providers/match_providers.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider(
  (ref) => AdminRepository(ref.watch(firestoreProvider)),
);
final usersProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(adminRepositoryProvider).watchUsers(),
);

class AdminController extends AsyncNotifier<void> {
  String? savedId;
  @override
  void build() {}
  Future<bool> save(
    String kind,
    String? id,
    Map<String, dynamic> data, {
    String? teamId,
  }) => _run(
    () async {
      savedId = null;
      switch (kind) {
        case 'tournaments':
          savedId = await ref.read(tournamentRepositoryProvider).save(id, data);
        case 'teams':
          savedId = await ref.read(teamRepositoryProvider).save(id, data);
        case 'matches':
          savedId = await ref.read(matchRepositoryProvider).save(id, data);
        case 'players':
          await ref.read(playerRepositoryProvider).save(teamId!, id, data);
        default:
          throw ArgumentError('Unknown editor');
      }
    },
    allowCreate:
        id == null && ['tournaments', 'teams', 'matches'].contains(kind),
    allowSquad:
        kind == 'players' &&
        teamId != null &&
        ref.read(canManageSquadProvider(teamId)),
  );
  Future<bool> delete(String kind, String id, {String? teamId}) =>
      _run(() async {
        switch (kind) {
          case 'tournaments':
            await ref.read(tournamentRepositoryProvider).delete(id);
          case 'teams':
            await ref.read(teamRepositoryProvider).delete(id);
          case 'matches':
            await ref.read(matchRepositoryProvider).delete(id);
          case 'players':
            await ref.read(playerRepositoryProvider).delete(teamId!, id);
          default:
            throw ArgumentError('Unknown editor');
        }
      });
  Future<bool> role(String uid, String role) => _run(
    () => ref
        .read(adminRepositoryProvider)
        .changeRole(uid, role, ref.read(currentUserProvider).requireValue!.uid),
  );
  Future<bool> _run(
    Future<void> Function() action, {
    bool allowCreate = false,
    bool allowSquad = false,
  }) async {
    if (!ref.read(managementAccessProvider) &&
        !(allowCreate && ref.read(isSignedInProvider)) &&
        !allowSquad) {
      state = AsyncError(
        StateError('Administrator access required'),
        StackTrace.current,
      );
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final adminControllerProvider = AsyncNotifierProvider<AdminController, void>(
  AdminController.new,
);
