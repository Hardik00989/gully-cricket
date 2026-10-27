import 'package:flutter/material.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/domain/cricket_match.dart';
import '../domain/scoring_engine.dart';

class ScoreboardHeader extends StatelessWidget {
  const ScoreboardHeader({
    super.key,
    required this.match,
    required this.state,
    this.target,
  });
  final CricketMatch match;
  final InningsState state;
  final int? target;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(match.teamName(state.battingTeamId), style: AppText.label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Text('${state.runs}/${state.wickets}', style: AppText.score),
          Text('${state.overs} / ${match.overs} ov', style: AppText.team),
        ],
      ),
      Text(
        'Run rate ${state.runRate.toStringAsFixed(2)} · Extras ${state.extras}',
      ),
      if (target != null)
        Text(
          'Target $target · ${(target! - state.runs).clamp(0, target!)} needed from ${(match.overs * 6 - state.balls).clamp(0, match.overs * 6)} balls',
        ),
      const Divider(height: 32),
      Text(
        '${match.data['strikerName'] ?? ''} *',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(match.data['nonStrikerName'] as String? ?? ''),
      const SizedBox(height: 12),
      Text('Bowler: ${match.data['bowlerName'] ?? ''}'),
      if (state.freeHit && !state.closed) const Text('FREE HIT'),
      const Divider(height: 32),
    ],
  );
}
