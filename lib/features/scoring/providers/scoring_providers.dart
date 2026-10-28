import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/scoring_repository.dart';
import '../domain/scoring_engine.dart';

final scoringRepositoryProvider = Provider(
  (ref) => ScoringRepository(ref.watch(firestoreProvider)),
);

class ScoringController extends AsyncNotifier<void> {
  @override
  void build() {}
  Future<bool> score(String id, int revision, Delivery ball) =>
      _run(() => ref.read(scoringRepositoryProvider).score(id, revision, ball));
  Future<bool> start(
    String id,
    int revision, {
    required String striker,
    required String nonStriker,
    required String bowler,
    required String tossWinner,
    required String decision,
  }) => _run(
    () => ref
        .read(scoringRepositoryProvider)
        .start(
          id,
          revision,
          striker: striker,
          nonStriker: nonStriker,
          bowler: bowler,
          tossWinner: tossWinner,
          decision: decision,
        ),
  );
  Future<bool> bowler(String id, int revision, String bowler) => _run(
    () =>
        ref.read(scoringRepositoryProvider).changeBowler(id, revision, bowler),
  );
  Future<bool> undo(String id, int revision) =>
      _run(() => ref.read(scoringRepositoryProvider).undo(id, revision));
  Future<bool> end(String id, int revision) =>
      _run(() => ref.read(scoringRepositoryProvider).endInnings(id, revision));
  Future<bool> abandon(String id, int revision) =>
      _run(() => ref.read(scoringRepositoryProvider).abandon(id, revision));
  Future<bool> _run(Future<void> Function() action) async {
    if (!ref.read(managementAccessProvider)) {
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

final scoringControllerProvider =
    AsyncNotifierProvider<ScoringController, void>(ScoringController.new);
