import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/async_panel.dart';
import '../../matches/providers/match_providers.dart';
import '../../teams/providers/team_providers.dart';
import '../../tournaments/providers/tournament_providers.dart';
import '../providers/standings_providers.dart';

class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key, required this.tournamentId});
  final String tournamentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tournamentId;
    return AsyncPanel(
      value: ref.watch(tournamentsProvider),
      retry: () => ref.invalidate(tournamentsProvider),
      data: (tournaments) {
        return Column(
          children: [
            Expanded(
              child: AsyncPanel(
                value: ref.watch(teamsProvider),
                retry: () => ref.invalidate(teamsProvider),
                data: (teams) => AsyncPanel(
                  value: ref.watch(matchesProvider),
                  retry: () => ref.invalidate(matchesProvider),
                  data: (matches) {
                    final rows = ref
                        .read(standingsRepositoryProvider)
                        .calculate(
                          teams,
                          matches,
                          id,
                          teamIds:
                              tournaments
                                  .where((t) => t.id == id)
                                  .firstOrNull
                                  ?.teamIds ??
                              [],
                        );
                    if (rows.isEmpty) {
                      return const Center(
                        child: Text('No teams in this tournament.'),
                      );
                    }
                    return SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            'Team',
                            'P',
                            'W',
                            'L',
                            'T',
                            'NR',
                            'NRR',
                            'Pts',
                          ].map((s) => DataColumn(label: Text(s))).toList(),
                          rows: rows
                              .map(
                                (r) => DataRow(
                                  cells: [
                                    r.name,
                                    r.played,
                                    r.won,
                                    r.lost,
                                    r.tied,
                                    r.noResult,
                                    r.nrr.toStringAsFixed(3),
                                    r.points,
                                  ].map((v) => DataCell(Text('$v'))).toList(),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
