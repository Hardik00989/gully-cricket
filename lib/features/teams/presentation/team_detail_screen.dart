import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../../core/widgets/record_menu.dart';
import '../../../core/widgets/empty_state.dart';
import '../../players/providers/player_providers.dart';
import '../providers/team_providers.dart';
import '../providers/team_access.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamProvider(id)).asData?.value;
    final manage = ref.watch(canManageSquadProvider(id));
    return AppScaffold(
      title: team?.name ?? 'Team squad',
      actions: [
        if (team != null) RecordMenu(kind: 'teams', id: id, name: team.name),
      ],
      body: AsyncPanel(
        value: ref.watch(teamProvider(id)),
        retry: () => ref.invalidate(teamProvider(id)),
        data: (team) => team == null
            ? const Center(child: Text('Team no longer exists.'))
            : AsyncPanel(
                value: ref.watch(playersProvider(id)),
                retry: () => ref.invalidate(playersProvider(id)),
                data: (players) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Squad - ${players.length} players',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (manage)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/teams/$id/squad/new'),
                                  icon: const Icon(Icons.person_add_outlined),
                                  label: const Text('Add player'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/teams/$id/squad'),
                                  child: const Text('Manage squad'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: players.isEmpty
                          ? EmptyState(
                              icon: Icons.groups_outlined,
                              title: 'Build your squad',
                              message: manage
                                  ? 'Add your batters, bowlers and wicketkeeper.'
                                  : 'Players will appear here when the squad is ready.',
                            )
                          : ListView.separated(
                              itemCount: players.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final player = players[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${player.jerseyNo}'),
                                  ),
                                  title: Text(player.name),
                                  subtitle: Text(player.roleLabel),
                                  trailing: manage
                                      ? const Icon(Icons.edit_outlined)
                                      : null,
                                  onTap: manage
                                      ? () => context.push(
                                          '/teams/$id/squad/${player.id}',
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
