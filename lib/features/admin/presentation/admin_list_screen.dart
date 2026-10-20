import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../matches/providers/match_providers.dart';
import '../../teams/providers/team_providers.dart';
import '../../players/providers/player_providers.dart';
import '../../tournaments/providers/tournament_providers.dart';
import '../domain/admin_entry.dart';
import '../providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';

class AdminListScreen extends ConsumerWidget {
  const AdminListScreen({
    super.key,
    required this.kind,
    this.teamId,
    this.basePath,
  });
  final String kind;
  final String? teamId;
  final String? basePath;
  String get base =>
      basePath ??
      (kind == 'players' ? '/admin/teams/$teamId/players' : '/admin/$kind');
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AdminEntry>> items = switch (kind) {
      'tournaments' =>
        ref
            .watch(tournamentsProvider)
            .whenData(
              (list) => list
                  .map((t) => AdminEntry(t.id, t.name, t.location, t.data))
                  .toList(),
            ),
      'teams' =>
        ref
            .watch(teamsProvider)
            .whenData(
              (list) => list
                  .map((t) => AdminEntry(t.id, t.name, t.shortName, t.data))
                  .toList(),
            ),
      'players' =>
        ref
            .watch(playersProvider(teamId!))
            .whenData(
              (list) => list
                  .map((p) => AdminEntry(p.id, p.name, p.role, p.data))
                  .toList(),
            ),
      _ =>
        ref
            .watch(matchesProvider)
            .whenData(
              (list) => list
                  .map(
                    (m) => AdminEntry(
                      m.id,
                      '${m.teamAName} v ${m.teamBName}',
                      m.status,
                      m.data,
                    ),
                  )
                  .toList(),
            ),
    };
    return AppScaffold(
      title: kind == 'players' ? 'Manage squad' : 'Manage $kind',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('$base/new'),
        icon: const Icon(Icons.add),
        label: Text(kind == 'players' ? 'Add player' : 'Add new'),
      ),
      body: AsyncPanel(
        value: items,
        retry: () {
          switch (kind) {
            case 'tournaments':
              ref.invalidate(tournamentsProvider);
            case 'teams':
              ref.invalidate(teamsProvider);
            case 'players':
              ref.invalidate(playersProvider(teamId!));
            default:
              ref.invalidate(matchesProvider);
          }
        },
        data: (entries) => entries.isEmpty
            ? const Center(
                child: Text(
                  'Nothing here yet. Use the add button to get started.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) {
                  final e = entries[index];
                  return ListTile(
                    title: Text(e.title),
                    subtitle: Text(e.subtitle),
                    onTap: () => context.push('$base/${e.id}'),
                    trailing: Wrap(
                      children: [
                        if (kind == 'teams')
                          IconButton(
                            tooltip: 'Manage squad',
                            icon: const Icon(Icons.groups_outlined),
                            onPressed: () =>
                                context.push('/admin/teams/${e.id}/players'),
                          ),
                        if (ref.watch(managementAccessProvider))
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed:
                                ref.watch(adminControllerProvider).isLoading
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete ${e.title}?'),
                                        content: const Text(
                                          'This permanently removes the record.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    final ok = await ref
                                        .read(adminControllerProvider.notifier)
                                        .delete(kind, e.id, teamId: teamId);
                                    if (!ok && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ref
                                                .read(adminControllerProvider)
                                                .error
                                                .toString(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
