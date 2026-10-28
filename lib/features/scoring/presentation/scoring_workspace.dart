import 'match_options.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scoreboard_header.dart';
import 'run_controls.dart';
import 'scoring_dialogs.dart';
import '../../matches/domain/cricket_match.dart';
import '../../players/domain/player.dart';
import '../domain/scoring_engine.dart';
import '../providers/scoring_providers.dart';
import 'opening_sheet.dart';
import 'delivery_sheet.dart';

class ScoringWorkspace extends ConsumerWidget {
  const ScoringWorkspace({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.action,
  });
  final CricketMatch match;
  final List<Player> teamA, teamB;
  final AsyncValue<void> action;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = match;
    final state = m.innings.isEmpty
        ? null
        : InningsState.fromMap(m.innings[m.currentInnings]);
    final controller = ref.read(scoringControllerProvider.notifier);
    final busy = action.isLoading;
    final active =
        m.status == 'live' &&
        state != null &&
        !state.closed &&
        !state.awaitingBowler &&
        !busy;
    final batters = state?.battingTeamId == m.teamAId ? teamA : teamB;
    final bowlers = state?.battingTeamId == m.teamAId ? teamB : teamA;
    final target = m.currentInnings == 1
        ? (m.innings.first['runs'] as num).toInt() + 1
        : null;
    Future<void> opening() async {
      final selected = await showModalBottomSheet<OpeningSelection>(
        context: context,
        isScrollControlled: true,
        builder: (_) => OpeningSheet(match: m, teamA: teamA, teamB: teamB),
      );
      if (selected != null) {
        await controller.start(
          m.id,
          m.revision,
          striker: selected.striker,
          nonStriker: selected.nonStriker,
          bowler: selected.bowler,
          tossWinner: selected.tossWinner,
          decision: selected.decision,
        );
      }
    }

    Future<void> special({
      ExtraType extra = ExtraType.none,
      bool wicket = false,
    }) async {
      final ball = await showModalBottomSheet<Delivery>(
        context: context,
        isScrollControlled: true,
        builder: (_) => DeliverySheet(
          state: state!,
          players: batters,
          maxOvers: m.overs,
          target: target,
          extra: extra,
          wicket: wicket,
        ),
      );
      if (ball != null) await controller.score(m.id, m.revision, ball);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${m.teamAName} v ${m.teamBName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        if (state != null)
          ScoreboardHeader(match: m, state: state, target: target),
        if (action.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              friendlyError(action.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (busy) const LinearProgressIndicator(),
        if (m.status == 'upcoming' ||
            m.status == 'live' &&
                state?.closed == true &&
                m.currentInnings == 0)
          FilledButton(
            onPressed: busy ? null : opening,
            child: Text(
              m.status == 'upcoming' ? 'Start match' : 'Start second innings',
            ),
          ),
        if (m.status == 'live' && state != null && !state.closed) ...[
          RunControls(
            enabled: active,
            onRuns: (runs) =>
                controller.score(m.id, m.revision, Delivery(runsOffBat: runs)),
            onExtra: (extra) => special(extra: extra),
            onWicket: () => special(wicket: true),
          ),
          if (state.awaitingBowler)
            const Text('Over complete. Select the next bowler to continue.'),
          if (state.awaitingBowler)
            FilledButton(
              onPressed: busy || !state.awaitingBowler
                  ? null
                  : () async {
                      final selected = await pickNextBowler(
                        context,
                        bowlers,
                        state.bowlerId,
                      );
                      if (selected != null) {
                        await controller.bowler(m.id, m.revision, selected);
                      }
                    },
              child: const Text('Choose next bowler'),
            ),
        ],
        if ((m.data['lastBallId'] as String? ?? '').isNotEmpty)
          TextButton.icon(
            onPressed: busy
                ? null
                : () async {
                    if (await confirmScoringAction(
                      context,
                      'Undo last ball?',
                      'The score and players will return to their state before the last delivery.',
                    )) {
                      await controller.undo(m.id, m.revision);
                    }
                  },
            icon: const Icon(Icons.undo),
            label: const Text('Undo last ball'),
          ),
        MatchOptions(match: m, busy: busy),
        if (m.status == 'completed' || m.status == 'abandoned')
          Text(
            m.result['summary'] as String? ?? m.status,
            style: Theme.of(context).textTheme.titleLarge,
          ),
      ],
    );
  }
}
