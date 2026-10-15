import 'package:flutter/material.dart';
import '../../../core/theme/app_text.dart';

class RecentBalls extends StatelessWidget {
  const RecentBalls({super.key, required this.balls, required this.innings});
  final List<Map<String, dynamic>> balls;
  final int innings;
  String label(Map<String, dynamic> b) => b['isWicket'] == true
      ? 'W'
      : b['extraType'] != 'none'
      ? '${b['runsOffBat'] + b['extraRuns']} ${b['extraType']}'
      : '${b['runsOffBat']}';
  @override
  Widget build(BuildContext context) {
    final current = balls.where((b) => b['innings'] == innings).toList();
    final over = current.isEmpty ? 0 : current.last['over'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CURRENT OVER · ${over + 1}', style: AppText.label),
        const SizedBox(height: 8),
        if (current.isEmpty)
          const Text('Waiting for the first ball.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: current
                .where((b) => b['over'] == over)
                .map((b) => Chip(label: Text(label(b))))
                .toList(),
          ),
        const SizedBox(height: 16),
        Text('RECENT DELIVERIES', style: AppText.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: current.reversed
              .take(18)
              .map((b) => Chip(label: Text(label(b))))
              .toList(),
        ),
      ],
    );
  }
}
