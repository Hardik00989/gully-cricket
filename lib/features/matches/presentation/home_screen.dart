import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/match_providers.dart';
import 'home_actions.dart';
import 'match_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Gully Cricket',
    body: AsyncPanel(
      value: ref.watch(matchesProvider),
      retry: () => ref.invalidate(matchesProvider),
      data: (matches) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Every ball. Every run.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Follow local cricket or organise your next match.'),
          const SizedBox(height: 20),
          if (ref.watch(managementAccessProvider))
            HomeActions(firstMatch: matches.isEmpty)
          else if (matches.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No matches yet. Sign in to set up your first tournament.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Login to get started'),
                ),
              ],
            ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (matches.any((m) => m.status == 'live'))
              MatchSection(
                title: 'LIVE NOW',
                horizontal: true,
                matches: matches.where((m) => m.status == 'live').toList(),
              ),
            if (matches.any((m) => m.status == 'upcoming'))
              MatchSection(
                title: 'UPCOMING MATCHES',
                matches: matches.where((m) => m.status == 'upcoming').toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
              ),
            if (matches.any(
              (m) => ['completed', 'abandoned'].contains(m.status),
            ))
              MatchSection(
                title: 'RECENT RESULTS',
                matches:
                    matches
                        .where(
                          (m) => ['completed', 'abandoned'].contains(m.status),
                        )
                        .toList()
                      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)),
              ),
          ],
        ],
      ),
    ),
  );
}
