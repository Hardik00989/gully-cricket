import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../providers/match_providers.dart';
import 'match_list.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 3,
    initialIndex: initialTab.clamp(0, 2),
    child: AppScaffold(
      title: 'Matches',
      floatingActionButton: ref.watch(managementAccessProvider)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create/matches'),
              icon: const Icon(Icons.add),
              label: const Text('Schedule match'),
            )
          : null,
      body: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Live'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: AsyncPanel(
              value: ref.watch(matchesProvider),
              retry: () => ref.invalidate(matchesProvider),
              data: (matches) => TabBarView(
                children: ['live', 'upcoming', 'completed']
                    .map(
                      (status) => MatchList(
                        matches:
                            (status == 'completed' ? matches.reversed : matches)
                                .where(
                                  (m) =>
                                      m.status == status ||
                                      status == 'completed' &&
                                          m.status == 'abandoned',
                                )
                                .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
