import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../data/match_repository.dart';
import '../domain/cricket_match.dart';

final matchRepositoryProvider = Provider(
  (ref) => MatchRepository(ref.watch(firestoreProvider)),
);
final matchesProvider = StreamProvider.autoDispose<List<CricketMatch>>(
  (ref) => ref.watch(matchRepositoryProvider).watchAll(),
);
final matchProvider = StreamProvider.autoDispose.family<CricketMatch?, String>(
  (ref, id) => ref.watch(matchRepositoryProvider).watch(id),
);
final liveMatchesProvider = StreamProvider.autoDispose<List<CricketMatch>>(
  (ref) => ref
      .watch(matchRepositoryProvider)
      .watchAll()
      .map((matches) => matches.where((m) => m.status == 'live').toList()),
);
