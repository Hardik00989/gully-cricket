import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../data/player_repository.dart';
import '../domain/player.dart';

final playerRepositoryProvider = Provider(
  (ref) => PlayerRepository(ref.watch(firestoreProvider)),
);
final playersProvider = StreamProvider.autoDispose.family<List<Player>, String>(
  (ref, teamId) => ref.watch(playerRepositoryProvider).watchTeam(teamId),
);
