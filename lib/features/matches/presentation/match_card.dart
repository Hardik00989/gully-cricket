import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../domain/cricket_match.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.tappable = true});
  final CricketMatch match;
  final bool tappable;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: tappable ? () => context.push('/matches/${match.id}') : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (match.status == 'live') ...[
                  const Icon(Icons.circle, color: AppColors.live, size: 8),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'LIVE',
                      style: AppText.label.copyWith(color: AppColors.live),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      match.status.toUpperCase(),
                      style: AppText.label,
                    ),
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${match.overs} OVERS',
                    style: AppText.label,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(match.teamAShort, style: AppText.team)),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      match.scoreFor(match.teamAId),
                      style: AppText.team,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text(match.teamBShort, style: AppText.team)),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      match.scoreFor(match.teamBId),
                      style: AppText.team,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              match.result['summary'] as String? ??
                  '${DateFormat('d MMM, h:mm a').format(match.scheduledAt)} · ${match.venue}',
            ),
          ],
        ),
      ),
    ),
  );
}
