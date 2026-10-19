import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../matches/providers/match_providers.dart';
import '../../teams/providers/team_providers.dart';
import '../../tournaments/providers/tournament_providers.dart';
import '../providers/standings_providers.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key, this.tournamentId});
  final String? tournamentId;
  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    final body = AsyncPanel(
      value: ref.watch(tournamentsProvider),
      retry: () => ref.invalidate(tournamentsProvider),
      data: (tournaments) {
        if (tournaments.isEmpty) {
          return const Center(child: Text('No tournaments yet.'));
        }
        final id =
            widget.tournamentId ??
            (tournaments.any((t) => t.id == selected)
                ? selected
                : tournaments.first.id)!;
        return Column(
          children: [
            if (widget.tournamentId == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: id,
                  decoration: const InputDecoration(labelText: 'Tournament'),
                  items: tournaments
                      .map(
                        (t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
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
    return widget.tournamentId == null
        ? AppScaffold(title: 'Points Table', body: body)
        : body;
  }
}
