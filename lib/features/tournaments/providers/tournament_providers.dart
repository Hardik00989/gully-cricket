import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../data/tournament_repository.dart';
import '../domain/tournament.dart';

final tournamentRepositoryProvider = Provider(
  (ref) => TournamentRepository(ref.watch(firestoreProvider)),
);
final tournamentsProvider = StreamProvider.autoDispose<List<Tournament>>(
  (ref) => ref.watch(tournamentRepositoryProvider).watchAll(),
);
final tournamentProvider = StreamProvider.autoDispose
    .family<Tournament?, String>(
      (ref, id) => ref.watch(tournamentRepositoryProvider).watch(id),
    );
