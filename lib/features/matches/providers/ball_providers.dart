import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_providers.dart';

final ballsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) => ref.watch(matchRepositoryProvider).watchBalls(id),
    );
