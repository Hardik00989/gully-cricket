import '../../auth/providers/auth_providers.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../providers/tournament_providers.dart';

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Tournaments',
    floatingActionButton:
        ref.watch(managementAccessProvider) &&
            (ref.watch(tournamentsProvider).asData?.value.isNotEmpty ?? false)
        ? FloatingActionButton.extended(
            onPressed: () => context.push('/create/tournaments'),
            icon: const Icon(Icons.add),
            label: const Text('New tournament'),
          )
        : null,
    body: AsyncPanel(
      value: ref.watch(tournamentsProvider),
      retry: () => ref.invalidate(tournamentsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Your next tournament starts here',
              message:
                  'Create a tournament, add its teams and schedule a match.',
              action: ref.watch(managementAccessProvider)
                  ? () => context.push('/create/tournaments')
                  : null,
              actionLabel: 'Create tournament',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) {
                final t = items[index];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text(
                    '${t.location} · ${t.format}\n${DateFormat.yMMMd().format(t.startDate)} · ${t.status}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tournaments/${t.id}'),
                );
              },
            ),
    ),
  );
}
