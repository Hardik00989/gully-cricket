import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../../core/widgets/record_menu.dart';
import '../../auth/providers/auth_providers.dart';
import '../../matches/providers/match_providers.dart';
import '../../matches/presentation/match_list.dart';
import '../../teams/presentation/teams_screen.dart';
import '../../standings/presentation/standings_screen.dart';
import '../providers/tournament_providers.dart';

class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(tournamentProvider(id));
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: value.asData?.value?.name ?? 'Tournament',
        actions: [
          if (value.asData?.value != null)
            RecordMenu(
              kind: 'tournaments',
              id: id,
              name: value.asData!.value!.name,
            ),
        ],
        body: AsyncPanel(
          value: value,
          retry: () => ref.invalidate(tournamentProvider(id)),
          data: (tournament) => tournament == null
              ? const Center(child: Text('Tournament no longer exists.'))
              : Column(
                  children: [
                    if (ref.watch(managementAccessProvider))
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/create/teams?tournamentId=$id',
                              ),
                              icon: const Icon(Icons.group_add_outlined),
                              label: const Text('Add team'),
                            ),
                            FilledButton.icon(
                              onPressed: () => context.push(
                                '/create/matches?tournamentId=$id',
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Schedule match'),
                            ),
                          ],
                        ),
                      ),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Matches'),
                        Tab(text: 'Teams'),
                        Tab(text: 'Points'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          AsyncPanel(
                            value: ref.watch(matchesProvider),
                            retry: () => ref.invalidate(matchesProvider),
                            data: (matches) => MatchList(
                              matches:
                                  matches
                                      .where((m) => m.tournamentId == id)
                                      .toList()
                                    ..sort((a, b) {
                                      const order = {
                                        'live': 0,
                                        'upcoming': 1,
                                        'completed': 2,
                                        'abandoned': 3,
                                      };
                                      final status = (order[a.status] ?? 3)
                                          .compareTo(order[b.status] ?? 3);
                                      return status != 0
                                          ? status
                                          : a.status == 'completed'
                                          ? b.scheduledAt.compareTo(
                                              a.scheduledAt,
                                            )
                                          : a.scheduledAt.compareTo(
                                              b.scheduledAt,
                                            );
                                    }),
                              emptyText:
                                  'No matches scheduled. Add teams, then schedule your first match.',
                            ),
                          ),
                          TeamsScreen(tournamentId: id),
                          StandingsScreen(tournamentId: id),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
