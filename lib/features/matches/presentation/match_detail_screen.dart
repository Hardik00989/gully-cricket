import '../../../core/widgets/record_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/async_panel.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/match_providers.dart';
import '../providers/ball_providers.dart';
import 'match_card.dart';
import 'scorecard.dart';
import 'recent_balls.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    title: 'Match centre',
    actions: [
      if (ref.watch(matchProvider(id)).asData?.value case final match?)
        RecordMenu(
          kind: 'matches',
          id: id,
          name: 'this match',
          allowEdit: match.status == 'upcoming',
        ),
    ],
    body: AsyncPanel(
      value: ref.watch(matchProvider(id)),
      retry: () => ref.invalidate(matchProvider(id)),
      data: (match) {
        if (match == null) {
          return const Center(child: Text('Match no longer exists.'));
        }
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MatchCard(match: match, tappable: false),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Live'),
                  Tab(text: 'Scorecard'),
                  Tab(text: 'Summary'),
                ],
              ),
              Expanded(
                child: AsyncPanel(
                  value: ref.watch(ballsProvider(id)),
                  retry: () => ref.invalidate(ballsProvider(id)),
                  data: (balls) => TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (match.innings.isNotEmpty) ...[
                            Text(
                              '${match.innings[match.currentInnings]['runs']}/${match.innings[match.currentInnings]['wickets']}',
                              style: AppText.score,
                            ),
                            Text(
                              'Run rate: ${_rate(match.innings[match.currentInnings])}',
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'At the crease',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Striker: ${match.data['strikerName'] ?? 'Not selected'} *',
                            ),
                            Text(
                              'Non-striker: ${match.data['nonStrikerName'] ?? 'Not selected'}',
                            ),
                            Text(
                              'Bowler: ${match.data['bowlerName'] ?? 'Not selected'}',
                            ),
                          ],
                          const SizedBox(height: 24),
                          RecentBalls(
                            balls: balls,
                            innings: match.currentInnings,
                          ),
                          if (ref.watch(managementAccessProvider) &&
                              match.status != 'completed' &&
                              match.status != 'abandoned')
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: FilledButton(
                                onPressed: () =>
                                    context.push('/admin/scoring/$id'),
                                child: Text(
                                  match.status == 'upcoming'
                                      ? 'Start scoring'
                                      : 'Continue scoring',
                                ),
                              ),
                            ),
                        ],
                      ),
                      Scorecard(match: match, balls: balls),
                      ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            '${match.teamAName} v ${match.teamBName}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(match.venue),
                          Text(
                            DateFormat.yMMMd().add_jm().format(
                              match.scheduledAt,
                            ),
                          ),
                          Text('${match.overs} overs per innings'),
                          const SizedBox(height: 16),
                          Text(
                            match.result['summary'] as String? ??
                                'Match ${match.status}',
                          ),
                          if (match.data['toss'] is Map)
                            Text(
                              'Toss: ${match.teamName(match.data['toss']['winnerTeamId'] as String? ?? '')} chose to ${match.data['toss']['decision']}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  String _rate(Map<String, dynamic> i) {
    final balls = (i['balls'] as num).toInt();
    return balls == 0
        ? '0.00'
        : ((i['runs'] as num) * 6 / balls).toStringAsFixed(2);
  }
}
