import '../../auth/providers/auth_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../tournaments/providers/tournament_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../../core/widgets/team_logo.dart';
import '../providers/team_providers.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key, this.tournamentId});
  final String? tournamentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = AsyncPanel(
      value: ref.watch(teamsProvider),
      retry: () => ref.invalidate(teamsProvider),
      data: (all) {
        final teams = all
            .where(
              (t) =>
                  tournamentId == null ||
                  t.tournamentIds.contains(tournamentId) ||
                  (tournamentId != null &&
                      (ref
                              .watch(tournamentProvider(tournamentId!))
                              .asData
                              ?.value
                              ?.teamIds
                              .contains(t.id) ??
                          false)),
            )
            .toList();
        if (teams.isEmpty) {
          return EmptyState(
            icon: Icons.groups_outlined,
            title: 'No teams yet',
            message: 'Add a team, then build its squad.',
            action: ref.watch(managementAccessProvider)
                ? () => context.push(
                    '/create/teams${tournamentId == null ? '' : '?tournamentId=$tournamentId'}',
                  )
                : null,
            actionLabel: 'Add team',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final team = teams[index];
            return ListTile(
              leading: TeamLogo(name: team.shortName, url: team.logoUrl),
              title: Text(team.name),
              subtitle: Text(team.shortName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/teams/${team.id}'),
            );
          },
        );
      },
    );
    return tournamentId == null
        ? AppScaffold(
            title: 'Teams',
            body: list,
            floatingActionButton:
                ref.watch(managementAccessProvider) &&
                    (ref.watch(teamsProvider).asData?.value.isNotEmpty ?? false)
                ? FloatingActionButton.extended(
                    onPressed: () => context.push('/create/teams'),
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Add team'),
                  )
                : null,
          )
        : list;
  }
}
