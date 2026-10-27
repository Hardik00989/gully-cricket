import '../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../matches/providers/match_providers.dart';
import '../../matches/presentation/match_card.dart';
import '../../players/providers/player_providers.dart';
import '../providers/scoring_providers.dart';
import 'scoring_workspace.dart';

class ScoringScreen extends ConsumerWidget {
  const ScoringScreen({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) {
      return AppScaffold(
        title: 'Choose a match to score',
        body: AsyncPanel(
          value: ref.watch(matchesProvider),
          retry: () => ref.invalidate(matchesProvider),
          data: (matches) {
            final eligible = matches
                .where((m) => ['upcoming', 'live'].contains(m.status))
                .toList();
            if (eligible.isEmpty) {
              return EmptyState(
                icon: Icons.sports_cricket,
                title: 'Ready to play?',
                message: 'Schedule a match before you start recording balls.',
                action: () => context.push('/create/matches'),
                actionLabel: 'Schedule match',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: eligible
                  .map(
                    (m) => Column(
                      children: [
                        MatchCard(match: m),
                        FilledButton(
                          onPressed: () =>
                              context.push('/admin/scoring/${m.id}'),
                          child: Text(
                            m.status == 'upcoming'
                                ? 'Start this match'
                                : 'Continue scoring',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            );
          },
        ),
      );
    }
    return AppScaffold(
      title: 'Score match',
      body: AsyncPanel(
        value: ref.watch(matchProvider(id!)),
        retry: () => ref.invalidate(matchProvider(id!)),
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
