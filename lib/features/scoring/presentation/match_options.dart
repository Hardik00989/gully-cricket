import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../matches/domain/cricket_match.dart';
import '../providers/scoring_providers.dart';
import 'scoring_dialogs.dart';

class MatchOptions extends ConsumerWidget {
  const MatchOptions({super.key, required this.match, required this.busy});
  final CricketMatch match;
  final bool busy;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!['upcoming', 'live'].contains(match.status)) {
      return const SizedBox.shrink();
    }
    final controller = ref.read(scoringControllerProvider.notifier);
    final active =
        match.innings.isNotEmpty &&
        match.innings[match.currentInnings]['closed'] != true;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Match options'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        if (match.status == 'live' && active)
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(
              match.currentInnings == 0 ? 'End innings' : 'Finish match',
            ),
            onTap: busy
                ? null
                : () async {
                    if (await confirmScoringAction(
                      context,
                      match.currentInnings == 0
                          ? 'End innings?'
                          : 'Finish match?',
                      'Close the innings at the current score?',
                    )) {
                      await controller.end(match.id, match.revision);
                    }
                  },
          ),
        ListTile(
          leading: const Icon(Icons.cancel_outlined),
          title: const Text('Abandon match'),
          onTap: busy
              ? null
              : () async {
                  if (await confirmScoringAction(
                    context,
                    'Abandon match?',
                    'Declare no result and award one point to each team?',
                  )) {
                    await controller.abandon(match.id, match.revision);
                  }
                },
        ),
      ],
    );
  }
}
