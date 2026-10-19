import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/standings_repository.dart';

final standingsRepositoryProvider = Provider((ref) => StandingsRepository());
