import '../../auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../teams/providers/team_providers.dart';
import '../../players/providers/player_providers.dart';
import '../../matches/providers/match_providers.dart';
import '../../tournaments/providers/tournament_providers.dart';
import 'entity_editor.dart';

class EntityFormScreen extends ConsumerWidget {
  const EntityFormScreen({
    super.key,
    required this.kind,
    required this.id,
    this.teamId,
    this.tournamentId,
  });
  final String kind, id;
  final String? teamId, tournamentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, dynamic>?> value = id == 'new'
        ? const AsyncData({})
        : switch (kind) {
            'tournaments' =>
              ref.watch(tournamentProvider(id)).whenData((v) => v?.data),
            'teams' => ref.watch(teamProvider(id)).whenData((v) => v?.data),
            'players' => ref.watch(playersProvider(teamId!)).whenData((v) {
              final found = v.where((p) => p.id == id);
              return found.isEmpty ? null : found.first.data;
            }),
            _ => ref.watch(matchProvider(id)).whenData((v) => v?.data),
          };
    return AppScaffold(
      title:
          '${id == 'new' ? 'Create' : 'Edit'} ${kind == 'matches' ? 'match' : kind.substring(0, kind.length - 1)}',
      body: AsyncPanel(
        value: value,
        retry: () {
          switch (kind) {
            case 'tournaments':
              ref.invalidate(tournamentProvider(id));
            case 'teams':
              ref.invalidate(teamProvider(id));
            case 'players':
              ref.invalidate(playersProvider(teamId!));
            default:
              ref.invalidate(matchProvider(id));
          }
        },
        data: (data) => data == null
            ? const Center(child: Text('Record no longer exists.'))
            : AsyncPanel(
                value: ref.watch(tournamentsProvider),
                retry: () => ref.invalidate(tournamentsProvider),
                data: (tournaments) => AsyncPanel(
                  value: ref.watch(teamsProvider),
                  retry: () => ref.invalidate(teamsProvider),
                  data: (teams) => EntityEditor(
                    key: ValueKey('$kind/$id'),
                    kind: kind,
                    id: id,
                    teamId: teamId,
                    tournamentId: tournamentId,
                    initial: data,
                    tournaments:
                        ref.watch(managementAccessProvider) ||
                            kind == 'tournaments'
                        ? tournaments
                        : tournaments
                              .where(
                                (t) =>
                                    t.data['createdBy'] ==
                                    ref
                                        .watch(currentUserProvider)
                                        .asData
                                        ?.value
                                        ?.uid,
                              )
                              .toList(),
                    teams: teams,
                  ),
                ),
              ),
      ),
    );
  }
}
