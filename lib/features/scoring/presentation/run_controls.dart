import 'package:flutter/material.dart';
import '../../../core/theme/app_text.dart';
import '../domain/scoring_engine.dart';

class RunControls extends StatelessWidget {
  const RunControls({
    super.key,
    required this.enabled,
    required this.onRuns,
    required this.onExtra,
    required this.onWicket,
  });
  final bool enabled;
  final ValueChanged<int> onRuns;
  final ValueChanged<ExtraType> onExtra;
  final VoidCallback onWicket;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('RUNS OFF BAT', style: AppText.label),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [0, 1, 2, 3, 4, 6]
            .map(
              (runs) => SizedBox(
                width: 76,
                height: 56,
                child: FilledButton(
                  onPressed: enabled ? () => onRuns(runs) : null,
                  child: Text('$runs', style: AppText.team),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in [
            (ExtraType.wide, 'Wide'),
            (ExtraType.noball, 'No ball'),
            (ExtraType.bye, 'Bye'),
            (ExtraType.legbye, 'Leg bye'),
          ])
            OutlinedButton(
              onPressed: enabled ? () => onExtra(e.$1) : null,
              child: Text(e.$2),
            ),
          FilledButton.tonal(
            onPressed: enabled ? onWicket : null,
            child: const Text('Wicket'),
          ),
        ],
      ),
      const SizedBox(height: 20),
    ],
  );
}
