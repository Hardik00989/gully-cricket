import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../matches/providers/match_providers.dart';
import '../../players/providers/player_providers.dart';
import '../providers/scoring_providers.dart';
import 'scoring_workspace.dart';

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Score match',
      body: AsyncPanel(
        value: ref.watch(matchProvider(id)),
        retry: () => ref.invalidate(matchProvider(id)),
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Match no longer exists.'));
          }
          return AsyncPanel(
            value: ref.watch(playersProvider(match.teamAId)),
            retry: () => ref.invalidate(playersProvider(match.teamAId)),
            data: (a) => AsyncPanel(
              value: ref.watch(playersProvider(match.teamBId)),
              retry: () => ref.invalidate(playersProvider(match.teamBId)),
              data: (b) => ScoringWorkspace(
                match: match,
                teamA: a,
                teamB: b,
                action: ref.watch(scoringControllerProvider),
              ),
            ),
          );
        },
      ),
    );
  }
}
