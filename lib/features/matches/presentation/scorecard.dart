import 'package:flutter/material.dart';
import '../domain/cricket_match.dart';

class Scorecard extends StatelessWidget {
  const Scorecard({super.key, required this.match, required this.balls});
  final CricketMatch match;
  final List<Map<String, dynamic>> balls;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (var innings = 0; innings < match.innings.length; innings++) ...[
        Text(
          match.teamName(match.innings[innings]['battingTeamId'] as String),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(match.scoreFor(match.innings[innings]['battingTeamId'] as String)),
        const SizedBox(height: 12),
        ..._batters(innings).entries.map((entry) {
          final deliveries = entry.value;
          final runs = deliveries.fold<int>(
            0,
            (sum, b) => sum + (b['runsOffBat'] as num).toInt(),
          );
          final faced = deliveries
              .where((b) => b['extraType'] != 'wide')
              .length;
          final out = balls.any(
            (b) =>
                b['innings'] == innings && b['dismissedPlayerId'] == entry.key,
          );
          final name = _batterName(innings, entry.key, deliveries);
          final fours = deliveries.where((b) => b['runsOffBat'] == 4).length;
          final sixes = deliveries.where((b) => b['runsOffBat'] == 6).length;
          return ListTile(
            title: Text('$name${out ? '' : ' *'}'),
            trailing: Text('$runs ($faced)'),
            subtitle: Text(
              '${out ? 'Out' : 'Not out'} · $fours fours · $sixes sixes · SR ${faced == 0 ? '0.00' : (runs * 100 / faced).toStringAsFixed(2)}',
            ),
          );
        }),
        const Divider(),
        Text('Bowling', style: Theme.of(context).textTheme.titleMedium),
        ..._bowlers(innings).entries.map((entry) {
          final deliveries = entry.value;
          final legal = deliveries
              .where((b) => !['wide', 'noball'].contains(b['extraType']))
              .length;
          final runs = deliveries.fold<int>(
            0,
            (s, b) =>
                s +
                (b['runsOffBat'] as num).toInt() +
                (['bye', 'legbye'].contains(b['extraType'])
                    ? 0
                    : (b['extraRuns'] as num).toInt()),
          );
          final wickets = deliveries
              .where(
                (b) =>
                    b['isWicket'] == true &&
                    ![
                      'run out',
                      'retired hurt',
                      'obstructing the field',
                    ].contains(b['wicketType']),
              )
              .length;
          return ListTile(
            title: Text(deliveries.first['bowlerName'] as String? ?? entry.key),
            trailing: Text('${legal ~/ 6}.${legal % 6}   $runs/$wickets'),
          );
        }),
        const Divider(height: 32),
      ],
    ],
  );
  Map<String, List<Map<String, dynamic>>> _batters(int innings) {
    final grouped = _group(innings, 'batterId');
    final summary = match.innings[innings];
    for (final id in [
      summary['strikerId'],
      summary['nonStrikerId'],
      ...List<String>.from(summary['dismissed'] as List? ?? []),
    ]) {
      if (id is String && id.isNotEmpty) grouped.putIfAbsent(id, () => []);
    }
    return grouped;
  }

  String _batterName(
    int innings,
    String id,
    List<Map<String, dynamic>> deliveries,
  ) {
    if (deliveries.isNotEmpty) {
      return deliveries.first['batterName'] as String? ?? id;
    }
    final summary = match.innings[innings];
    if (summary['strikerId'] == id) {
      return summary['strikerName'] as String? ?? id;
    }
    if (summary['nonStrikerId'] == id) {
      return summary['nonStrikerName'] as String? ?? id;
    }
    final dismissal = balls.where(
      (b) => b['innings'] == innings && b['dismissedPlayerId'] == id,
    );
    return dismissal.isEmpty
        ? id
        : dismissal.first['dismissedPlayerName'] as String? ?? id;
  }

  Map<String, List<Map<String, dynamic>>> _bowlers(int innings) =>
      _group(innings, 'bowlerId');
  Map<String, List<Map<String, dynamic>>> _group(int innings, String key) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final b in balls.where((b) => b['innings'] == innings)) {
      result.putIfAbsent(b[key] as String, () => []).add(b);
    }
    return result;
  }
}
