import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/firebase_providers.dart';
import '../data/team_repository.dart';
import '../domain/team.dart';

final teamRepositoryProvider = Provider(
  (ref) => TeamRepository(ref.watch(firestoreProvider)),
);
final teamsProvider = StreamProvider.autoDispose<List<Team>>(
  (ref) => ref.watch(teamRepositoryProvider).watchAll(),
);
final teamProvider = StreamProvider.autoDispose.family<Team?, String>(
  (ref, id) => ref.watch(teamRepositoryProvider).watch(id),
);
